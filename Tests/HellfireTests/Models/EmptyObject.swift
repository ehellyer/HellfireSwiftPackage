//
//  EmptyObject.swift
//
//
//  Created by Ed Hellyer on 1/6/24.
//

import Foundation
import Hellfire

struct EmptyObject: JSONSerializable {
    
    var propertyOne: Int?
    
    var propertyTwo: String?
    
    @OptionalCoding<CodingUses<ISO8601DateStaticCodable>>
    var propertyThree: Date?
}
