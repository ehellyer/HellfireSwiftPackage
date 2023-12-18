//
//  DateFormatterStaticCodable.swift
//
//
//  Created by Ed Hellyer on 1/15/24.
//

// Code is based from:
// https://github.com/GottaGetSwifty/CodableWrappers

import Foundation

public protocol DateFormatterStaticDecodable: StaticDecodable {
    static var dateFormatter: DateFormatter { get }
}

extension DateFormatterStaticDecodable {
    public static func decode(from decoder: Decoder) throws -> Date {
        let stringValue = try String(from: decoder)
        
        guard let value = dateFormatter.date(from: stringValue) else {
            let description = "Could not convert \(stringValue) to Date"
            throw DecodingError.valueNotFound(self,  DecodingError.Context(codingPath: decoder.codingPath,
                                                                           debugDescription: description))
        }
        return value
    }
}

public protocol DateFormatterStaticEncodable: StaticEncodable {
    static var dateFormatter: DateFormatter { get }
}

extension DateFormatterStaticEncodable {
    public static func encode(value: Date, to encoder: Encoder) throws {
        try dateFormatter.string(from: value).encode(to: encoder)
    }
}

public typealias DateFormatterStaticCodable = StaticCodable & DateFormatterStaticEncodable & DateFormatterStaticDecodable
