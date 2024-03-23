//
//  JSONSerializableResponse.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/21/20.
//

import Foundation

/// Represents the result of a data task request, downloaded as a JSONSerializable type into memory.
public class JSONSerializableResponse<T: JSONSerializable> {
    
    /// Creates an instance of `JSONSerializableResponse<T>`
    /// - Parameters:
    ///   - headers: Sets the response headers from the server.
    ///   - statusCode: Sets the HTTP result status code.
    ///   - jsonObject: The jsonObject of `JSONSerializable` type defined in the original request.
    public init(headers: [HTTPHeader], 
                statusCode: StatusCode?,
                jsonObject: T) {
        self.headers = headers
        self.statusCode = statusCode
        self.jsonObject = jsonObject
    }
    
    /// Gets the response headers from the server.
    public let headers: [HTTPHeader]

    /// Gets the jsonObject
    public let jsonObject: T
    
    /// Gets the HTTP result status code.
    public let statusCode: StatusCode?
}
