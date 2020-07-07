//
//  RequestResult.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/27/20.
//

import Foundation

public enum RequestResult {
    case success(NetworkResponse)
    case failure(ServiceError)
}
