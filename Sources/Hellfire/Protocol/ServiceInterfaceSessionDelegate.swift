//
//  ServiceInterfaceSessionDelegate.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

public protocol ServiceInterfaceSessionDelegate: class {
    
    ///Delegate implements this method and returns all required headers for the data request
    func headerCollection(forRequest dataRequest: NetworkRequest) -> [HTTPHeader]?
    
    ///Send the response headers to the session delegate.
    func responseHeaders(headers: [HTTPHeader], forRequest: NetworkRequest)
}

//Empty private protocol extension to make protocol methods optional for the delegate.
public extension ServiceInterfaceSessionDelegate {
    func headerCollection(forRequest dataRequest: NetworkRequest) -> [HTTPHeader]? { return nil }
    func responseHeaders(headers: [HTTPHeader], forRequest: NetworkRequest) {}
}
