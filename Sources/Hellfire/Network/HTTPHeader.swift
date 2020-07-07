//
//  HTTPHeader.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

///Represents a name and value of an HTTP header.
public struct HTTPHeader: Hashable {
    
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
    ///Gets the name of the HTTPHeader
    public let name: String
    
    ///Gets the values of the HTTPHeder
    public let value: String
}
