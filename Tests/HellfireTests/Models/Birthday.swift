//
//  Birthday.swift
//  Hellfire_Example
//
//  Created by Ed Hellyer on 9/2/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Hellfire

struct Birthday: JSONSerializable {
    var birthdate: Date
    static var dateformat: String = "yyyy-MM-dd"
}
