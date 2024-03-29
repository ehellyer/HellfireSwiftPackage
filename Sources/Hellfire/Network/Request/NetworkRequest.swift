//
//  NetworkRequest.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

///The basic request object supplying the minimal information for a network request.
public class NetworkRequest {
    
    
    /// Default initializer for the NetworkRequest object.  Minimum parameters for a basic request is `url` and `method`.
    /// - Parameters:
    ///   - url: Sets the url for the request.
    ///   - method: Sets the HTTP method for the request.
    ///   - cachePolicyType: Sets the CachePolicyType to be used on the response.  Default value is .doNotCache
    ///   - timeoutInterval: Sets the connection timeout for the request in seconds.  Default value is 30 seconds.
    ///   - body: Sets the Request http body.   Default value is nil.
    ///   - headers: Sets the request headers.  These values are set after the delegate sets request header values and so header values in the `NetworkRequest` take precedence.
    ///   - dispatchResponseToMain: Defaults to true.  When true, the response will be automatically dispatched back to the main thread.  Setting this to false, the response is dispatched on the initiating thread.
    public init(url: URL,
                method: HTTPMethod,
                cachePolicyType: CachePolicyType = .doNotCache,
                timeoutInterval: TimeInterval = TimeInterval(30),
                body: Data? = nil,
                headers: [HTTPHeader] = [],
                dispatchResponseToMain: Bool = true) {
        self.url = url
        self.method = method
        self.cachePolicyType = cachePolicyType
        self.timeoutInterval = timeoutInterval
        self.body = body
        self.headers = headers
        self.dispatchToMain = dispatchResponseToMain
    }
    
    /// Gets the url for the request.
    public let url: URL
    
    /// Gets the HTTP method for the request.
    public let method: HTTPMethod
    
    /// Gets the CachePolicyType to be used on the response.  Default value is .doNotCache
    public let cachePolicyType: CachePolicyType
    
    /// Gets the connection timeout for the request in seconds.  Default value is 30 seconds.
    public let timeoutInterval: TimeInterval
    
    /// Gets the Request http body.   Default value is nil.
    public let body: Data?
    
    /// Gets the headers set for this request.  These values are used after the delegate configures global request headers and so takes precedence.
    public let headers: [HTTPHeader]

    internal let dispatchToMain: Bool
}

extension NetworkRequest {
    
    /// Creates a new instance of the `NetworkRequest` object when it is used for a background upload task.  The timeout is set to 10 minutes and the caching option is set to do not cache.
    /// - Parameter request: Original `NetworkRequest`
    /// - Returns: New `NetworkRequest` with timeoutInterval and cachePolicyType overridden.
    internal static func uploadRequest(fromRequest request: NetworkRequest) -> NetworkRequest {
        return NetworkRequest(url: request.url,
                              method: request.method,
                              cachePolicyType: .doNotCache,
                              timeoutInterval: TimeInterval(600),
                              body: request.body,
                              headers: request.headers)
    }
}
