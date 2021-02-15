//
//  NetworkResponse.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/21/20.
//

import Foundation

///Describes the successful response of an HTTP \ HTTPS call to a server
public class NetworkResponse {
    
    /// Creates an instance of `NetworkResponse`
    /// - Parameters:
    ///   - headers: Sets the response headers from the server.
    ///   - body: Sets the response body from the server.
    ///   - statusCode: Sets the HTTP result status code.
    public init(headers: [HTTPHeader], body: Data?, statusCode: StatusCode) {
        self.headers = headers
        self.body = body
        self.statusCode = statusCode
    }
    
    ///Gets the response headers from the server.
    public let headers: [HTTPHeader]

    ///Gets the response body from the server.
    public let body: Data?
    
    ///Gets the HTTP result status code.
    public let statusCode: StatusCode
}
