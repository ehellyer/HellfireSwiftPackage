//
//  StaticCodableWrapper.swift
//
//
//  Created by Ed Hellyer on 1/15/24.
//

// Code is based from:
// https://github.com/GottaGetSwifty/CodableWrappers

import Foundation

public protocol StaticEncoderWrapper: Encodable {
    associatedtype CustomEncoder: StaticEncodable
    var wrappedValue: CustomEncoder.EncodedType { get }
}

extension StaticEncoderWrapper {
    public func encode(to encoder: Encoder) throws {
        try CustomEncoder.encode(value: wrappedValue, to: encoder)
    }
}

public protocol StaticDecoderWrapper: Decodable {
    associatedtype CustomDecoder: StaticDecodable
    init(wrappedValue: CustomDecoder.DecodedType)
}

extension StaticDecoderWrapper {
    public init(from decoder: Decoder) throws {
        self.init(wrappedValue: try CustomDecoder.decode(from: decoder))
    }
}

public protocol StaticCodingWrapper: StaticEncoderWrapper & StaticDecoderWrapper where CustomEncoder.EncodedType == CustomDecoder.DecodedType {
    associatedtype CustomCoder: StaticCodable
}

public protocol StaticCodingWrapper2: StaticCodable {
    associatedtype CustomCoder: StaticCodable
    var wrappedValue: CustomCoder { get }
    init(wrappedValue: CustomCoder)
}
