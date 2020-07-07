//
//  Address.swift
//  Hellfire_Example
//
//  Created by Ed Hellyer on 9/2/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Hellfire

struct Address: JSONSerializable {
    var street: String
    var suite: String
    var city: String
    var zipcode: String
    var geo: Geography
}

