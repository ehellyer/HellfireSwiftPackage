//
//  User.swift
//  Hellfire_Example
//
//  Created by Ed Hellyer on 9/2/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Hellfire

struct User: JSONSerializable {
    var id: Int
    var name: String
    var username: String
    var email: String
    var address: Address
    var phone: String
    var website: String
    var company: Company
}
