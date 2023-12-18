//
//  DataResponse.swift
//  Hellfire
//
//  Created by Ed Hellyer on 10/3/21.
//

import Foundation

/// Represents the result of a data task downloaded into memory.
public class DataResponse {
    
    /// Creates an instance of `DataResponse`
    /// - Parameters:
    ///   - headers: Sets the response headers from the server.
    ///   - statusCode: Sets the HTTP result status code.
    ///   - body: Sets the response body from the server.
    public init(headers: [HTTPHeader],
                statusCode: StatusCode,
                body: Data?) {
        self.headers = headers
        self.statusCode = statusCode
        self.body = body
    }
    
    /// Gets the response headers from the server.
    public let headers: [HTTPHeader]
    
    /// Gets the HTTP result status code.
    public let statusCode: StatusCode
    
    /// Gets the response body from the server.
    public let body: Data?
}
