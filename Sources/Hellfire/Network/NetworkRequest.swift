//
//  NetworkRequest.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

///The basic request object supplying the minimal information for a network request.  Headers are set later by a delegate call to ServiceInterfaceSessionDelegate implemented by the application.
public struct NetworkRequest {
    
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
    
    /// Gets the CachePolicyType to be used on the response.
    public let cachePolicyType: CachePolicyType
    
    /// Gets the connection timeout for the request in seconds.  Default is 30 seconds if parameter is not passed in on the initializer.
    public let timeoutInterval: TimeInterval
    
    /// Gets the Request http body
    public let body: Data?
    
    /// Gets the content type of the request body.
    public let contentType: String
}
