//
//  ServiceError.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

public class ServiceError: Error {
    
    
    /// Default initializer for the `ServiceError` object.
    /// - Parameters:
    ///   - request: Sets the url for the service error.
    ///   - error: Sets the error object if there is one available.
    ///   - statusCode: Sets `StatusCode` of the network request.
    ///   - responseBody: Sets response body for the erroring request.
    ///   - userCancelledRequest: Sets the flag to indicate if the network request was cancelled by the user.  Returns true if the user cancelled the request.
    internal init(request: URLRequest?, error: Error?, statusCode: StatusCode, responseBody: Data?, userCancelledRequest: Bool) {
        self.request = request
        self.error = error
        self.statusCode = statusCode
        self.responseBody = responseBody
        self.userCancelledRequest = userCancelledRequest
    }
    
    ///Gets the url request that initiated the service error.
    public let request: URLRequest?
    
    ///Gets the error object if there is one available.
    public let error: Error?
    
    ///Gets `StatusCode` off the network request.
    public let statusCode: StatusCode
    
    ///Gets response body for the erroring request.  (Sometimes this might contain a HTML error page from a web service.)
    public let responseBody: Data?
    
    ///Gets the flag to indicate if the network request was cancelled by the user.  Returns true if the user cancelled the request.
    public let userCancelledRequest: Bool
}
