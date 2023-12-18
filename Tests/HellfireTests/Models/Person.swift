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
    
    /// Encoded to and decoded from this key "first_Name"
    var firstName: String
    
    /// Encoded to and decoded from this key "last_Name"
    var lastName: String
    
    /// Encode to and decoded from this key "a_fantastic_person"
    var isAwesome: Bool?
    
    /// Encoded to and decoded from, this format "yyyy-MM-dd"
    @CodingUses<YearMonthDayFormatter>
    var birthdate: Date
    
    /// Optionally, encoded to and decoded from this format "yyyy-MM-dd'T'HH:mm:ssZ", using this key "apt_time".
    @OptionalCoding<CodingUses<ISO8601DateStaticCodable>>
    var appointmentTime: Date?
    
    /// Optionally, encoded to and decoded from this format "yyyy-MM-dd'T'HH:mm:ss".
    @OptionalCoding<CodingUses<ISO8601NoMillisecondsNoTZDateFormatter>>
    var someOtherDate: Date?
}

extension Person {
    private enum CodingKeys: String, CodingKey {
        case firstName = "first_Name"
        case lastName = "last_Name"
        case isAwesome = "a_fantastic_person"
        case birthdate
        case appointmentTime = "apt_time"
        case someOtherDate
    }
}
