//
//  ServiceInterface.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

public typealias ReachabilityHandler = (ReachabilityStatus) -> Void
public typealias ServiceErrorHandler = (ServiceError) -> Void
public typealias TaskResult = (RequestResult) -> Void

/// Only one instance per app should be created.  However, rather than trying to enforce this via a singleton, its up to the app developer when to create multiple instances.
/// Be aware that DiskCache storage is shared between multiple ServiceInterface instances.  Although a unique hash insertion key will be created, storage size will be shared.
public class ServiceInterface: NSObject {
    
    //MARK: - Private API
    
    private var reachabilityManager: NetworkReachabilityManager?
    private var privateReachabilityHost: String?
    private lazy var requestCollection = RequestCollection()
    private lazy var diskCache = DiskCache()
    private lazy var backgroundSessionIdentifier: String = "Hellfire.BackgroundUrlSession"
    private lazy var dataTaskSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = self.defaultRequestHeaders
        configuration.requestCachePolicy = .reloadIgnoringCacheData
        configuration.urlCache = nil
        let urlSession = URLSession(configuration: configuration)
        return urlSession
    }()
    private lazy var backgroundSession: URLSession = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        operationQueue.qualityOfService = .userInteractive

        let configuration = URLSessionConfiguration.background(withIdentifier: self.backgroundSessionIdentifier)
        configuration.httpAdditionalHeaders = self.defaultRequestHeaders
        configuration.requestCachePolicy = .reloadIgnoringCacheData
        configuration.urlCache = nil
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        configuration.shouldUseExtendedBackgroundIdleMode = true
        //configuration.timeoutIntervalForRequest = {For now using default - 60 seconds}
        //configuration.timeoutIntervalForResource = {For now using default - 7 days}
        
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)

        return urlSession
    }()
    private lazy var defaultRequestHeaders: [AnyHashable: Any] = {
        var headers = [AnyHashable: Any]()
        [HTTPHeader.defaultUserAgent].forEach { headers[$0.name] = $0.value }
        return headers
    }()
    
    private func statusCodeForResponse(_ response: URLResponse?, error: Error?) -> StatusCode {
        /*
         In Hellfire, we always want to have a value in statusCode for easier error detection.
         This means that for non URL reponse errors, we set the statusCode to the negative values of 'URL Loading System Error Codes'.
         */
        let statusCode: StatusCode = (response as? HTTPURLResponse)?.statusCode ??
            (error as NSError?)?.code ??
            //We should never get to this last option.  But if there was no statusCode from the response and there was no error instance, we are defaulting to HTTP.ok
            HTTPCode.ok.rawValue
        return statusCode
    }
    
    private func responseHeaders(_ response: URLResponse?) -> [HTTPHeader] {
        guard let headers = (response as? HTTPURLResponse)?.allHeaderFields else { return [] }
        let httpHeaders = headers.compactMap { HTTPHeader(name: "\($0.key)", value: "\($0.value)") }
        return httpHeaders
    }
    
    private func createServiceError(data: Data?, statusCode: StatusCode, error: Error?, request: URLRequest) -> ServiceError {
        let requestCancelled = HTTPCode.wasRequestCancelled(statusCode: statusCode)
        let serviceError = ServiceError(request: request, error: error, statusCode: statusCode, responseBody: data, userCancelledRequest: requestCancelled)
        self.serviceErrorHandler?(serviceError)
        return serviceError
    }
    
    private func urlRequest(fromNetworkRequest request: NetworkRequest) -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.name
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = request.timeoutInterval
        
        //Set ContentType per request.
        let contentTypeHeader = HTTPHeader.contentType(request.contentType)
        urlRequest.setValue(contentTypeHeader.value, forHTTPHeaderField: contentTypeHeader.name)
        
        //Ask session delegate for additional headers or updates to headers for this request.
        let appHeaders: [HTTPHeader] = self.sessionDelegate?.headerCollection(forRequest: request) ?? []
        appHeaders.forEach({ (header) in
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
        })
        
        return urlRequest
    }
    
    private func hasCachedResponse(forRequest request: NetworkRequest, completion: @escaping TaskResult) -> Bool {
        if request.cachePolicyType != CachePolicyType.doNotCache {
            if let response = self.diskCache.getCacheDataFor(request: request) {
                DispatchQueue.main.async {
                    let dataResponse = NetworkResponse(headers: [HTTPHeader(name: "CachedResponse", value: "true")],
                                                       body: response,
                                                       statusCode: HTTPCode.ok.rawValue)
                    completion(.success(dataResponse))
                }
                return true
            }
        }
        return false
    }
    
    private func setupReachabilityManager(host: String) {
        self.reachabilityManager?.stopListening()
        self.reachabilityManager?.listener = nil
        self.reachabilityManager = NetworkReachabilityManager(host: host)
        self.reachabilityManager?.listener = { [weak self] status in
            guard let strongSelf = self else { return }
            switch status {
            case .notReachable:
                strongSelf.reachabilityHandler?(.notReachable)
            case .unknown :
                strongSelf.reachabilityHandler?(.unknown)
            case .reachable(.ethernetOrWiFi):
                strongSelf.reachabilityHandler?(.reachable(.wiFiOrEthernet))
            case .reachable(.wwan):
                strongSelf.reachabilityHandler?(.reachable(.cellular))
            }
        }
        self.reachabilityManager?.startListening()
    }
    
    private func taskResponseHandler(request: NetworkRequest, urlRequest: URLRequest, completion: @escaping TaskResult, data: Data?, response: URLResponse?, error: Error?) {
        let statusCode = self.statusCodeForResponse(response, error: error)
        
        if let responseData = data, HTTPCode.isOk(statusCode: statusCode) {
            self.diskCache.cache(data: responseData, forRequest: request)
        }
        
        //Send back response headers to delegate.  (Headers will be additionally included with the NetworkResponse.)
        let responseHeaders: [HTTPHeader] = self.responseHeaders(response)
        self.sessionDelegate?.responseHeaders(headers: responseHeaders, forRequest: request)
        
        //Remove task from request collection
        self.requestCollection.removeTaskRequest(networkRequest: request)
        
        //Call completion block
        DispatchQueue.main.async {
            if HTTPCode.isOk(statusCode: statusCode) {
                let dataResponse = NetworkResponse(headers: responseHeaders, body: data, statusCode: statusCode)
                completion(.success(dataResponse))
            } else {
                let serviceError = self.createServiceError(data: data, statusCode: statusCode, error: error, request: urlRequest)
                completion(.failure(serviceError))
            }
        }
    }
    
    //MARK: - Public API
    
    deinit {
        #if DEBUG
        print("\(String(describing: type(of: self))) has deallocated. - \(#function)")
        #endif
    }

    
    //TODO: Finish the injection of this configuration.
//    public init(backgroundSessionConfiguration: URLSessionConfiguration) {
//        self.backgroundSession.configuration = backgroundSessionConfiguration
//    }
    
    ///Gets or sets the handler for the reachability status change events.
    public var reachabilityHandler: ReachabilityHandler?
    
    ///Gets or sets the handler for the service error handler
    public var serviceErrorHandler: ServiceErrorHandler?
    
    /**
     Gets or sets the reachability host (e.g. "www.apple.com").
     Setting the host to some value starts the listener.
     Setting the host to nil will stop the listener.
     IMPORTANT NOTE: You must set self.reachabilityHost after setting self.reachabilityHandler, otherwise reachability manager will not start listening for network change events.
     */
    public var reachabilityHost: String? {
        get {
            return self.privateReachabilityHost
        }
        set {
            self.privateReachabilityHost = newValue
            if let host = newValue, host.isEmpty == false {
                self.setupReachabilityManager(host: host)
            }
        }
    }
    
    public weak var sessionDelegate: HellfireSessionDelegate?
   
    public func executeUpload(_ request: MultipartRequest) -> RequestTaskIdentifier? {
        do {
            let result = try request.build()
            var urlRequest = result.request
            
            //Ask session delegate for additional headers or updates to headers for this request.
            let appHeaders: [HTTPHeader] = self.sessionDelegate?.headerCollection(forRequest: request) ?? []
            appHeaders.forEach({ (header) in
                urlRequest.setValue(header.value,
                                    forHTTPHeaderField: header.name)
            })
            
            let task = self.backgroundSession.uploadTask(with: urlRequest,
                                                         fromFile: result.requestBodyURL)
            let taskIdentifier = self.requestCollection.add(networkRequest: request,
                                                            task: task,
                                                            for: urlRequest,
                                                            requestBodyURL: result.requestBodyURL)
            task.resume()
            return taskIdentifier
        } catch (let error) {
            let serviceError = ServiceError(request: nil,
                                            error: error,
                                            statusCode: -666,
                                            responseBody: nil,
                                            userCancelledRequest: false)
            self.sessionDelegate?.backgroundTask(nil,
                                                 requestTaskIdentifier: nil,
                                                 didCompleteWithResult: .failure(serviceError))
        }
        return nil
    }
    
    ///Executes the network request asynchronously as a [URLSessionDataTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionDataTask), intended to be a relatively short request.
    ///Cached and network responses are called back by dispatching to the main thread and calling the completion block.  For cached responses, the network response object will have a response header added with the name `CachedResponse` with a value of `true`.
    ///A `RequestTaskIdentifier` is returned for a NetworkRequest that is dispatched to URL session.  This identifier can be used to cancel the network request.
    ///
    /// - Parameters:
    ///     - request: The network request to be executed
    ///     - completion: The completion function to be called with the response.
    /// - Returns: `RequestTaskIdentifier`  Unique task identifier for the [URLSessionDataTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionDataTask).  This identifier can be used to cancel the network request.
    public func execute(_ request: NetworkRequest, completion: @escaping TaskResult) -> RequestTaskIdentifier? {
        if hasCachedResponse(forRequest: request, completion: completion) { return nil }
        
        let urlRequest = self.urlRequest(fromNetworkRequest: request)
        let task = self.dataTaskSession.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let strongSelf = self else { return }
            strongSelf.taskResponseHandler(request: request,
                                           urlRequest: urlRequest,
                                           completion: completion,
                                           data: data,
                                           response: response,
                                           error: error)
        }
        
        let taskIdentifier = self.requestCollection.add(networkRequest: request,
                                                        task: task,
                                                        for: urlRequest,
                                                        requestBodyURL: nil)
        task.resume()
        
        return taskIdentifier
    }
    
    ///Cancels the network request for the specified request task identifier.
    ///
    /// - Parameters:
    ///     - taskIdentifier: Unique task identifier for the URLSessionTask.
    public func cancelRequest(taskIdentifier: RequestTaskIdentifier?) {
        guard let taskId = taskIdentifier else { return }
        let item = self.requestCollection.taskRequestItem(forTaskIdentifier: taskId)
        item?.sessionTask.cancel()
        self.requestCollection.removeTaskRequest(forTaskIdentifier: taskId)
    }
    
    ///Cancels all current network requests.
    public func cancelAllCurrentRequests() {
        let taskIdentifiers = self.requestCollection.allTaskIdentifiers()
        taskIdentifiers.forEach { (taskIdentifier) in
            self.cancelRequest(taskIdentifier: taskIdentifier)
        }
    }
    
    ///Clears all cached data for any instance of ServiceInterface.
    public func clearCache() {
        self.diskCache.clearCache()
    }
    
    /// Clears cached data for the specified cache policy type only
    /// - Parameter policyType: The cache bucket that is to be cleared.
    public func clearCache(policyType: CachePolicyType) {
        self.diskCache.clearCache(policyType: policyType)
    }
}

//MARK: - URLSessionDataDelegate protocol
extension ServiceInterface: URLSessionDataDelegate {

    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive data: Data) {
        guard let taskRequestItem = self.requestCollection.taskRequestItem(forSessionTask: dataTask) else { return }
        
        self.sessionDelegate?.session(session,
                                      dataTask: dataTask,
                                      requestTaskIdentifier: taskRequestItem.identifier,
                                      didReceive: data)
    }
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        guard let taskRequestItem = self.requestCollection.taskRequestItem(forSessionTask: task) else { return }

        let statusCode = self.statusCodeForResponse(task.response,
                                                    error: error)
        let responseHeaders: [HTTPHeader] = self.responseHeaders(task.response)
        
        if HTTPCode.isOk(statusCode: statusCode) {
            let dataResponse = NetworkResponse(headers: responseHeaders,
                                               body: nil,
                                               statusCode: statusCode)
            DispatchQueue.main.async { [weak self] in
                self?.sessionDelegate?.backgroundTask(task,
                                                      requestTaskIdentifier: taskRequestItem.identifier,
                                                      didCompleteWithResult: .success(dataResponse))
            }
        } else {
            let serviceError = self.createServiceError(data: nil,
                                                       statusCode: statusCode,
                                                       error: error,
                                                       request: taskRequestItem.urlRequest)
            DispatchQueue.main.async { [weak self] in
                self?.sessionDelegate?.backgroundTask(task,
                                                      requestTaskIdentifier: taskRequestItem.identifier,
                                                      didCompleteWithResult: .failure(serviceError))
            }
        }
        
        (taskRequestItem.networkRequest as? MultipartRequest)?.cleanUpHttpBody()
        self.requestCollection.removeTaskRequest(forTaskIdentifier: taskRequestItem.identifier)
    }
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        guard let taskRequestItem = self.requestCollection.taskRequestItem(forSessionTask: task) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.sessionDelegate?.backgroundTask(task,
                                                  forRequestIdentifier: taskRequestItem.identifier,
                                                  didSendBytes: Int(bytesSent),
                                                  totalBytesSent: Int(totalBytesSent),
                                                  totalBytesExpectedToSend: Int(totalBytesExpectedToSend))
        }
    }
}


//MARK: - URLSessionTaskDelegate protocol
extension ServiceInterface: URLSessionTaskDelegate {

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        self.sessionDelegate?.session(session,
                                      task: task,
                                      didReceive: challenge,
                                      completionHandler: completionHandler)
    }
}


//MARK: - URLSessionDelegate protocol
extension ServiceInterface: URLSessionDelegate {
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { [weak self] in
            self?.sessionDelegate?.backgroundSessionDidFinishEvents(session: session)
        }
    }

    public func urlSession(_ session: URLSession,
                           didBecomeInvalidWithError error: Error?) {
        self.sessionDelegate?.session(session,
                                      didBecomeInvalidWithError: error)
    }

    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        self.sessionDelegate?.session(session,
                                      didReceive: challenge,
                                      completionHandler: completionHandler)
    }
}
