//
//  StaticCodable.swift
//
//
//  Created by Ed Hellyer on 1/15/24.
//

// Code is based from:
// https://github.com/GottaGetSwifty/CodableWrappers

import Foundation

@propertyWrapper
public struct EncodingUses<CustomEncoder: StaticEncodable>: StaticEncoderWrapper {
    
    public var wrappedValue: CustomEncoder.EncodedType
    public init(wrappedValue: CustomEncoder.EncodedType) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper
public struct DecodingUses<CustomDecoder: StaticDecodable>: StaticDecoderWrapper {
    
    public var wrappedValue: CustomDecoder.DecodedType
    public init(wrappedValue: CustomDecoder.DecodedType) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper
public struct CodingUses<CustomCoder: StaticCodable>: StaticCodingWrapper {
    public typealias CustomEncoder = CustomCoder
    public typealias CustomDecoder = CustomCoder
    
    public var wrappedValue: CustomCoder.CodingType
    public init(wrappedValue: CustomCoder.CodingType) {
        self.wrappedValue = wrappedValue
    }
}





