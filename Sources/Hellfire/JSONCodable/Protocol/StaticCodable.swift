//
//  StaticCodable.swift
//  
//
//  Created by Ed Hellyer on 1/15/24.
//

// Code is based from:
// https://github.com/GottaGetSwifty/CodableWrappers

import Foundation

public protocol StaticEncodable {
    associatedtype EncodedType: Encodable
    static func encode(value: EncodedType, to encoder: Encoder) throws
}

public protocol StaticDecodable {
    associatedtype DecodedType: Decodable
    static func decode(from decoder: Decoder) throws -> DecodedType
}

public protocol StaticCodable: StaticDecodable & StaticEncodable where DecodedType == EncodedType {
    typealias CodingType = DecodedType
}
