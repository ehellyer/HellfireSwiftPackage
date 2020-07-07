//
//  Person.swift
//  Hellfire_Example
//
//  Created by Ed Hellyer on 9/2/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Hellfire

struct Person: JSONSerializable {
    var firstName: String
    var lastName: String
    var isAwesome: Bool
}

extension Person {
    private enum CodingKeys: String, CodingKey {
        case firstName = "first_Name"
        case lastName = "last_Name"
        case isAwesome = "a_fantastic_person"
    }
}
