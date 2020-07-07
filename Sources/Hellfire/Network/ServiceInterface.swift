//
//  ServiceInterface.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

public typealias RequestTaskIdentifier = Int
public typealias ReachabilityHandler = (ReachabilityStatus) -> Void
public typealias ServiceErrorHandler = (ServiceError) -> Void
public typealias TaskResult = (RequestResult) -> Void

///Only one instance per app should be created.  However, rather than trying to enforce this via a singleton, its up to the app developer when to create multiple instances.
///Be aware that DiskCache is shared between multiple ServiceInterface instances.  Although a unique hash insertion key will be created, storage size will be shared.
public class ServiceInterface {
    
    //MARK: - Private API
    
    private var reachabilityManager: NetworkReachabilityManager?
    private var privateReachabilityHost: String?
    private lazy var requestCollection = RequestCollection()
    private lazy var diskCache = DiskCache()
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: configuration)
        return urlSession
    }()
    
    private func statusCodeForResponse(_ response: HTTPURLResponse?, error: Error?) -> StatusCode {
        //We decided we always want to have a value in statusCode.  This means that for non-service errors, we set the statusCode to negative values that are not recognized in the industry.
        let defaultStatusCode = (error == nil) ? HTTPCode.ok.rawValue : HTTPCode.generalError.rawValue
        var statusCode: Int = response?.statusCode ?? defaultStatusCode

        if let _error = error as NSError?, HTTPCode.isOk(statusCode: statusCode) == false {
            if (_error.code == HTTPCode.userCancelledRequest.rawValue) {
                statusCode = HTTPCode.userCancelledRequest.rawValue
            } else if (_error.code == HTTPCode.connectionMakeTimeout.rawValue) {
                statusCode = HTTPCode.connectionMakeTimeout.rawValue
            } else if (_error.code == HTTPCode.unableToCreateSSLSession.rawValue) {
                statusCode = HTTPCode.unableToCreateSSLSession.rawValue
            } else if (_error.code == HTTPCode.hostNameNotFound.rawValue) {
                statusCode = HTTPCode.hostNameNotFound.rawValue
            }
        }

        return statusCode
    }

    private func responseHeaders(_ response: HTTPURLResponse?) -> [HTTPHeader] {
        guard let headers = response?.allHeaderFields else { return [] }
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
        
        //Ask session delegate for any headers for this request.
        if let headers = self.sessionDelegate?.headerCollection(forRequest: request) {
            headers.forEach({ (header) in
                urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
            })
        }
        
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

    //MARK: - Public API
    
    deinit {
        #if DEBUG
        print("\(String(describing: type(of: self))) has deallocated. - \(#function)")
        #endif
    }

    public init() { }
    
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
    
    public weak var sessionDelegate: ServiceInterfaceSessionDelegate?

    ///Executes the network request asynchronously.
    ///Calls back with cached response on same thread, in current call stack.
    ///Calls back with network response by dispatching to the main thread.
    ///Cancels the network request for the specified request task identifier.
    ///
    /// - Parameters:
    ///     - request: The network request to be executed
    ///     - completion: The completion function to be called with the response.
    public func execute(_ request: NetworkRequest, completion: @escaping TaskResult) -> RequestTaskIdentifier? {

        if hasCachedResponse(forRequest: request, completion: completion) { return nil }
        
        let urlRequest = self.urlRequest(fromNetworkRequest: request)
        let task = self.session.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let strongSelf = self else { return }
            
            let httpURLResponse = response as? HTTPURLResponse
            let statusCode = strongSelf.statusCodeForResponse(httpURLResponse, error: error)
            
            //If call was successful and we have data, store response in disk cache.
            if let responseData = data, HTTPCode.isOk(statusCode: statusCode), request.cachePolicyType != .doNotCache {
                strongSelf.diskCache.cache(data: responseData, forRequest: request)
            }
            
            //Send back response headers to delegate.  (Headers will be additionally included with the NetworkResponse.)
            let responseHeaders: [HTTPHeader] = strongSelf.responseHeaders(httpURLResponse)
            strongSelf.sessionDelegate?.responseHeaders(headers: responseHeaders, forRequest: request)
            
            //Remove task from request collection
            strongSelf.requestCollection.removeTask(forRequest: urlRequest)
            
            //Call completion block
            DispatchQueue.main.async {
                if HTTPCode.isOk(statusCode: statusCode) {
                    let dataResponse = NetworkResponse(headers: responseHeaders, body: data, statusCode: statusCode)
                    completion(.success(dataResponse))
                } else {
                    let serviceError = strongSelf.createServiceError(data: data, statusCode: statusCode, error: error, request: urlRequest)
                    completion(.failure(serviceError))
                }
            }
        }
        
        self.requestCollection.add(request: urlRequest, task: task)
        task.resume()
        
        return task.taskIdentifier
    }
    
    ///Cancels the network request for the specified request task identifier.
    ///
    /// - Parameters:
    ///     - taskIdentifier: Identifer for the network request.
    public func cancelRequest(taskIdentifier: RequestTaskIdentifier?) {
        guard let taskId = taskIdentifier else { return }
        self.requestCollection.removeRequest(forTaskIdentifier: taskId)
    }
    
    ///Cancels all current network requests.
    public func cancelAllCurrentRequests() {
        let tasks = self.requestCollection.allTasks()
        tasks.forEach { (task) in
            self.cancelRequest(taskIdentifier: task)
        }
    }
    
    ///Clears all cached data for any instance of ServiceInterface.
    public func clearCache() {
        self.diskCache.clearCache()
    }
    
    ///Clears cached data for the specified cache policy type only
    ///
    /// - Parameters:
    ///     - policyType: The cache bucket that is to be cleared.
    public func clearCache(policyType: CachePolicyType) {
        self.diskCache.clearCache(policyType: policyType)
    }
}
