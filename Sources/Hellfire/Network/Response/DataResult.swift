//
//  DataResult.swift
//  Hellfire
//
//  Created by Ed Hellyer on 10/3/21.
//

import Foundation

/// Represents a result of a NetworkRequest.
public enum DataResult {
    
    /// Returns a NetworkResponse upon successful execution of a NetworkRequest.
    /// - success: has an associated object of type NetworkResponse.
    case success(DataResponse)
    
    ///Returns a ServiceError upon unsuccessful execution of a NetworkRequest.
    /// - failure: has an associated object of type ServiceError
    case failure(ServiceError)
}
