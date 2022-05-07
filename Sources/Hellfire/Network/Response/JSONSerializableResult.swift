//
//  JSONSerializableResult.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/27/20.
//

import Foundation

/// Represents a result of a NetworkRequest.
public enum JSONSerializableResult<T: JSONSerializable> {
    
    /// Returns a NetworkResponse upon successful execution of a NetworkRequest.
    /// - success: has an associated object of type NetworkResponse.
    case success(JSONSerializableResponse<T>)
    
    ///Returns a ServiceError upon unsuccessful execution of a NetworkRequest.
    /// - failure: has an associated object of type ServiceError
    case failure(ServiceError)
}
