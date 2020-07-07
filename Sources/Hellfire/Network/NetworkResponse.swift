//
//  NetworkResponse.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/21/20.
//

import Foundation

///Describes the successful response of an HTTP \ HTTPS call to a server
public struct NetworkResponse {
    
    ///Gets the response headers from the server.
    public let headers: [HTTPHeader]

    ///Gets the response body from the server.
    public let body: Data?
    
    ///Gets the HTTP result status code
    public let statusCode: StatusCode
}
