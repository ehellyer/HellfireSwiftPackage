//
//  ServiceError.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

public class ServiceError: Error {
    
    public init(request: URLRequest, error: Error?, statusCode: StatusCode, responseBody: Data?, userCancelledRequest: Bool) {
        self.request = request
        self.error = error
        self.statusCode = statusCode
        self.responseBody = responseBody
        self.userCancelledRequest = userCancelledRequest
    }
    
    ///The url for the service error.
    public let request: URLRequest
    
    ///The error object (if there is one)
    public let error: Error?
    
    ///The status code can be a recognized HTTPStatusCode or one of this frameworks own network status code, defined in HTTPCode.
    public let statusCode: StatusCode
    
    ///The response body for the erroring request.
    public let responseBody: Data?
    
    ///Returns true if the user cancelled the request.
    public let userCancelledRequest: Bool
}
