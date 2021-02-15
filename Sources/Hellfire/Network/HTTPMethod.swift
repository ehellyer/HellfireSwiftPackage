//
//  HTTPMethod.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

//https://tools.ietf.org/html/rfc7231#section-4.3
///HTTP Methods
public enum HTTPMethod: String, Hashable, JSONSerializable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case connect = "CONNECT"
    case trace = "TRACE"
    case options = "OPTIONS"
    
    public var name: String {
        return self.rawValue
    }
}
