//
//  ServiceInterface.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

public typealias RequestTaskIdentifier = UUID
public typealias ReachabilityHandler = (ReachabilityStatus) -> Void
public typealias ServiceErrorHandler = (ServiceError) -> Void
public typealias TaskResult = (RequestResult) -> Void

/// Only one instance per app should be created.  However, rather than trying to enforce this via a singleton, it's up to the app developer when to create multiple instances.
/// Be aware that DiskCache storage, data task URLSession and background URLSession are shared between multiple ServiceInterface instances.
/// Concerning DiskCache, although a unique hash insertion key will be created, storage will be shared between the instances.
public class ServiceInterface: NSObject {
    
    //MARK: - ServiceInterface overrides API
    
    deinit {
        #if DEBUG
        print("\(String(describing: type(of: self))) has deallocated. - \(#function)")
        #endif
    }
    
    public required override init() {
        self.backgroundSessionIdentifier = "Hellfire.BackgroundUrlSession"
        super.init()
    }
    
    public required init(backgroundSessionIdentifier: String) {
        self.backgroundSessionIdentifier = backgroundSessionIdentifier
        super.init()
    }
    
    //MARK: - Private Property API
    
    private var reachabilityManager: NetworkReachabilityManager?
    private var privateReachabilityHost: String?
    private lazy var diskCache = DiskCache()
    private var backgroundSessionIdentifier: String
    
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
        //Allow the system automatically determine concurrent tasks based on current system resources. (via OperationQueue.defaultMaxConcurrentOperationCount)
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
    
    //MARK: - Private Func API
    
    private func statusCodeForResponse(_ response: URLResponse?, error: Error?) -> StatusCode {
        /*
         In Hellfire, we always want to have a value in statusCode for easier error detection.
         This means that for non URL response errors, we set the statusCode to the negative values of 'URL Loading System Error Codes'.
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
    
    private func createServiceError(data: Data?, statusCode: StatusCode, error: Error?, requestURL: URL?) -> ServiceError {
        let requestCancelled = HTTPCode.wasRequestCancelled(statusCode: statusCode)
        let serviceError = ServiceError(requestURL: requestURL, error: error, statusCode: statusCode, responseBody: data, userCancelledRequest: requestCancelled)
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
    
    private func taskResponseHandler(request: NetworkRequest, data: Data?, response: URLResponse?, error: Error?, completion: @escaping TaskResult) {
        let statusCode = self.statusCodeForResponse(response, error: error)
        
        if let responseData = data, HTTPCode.isOk(statusCode: statusCode) {
            self.diskCache.cache(data: responseData, forRequest: request)
        }
        
        //Send back response headers to delegate.  (Headers will be additionally included with the NetworkResponse.)
        let responseHeaders: [HTTPHeader] = self.responseHeaders(response)
        self.sessionDelegate?.responseHeaders(headers: responseHeaders, forRequest: request)

        //Call completion block
        DispatchQueue.main.async {
            if HTTPCode.isOk(statusCode: statusCode) {
                let dataResponse = NetworkResponse(headers: responseHeaders, body: data, statusCode: statusCode)
                completion(.success(dataResponse))
            } else {
                let serviceError = self.createServiceError(data: data, statusCode: statusCode, error: error, requestURL: request.url)
                completion(.failure(serviceError))
            }
        }
    }
    
    //MARK: - Public Property API
    
    ///Gets or sets the handler for the reachability status change events.
    public var reachabilityHandler: ReachabilityHandler?
    
    ///Gets or sets the handler for the service error handler
    public var serviceErrorHandler: ServiceErrorHandler?
    
    ///  Gets or sets the reachability host (e.g. "www.apple.com").
    ///
    ///  Setting the host to some value starts the listener.
    ///  Setting the host to nil will stop the listener.
    ///  IMPORTANT NOTE: You must set self.reachabilityHost after setting self.reachabilityHandler, otherwise reachability manager will not start listening for network change events.
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
    
    //MARK: - Public Func API
    
    /// Executes the `MultipartRequest` request asynchronously as a [URLSessionUploadTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionUploadTask).
    ///
    /// Upload tasks are run on a background URLSession.  The default URLSession identifier for this background session is Hellfire.BackgroundUrlSession.  A custom background session identifier can be passed in on init.
    /// - Parameter request: The multipart form data request that is to be executed.
    /// - Returns: Unique task identifier for the [URLSessionUploadTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionUploadTask). This identifier can be used to cancel the network request.
    public func executeUpload(_ request: MultipartRequest) throws -> RequestTaskIdentifier? {
        do {
            let requestComponents = try request.build()
            var urlRequest = requestComponents.urlRequest
            
            //Ask session delegate for additional headers or updates to headers for this request.
            let appHeaders: [HTTPHeader] = self.sessionDelegate?.headerCollection(forRequest: request) ?? []
            appHeaders.forEach({ (header) in
                urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
            })
            
            let task = self.backgroundSession.uploadTask(with: urlRequest, fromFile: requestComponents.requestBody)
            let taskIdentifier = UUID()
            task.requestItem = RequestItem(identifier: taskIdentifier, networkRequest: request)
            task.taskDescription = taskIdentifier.uuidString
            task.resume()
            return taskIdentifier
        } catch (let error) {
            let serviceError = self.createServiceError(data: error.localizedDescription.data(using: .utf8),
                                                       statusCode: -666,
                                                       error: error,
                                                       requestURL: request.url)
            
            throw HellfireError.ServiceRequestError.unableToCreateTask(result: .failure(serviceError))
        }
    }
    
    ///Executes the network request asynchronously as a [URLSessionDataTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionDataTask), intended to be a relatively short request.
    ///
    ///Cached and network responses are called back by dispatching to the main thread and calling the completion block.  For cached responses, the network response object will have a response header added with the name `CachedResponse` with a value of `true`.
    ///A `RequestTaskIdentifier` is returned for a NetworkRequest that is dispatched to URL session.  This identifier can be used to cancel the network request.
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
                                           data: data,
                                           response: response,
                                           error: error,
                                           completion: completion)
        }
        
        let taskIdentifier = UUID()
        task.requestItem = RequestItem(identifier: taskIdentifier, networkRequest: request)
        task.taskDescription = taskIdentifier.uuidString
        task.resume()
        return taskIdentifier
    }
    
    /// Gets all the tasks currently running on the background session.
    /// - Parameter completion: Returns a tuple of three arrays via an asynchronous completion block. ([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask])
    public func getBackgroundTasks(completion: @escaping ([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask]) -> Void) {
        self.backgroundSession.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) in
            completion(dataTasks, uploadTasks, downloadTasks)
        }
    }
  
    ///Cancels the network request for the specified request task identifier.
    ///
    /// - Parameters:
    ///     - taskIdentifier: Unique task identifier for the URLSessionTask.
    public func cancelUploadRequest(taskIdentifier: RequestTaskIdentifier?) {
        guard let taskId = taskIdentifier else { return }
        self.backgroundSession.getAllTasks { (backgroundSessionTasks) in
            if let task = backgroundSessionTasks.first(where: { $0.requestItem?.identifier == taskId }) {
                task.cancel()
            }
        }
    }
    
    ///Cancels the network request for the specified request task identifier.
    ///
    /// - Parameters:
    ///     - taskIdentifier: Unique task identifier for the URLSessionTask.
    public func cancelDataRequest(taskIdentifier: RequestTaskIdentifier?) {
        guard let taskId = taskIdentifier else { return }

        self.dataTaskSession.getAllTasks { (dataSessionTasks) in
            if let task = dataSessionTasks.first(where: { $0.requestItem?.identifier == taskId }) {
                task.cancel()
            }
        }
    }
    
    ///Cancels all current network requests on all sessions.
    public func cancelAllCurrentRequests() {
        self.backgroundSession.getAllTasks { (backgroundSessionTasks) in
            backgroundSessionTasks.forEach { $0.cancel() }
        }
        self.dataTaskSession.getAllTasks { (dataSessionTasks) in
            dataSessionTasks.forEach { $0.cancel() }
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
        
        self.sessionDelegate?.session(session,
                                      dataTask: dataTask,
                                      didReceive: data)
    }
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        let statusCode = self.statusCodeForResponse(task.response, error: error)
        let responseHeaders: [HTTPHeader] = self.responseHeaders(task.response)
        var result: RequestResult
        
        if HTTPCode.isOk(statusCode: statusCode) {
            let dataResponse = NetworkResponse(headers: responseHeaders,
                                               body: nil,
                                               statusCode: statusCode)
            result = .success(dataResponse)
        } else {
            let serviceError = self.createServiceError(data: nil,
                                                       statusCode: statusCode,
                                                       error: error,
                                                       requestURL: task.originalRequest?.url)
            result = .failure(serviceError)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.sessionDelegate?.backgroundTask(task, didCompleteWithResult: result)
        }
        
        (task.requestItem?.networkRequest as? MultipartRequest)?.cleanUpHttpBody()
    }
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        DispatchQueue.main.async { [weak self] in
            self?.sessionDelegate?.backgroundTask(task,
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
        self.sessionDelegate?.backgroundSessionDidFinishEvents(session: session)
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
