//
//  NetworkRequest.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

///The basic request object supplying the minimal information for a network request.  ContentType header value is part of this request, other headers are set later by a delegate call to HellfireSessionDelegate implemented by the application.
public class NetworkRequest {
    
    /// Default initializer for the NetworkRequest object.  Minimum parameters for a basic request is `url` and `method`.
    /// - Parameters:
    ///   - url: Sets the url for the request.
    ///   - method: Sets the HTTP method for the request.
    ///   - cachePolicyType: Sets the CachePolicyType to be used on the response.  Default value is .doNotCache
    ///   - timeoutInterval: Sets the connection timeout for the request in seconds.  Default value is 30 seconds.
    ///   - body: Sets the Request http body.   Default value is nil.
    ///   - contentType: Sets the content type of the request body.   Default value is `application/json`
    public init(url: URL,
                method: HTTPMethod,
                cachePolicyType: CachePolicyType = .doNotCache,
                timeoutInterval: TimeInterval = TimeInterval(30),
                body: Data? = nil,
                contentType: String = "application/json") {
        self.url = url
        self.method = method
        self.cachePolicyType = cachePolicyType
        self.timeoutInterval = timeoutInterval
        self.body = body
        self.contentType = contentType
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
    
    /// Gets the content type of the request body.   Default value is `application/json`
    public let contentType: String
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
                              contentType: request.contentType)
    }
}
