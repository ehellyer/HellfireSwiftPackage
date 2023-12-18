//
//  Person.swift
//  Hellfire_Example
//
//  Created by Ed Hellyer on 9/2/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Hellfire

/// Person - Hellfire test struct sort of representing a person.
struct Person: JSONSerializable {
    
    /// Gets or sets the persons first name.
    ///
    /// Encoded to, and decoded from, this key "first_Name"
    var firstName: String
    
    /// Gets or sets the persons last name.
    ///
    /// Encoded to, and decoded from, this key "last_Name"
    var lastName: String
    
    /// Gets or sets if this person is awesome.
    ///
    /// - nil = 🤷🏻‍♂️ - I don't know if they are awesome or not.
    /// - true = Person is verified awesome.
    /// - false = Person is verified to be not an awesome person.
    var isAwesome: Bool?
    
    /// Gets or sets the person birthdate.
    ///
    /// Only the Year Month and Date is set, ignore the time and TZ components of this date instance.
    ///
    /// Encoded to, and decoded from, this format "yyyy-MM-dd"
    var birthdate: Date
    
    /// Gets or sets the appointment time.  What appointment?  I do not know, this is just for a demo.
    ///
    /// Encoded to, and decoded from, this format "yyyy-MM-dd'T'HH:mm:ssZ"
    var appointmentTime: Date?
    
    /// Another date property who's format does not have TZ info, "yyyy-MM-dd'T'HH:mm:ss".
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

extension Person: CustomDateCodable {
    static var dateFormats: [String: String] {
        return [CodingKeys.birthdate.stringValue: "yyyy-MM-dd",
                CodingKeys.appointmentTime.stringValue: "yyyy-MM-dd'T'HH:mm:ssZ",
                CodingKeys.someOtherDate.stringValue: "yyyy-MM-dd'T'HH:mm:ss"]
    }
}
