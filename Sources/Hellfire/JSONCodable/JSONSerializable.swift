//
//  JSONSerializable.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

//MARK: - JSONSerializable protocol Definition

/// Adds functionality to the Codable protocol so that simple or complex structs and/or classes that implement JSONSerializable, can be decoded or encoded with very little effort.
public protocol JSONSerializable: Codable {
    
    /// Serializes the object into a data stream of the objects JSON representation.  Typically used for data requests or persisting state to some permanent storage.
    func toJSONData() throws -> Data
    
    /// Serializes the object into a JSON string representation.  Typically used for debug or persisting state to some permanent storage.
    func toJSONString() throws -> String
    
    /// Serializes the object into a of type Dictionary<String, Any>.  Typically used to make our JS friends happy.
    func toJSONObject() throws -> Dictionary<String, Any>
    
    /// Initializer for JSONSerializable type.
    /// - Parameter jsonData: The UTF8 encoded data.
    /// - Returns: Returns a new instance of the JSONSerializable type.
    static func initialize(jsonData: Data?) throws -> Self
}

//MARK: - JSONSerializable protocol Implementation

/// Implements the functions of JSONSerializable protocol.
public extension JSONSerializable {
    
    func toJSONData() throws -> Data {
        do {
            let encodeObject: Data = try Self.jsonEncoder.encode(self)
            return encodeObject
        } catch EncodingError.invalidValue(let invalidValue, let context) {
            let message = "An error occurred encoding object of type \(Self.typeName).  Error message: \(context.debugDescription)  Invalid Value: \(invalidValue)   Decoding path: \(context.codingPath)."
            throw JSONSerializableError.encodingError.invalidValue(message: message)
        } catch {
            let message = "An error occurred encoding object of type \(Self.typeName).  Error message: \(error.localizedDescription)."
            throw JSONSerializableError.encodingError.exception(message: message)
        }
    }
    
    func toJSONString() throws -> String {
        let jsonData = try self.toJSONData()
        let jsonString = String(data: jsonData, encoding: .utf8)
        return jsonString!
    }
    
    func toJSONObject() throws -> Dictionary<String, Any> {
        guard self is Array<JSONSerializable> == false else {
            throw JSONSerializableError.encodingError.exception(message: "Error, cannot convert Array<JSONSerializable> to Dictionary.")
        }
        
        let modelData = try self.toJSONData()
        var decodedObject: Dictionary<String, Any>
        do {
            decodedObject = try JSONSerialization.jsonObject(with: modelData, options: .allowFragments) as! [String: Any]
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            let message = "Key not found error decoding instance of `\(Self.typeName)`.\nExpected value for key '\(codingKey.stringValue)'.\nDecoding path: \(Self.debugCodingPath(context.codingPath))\nError message: \(context.debugDescription)\n."
            throw JSONSerializableError.decodingError.keyNotFound(message: message)
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            let message = "Type mismatch error decoding instance of '\(Self.typeName)'.\nExpected Type: \(expectedKeyType)\nDecoding path: \(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.typeMismatch(message: message)
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            let message = "Value not found error decoding instance of '\(Self.typeName)'.\nMissing value for type: \(missingKeyType)\nDecoding path: \(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.valueNotFound(message: message)
        } catch DecodingError.dataCorrupted(let context) {
            let message = "Data corrupted when decoding instance of '\(Self.typeName)'.\nDecoding path: \(Self.debugCodingPath(context.codingPath))\nError message: \(context.debugDescription)."
            throw JSONSerializableError.decodingError.dataCorrupted(message: message)
        } catch {
            let message = "Exception decoding type '\(Self.typeName)'.\nError message: \(error)"
            throw JSONSerializableError.decodingError.exception(message: message)
        }
        return decodedObject
    }
}

//MARK: - JSONSerializable Object Initializers

extension JSONSerializable {
    
    public static func initialize(jsonData: Data?) throws -> Self {
        
        /*
         Nil coalesce to empty representation and let JSONDecoder determine if the definition supports it.
         If the model definition does not support empty object, JSONSerializable will throw a decoder
         exception and this will then be handled by the caller as a failed decode operation with all the
         necessary information to triage.
         */
        let modelData = jsonData ?? "{}".data(using: .utf8)!
        
        do {
            return try Self.jsonDecoder.decode(Self.self, from: modelData)
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            let message = "Key not found error decoding instance of `\(Self.typeName)`.\nExpected value for key '\(codingKey.stringValue)'. \nDecoding path: \(Self.debugCodingPath(context.codingPath)) \nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.keyNotFound(message: message)
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            let message = "Type mismatch error decoding instance of '\(Self.typeName)'.\nExpected Type: \(expectedKeyType)\nDecoding path: \(Self.typeName).\(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.typeMismatch(message: message)
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            let message = "Value not found error decoding instance of '\(Self.typeName)'.\nMissing value for type: \(missingKeyType)\nDecoding path: \(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.valueNotFound(message: message)
        } catch DecodingError.dataCorrupted(let context) {
            let message = "Data corrupted when decoding instance of '\(Self.typeName)' - check for malformed JSON.\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.dataCorrupted(message: message)
        } catch {
            let message = "Exception decoding type '\(Self.typeName)'.\nError message: \(error)"
            throw JSONSerializableError.decodingError.exception(message: message)
        }
    }
    
    /// Initialize a new instance from a dictionary representation.
    ///
    /// Returns an empty object if the parameter is nil or is the JSON data representation of an empty object, but only if the model definition supports it.
    /// - Parameter dictionary: The dictionary representation of the type to be decoded.
    public init(dictionary: [String: Any]?) throws {
        if let dictionary {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            self = try Self.initialize(jsonData: data)
        } else {
            self = try Self.initialize(jsonData: nil)
        }
    }
}

//MARK: - JSONSerializable Array Implementation

extension Array: JSONSerializable where Element: JSONSerializable {
    
    /// Initializer for  a new instance of `Array<JSONSerializable>`.
    /// - Parameter jsonData: The UTF8 encoded data representation of the `Array<JSONSerializable>`.
    /// - Returns: Returns a new instance of `Array<JSONSerializable>`.
    public static func initialize(jsonData: Data?) throws -> [Element] {

        /*
         Nil coalesce to empty representation and let JSONDecoder determine if the definition supports it.
         If the model definition does not support empty object, JSONSerializable will throw a decoder
         exception and this will then be handled by the caller as a failed decode operation with all the
         necessary information to triage.
         */
        let modelData = jsonData ?? "[]".data(using: .utf8)!

        do {
            return try Element.jsonDecoder.decode([Element].self, from: modelData)
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            let message = "Key not found error decoding instance of `\(Self.typeName)`.\nExpected value for key '\(codingKey.stringValue)'.\nDecoding path: \(Self.debugCodingPath(context.codingPath))\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.keyNotFound(message: message)
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            let message = "Type mismatch error decoding instance of '\(Self.typeName)'.\nExpected Type: \(expectedKeyType)\nDecoding path: \(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.typeMismatch(message: message)
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            let message = "Value not found error decoding instance of '\(Self.typeName)'.\nMissing value for type: \(missingKeyType)\nDecoding path: \(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.valueNotFound(message: message)
        } catch DecodingError.dataCorrupted(let context) {
            let message = "Data corrupted when decoding instance of '\(Self.typeName)'.\nDecoding path: \(Self.debugCodingPath(context.codingPath))\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.dataCorrupted(message: message)
        } catch {
            let message = "Exception decoding type '\(Self.typeName)'.\nError message: \(error)"
            throw JSONSerializableError.decodingError.exception(message: message)
        }
    }
    
    public func toJSONData() throws -> Data {
        do {
            let jsonEncoder = Element.jsonEncoder
            let encodeObject: Data = try jsonEncoder.encode(self)
            return encodeObject
        } catch EncodingError.invalidValue(let invalidValue, let context) {
            let message = "An error occurred encoding object of type \(Element.typeName).  Error message: \(context.debugDescription)  Invalid Value: \(invalidValue)   Decoding path: \(context.codingPath)."
            throw JSONSerializableError.encodingError.invalidValue(message: message)
        } catch {
            let message = "An error occurred encoding object of type \(Element.typeName).  Error message: \(error)"
            throw JSONSerializableError.encodingError.exception(message: message)
        }
    }
}

extension JSONSerializable {
    
    //MARK: - Private Static API
    
    fileprivate static func debugCodingPath(_ codingPath: [CodingKey]) -> String {
        
        let debugString = codingPath.compactMap({
            if $0.intValue != nil {
                return "[\($0.intValue!)]"
            } else {
                return $0.stringValue
            }
        }).reduce("", {
            if $0 == "" {
                return $1
            } else if $1.first == "[" && $1.last == "]" {
                return $0 + $1
            } else {
                return $0 + "." + $1
            }
        })
        
        return debugString
    }

    fileprivate static var jsonEncoder: JSONEncoder {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .formatted(ISO8601DateFormatter.dateFormatter)
        return jsonEncoder
    }
    
    fileprivate static var jsonDecoder: JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(ISO8601DateFormatter.dateFormatter)
        return jsonDecoder
    }
    
    fileprivate static var typeName: String {
        return String(describing: Self.self)
    }
}

/// Codable using format: "yyyy-MM-dd'T'HH:mm:ssZ"
fileprivate struct ISO8601DateFormatter {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
}

public enum JSONSerializableError: Error {
    
    public enum customDecodableError: Error {
        case keyNotFound(message: String)
        case notImplemented(message: String)
    }
    
    public enum encodingError: Error {
        case invalidValue(message: String)
        case exception(message: String)
    }
    
    public enum decodingError: Error {
        case keyNotFound(message: String)
        case typeMismatch(message: String)
        case valueNotFound(message: String)
        case dataCorrupted(message: String)
        case exception(message: String)
    }
}

extension JSONSerializableError.decodingError: CustomStringConvertible {
    public var description: String {
        switch self {
            case .keyNotFound(let message):
                return message
            case .valueNotFound(let message):
                return message
            case .dataCorrupted(let message):
                return message
            case .typeMismatch(let message):
                return message
            case .exception(let message):
                return message
        }
    }
    
    public var localizedDescription: String {
        return self.description
    }
}

extension JSONSerializableError.encodingError: CustomStringConvertible {
    public var description: String {
        switch self {
            case .invalidValue(let message):
                return message
            case .exception(let message):
                return message
        }
    }
    
    public var localizedDescription: String {
        return self.description
    }
}
