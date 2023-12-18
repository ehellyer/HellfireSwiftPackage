//
//  ISO8601DateFormatterStaticCodable.swift
//  
//
//  Created by Ed Hellyer on 1/15/24.
//

// Code is based from:
// https://github.com/GottaGetSwifty/CodableWrappers

import Foundation

public protocol ISO8601DateFormatterStaticDecodable: StaticDecodable {
    static var iso8601DateFormatter: ISO8601DateFormatter { get }
}

extension ISO8601DateFormatterStaticDecodable {
    public static func decode(from decoder: Decoder) throws -> Date {
        let stringValue = try String(from: decoder)
        
        guard let value = iso8601DateFormatter.date(from: stringValue) else {
            let description = "Could not convert \(stringValue) to Date"
            throw DecodingError.valueNotFound(self,  DecodingError.Context(codingPath: decoder.codingPath,
                                                                           debugDescription: description))
        }
        return value
    }
}

public protocol ISO8601DateFormatterStaticEncodable: StaticEncodable {
    static var iso8601DateFormatter: ISO8601DateFormatter { get }
}

extension ISO8601DateFormatterStaticEncodable {
    public static func encode(value: Date, to encoder: Encoder) throws {
        try iso8601DateFormatter.string(from: value).encode(to: encoder)
    }
}

public typealias ISO8601DateFormatterStaticCodable = StaticCodable & ISO8601DateFormatterStaticEncodable & ISO8601DateFormatterStaticDecodable
