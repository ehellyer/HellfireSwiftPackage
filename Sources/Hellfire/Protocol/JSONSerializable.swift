//
//  JSONSerializable.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

///EJH - Quick hack for now to make it work.  I need to come up with a better implementation and update this code.
class JSONDateFormatter: DateFormatter {
    
    private var dateFormats: [String] = ["yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ", "MM/dd/yyyy"]
    
    override func date(from string: String) -> Date? {
        var date: Date?
        for format in self.dateFormats {
            super.dateFormat = format
            date = super.date(from: string)
            if date != nil {
                break;
            }
        }
        
        return date
    }
}

/// Adds functionality to the Codable protocol so that structs and classes that implement the JSONSerializable protocol can be decoded or encoded with very little effort.
public protocol JSONSerializable: Codable {
    
    /// Serializes the object into a data stream of the objects JSON representation.  Typically used for data requests or persisting state.
    func toJSONData() throws -> Data
    
    /// Serializes the object into a JSON string representation.  Typically used for debug.
    func toJSONString() throws -> String
    
    /// Serializes the object into a of type Dictionary<String, Any>
    func toJSONObject() throws -> Dictionary<String, Any>
    
    /// Deserializes the JSON data stream into an instance of the object.  Returns nil if the data stream does not match the target object graph, or the object graphs optionality descriptors.
    static func initialize(jsonData: Data?) throws -> Self
    
    /// Deserializes the dictionary into an instance of the object.  Returns nil if the dictionary representation does not match the target object graph, or the object graphs optionality descriptors.
    static func initialize(dictionary: [String: Any]?) throws -> Self
}

public extension JSONSerializable {

    func toJSONData() throws -> Data {
        do {
            let encoder = Self.encoder
            let encodeObject: Data = try encoder.encode(self)
            return encodeObject
        } catch EncodingError.invalidValue(let invalidValue, let context) {
            let message = "An error occurred encoding object of type \(Self.typeName).  Error message: \(context.debugDescription)  Invalid Value: \(invalidValue)   Decoding path: \(context.codingPath)."
            throw HellfireError.JSONSerializableError.encodingError.invalidValue(message: message)
        } catch {
            let message = "An error occurred encoding object of type \(Self.typeName).  Error message: \(error.localizedDescription)."
            throw HellfireError.JSONSerializableError.encodingError.exception(message: message)
        }
    }
    
    func toJSONString() throws -> String {
        let jsonData = try self.toJSONData()
        let jsonString = String(data: jsonData, encoding: .utf8)
        return jsonString!
    }
    
    func toJSONObject() throws -> Dictionary<String, Any> {
        let modelData = try self.toJSONData()
        var decodedObject: Dictionary<String, Any>
        do {
            decodedObject = try JSONSerialization.jsonObject(with: modelData, options: .allowFragments) as! [String: Any]
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            let message = "Key not found error decoding instance of `\(Self.typeName)`.Expected value for key '\(codingKey.stringValue)'.\nDecoding path: \(Self.decodeCodingPath(context.codingPath))\nError message: \(context.debugDescription)\n."
            throw HellfireError.JSONSerializableError.decodingError.keyNotFound(message: message)
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            let message = "Type mismatch error decoding instance of '\(Self.typeName)'.\nExpected Type: \(expectedKeyType)\nDecoding path: \(Self.decodeCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw HellfireError.JSONSerializableError.decodingError.typeMismatch(message: message)
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            let message = "Value not found error decoding instance of '\(Self.typeName)'.\nMissing value for type: \(missingKeyType)\nDecoding path: \(Self.decodeCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw HellfireError.JSONSerializableError.decodingError.valueNotFound(message: message)
        } catch DecodingError.dataCorrupted(let context) {
            let message = "Data corrupted when decoding instance of '\(Self.typeName)'.\nDecoding path: \(Self.decodeCodingPath(context.codingPath))\nError message: \(context.debugDescription)."
            throw HellfireError.JSONSerializableError.decodingError.dataCorrupted(message: message)
        } catch {
            let message = "Decoding error of type '\(Self.typeName)'.\nError message: \(error.localizedDescription)."
            throw  HellfireError.JSONSerializableError.decodingError.exception(message: message)
        }
        return decodedObject
    }

    static func initialize(jsonData: Data?) throws -> Self {
        guard let modelData = jsonData, modelData.count > 0 else {
            throw HellfireError.JSONSerializableError.zeroLengthResponseFromServer
        }
        var decodedObject: Self
        do {
            decodedObject = try Self.decoder.decode(Self.self, from: modelData)
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            let message = "Key not found error decoding instance of `\(Self.typeName)`.Expected value for key '\(codingKey.stringValue)'.\nDecoding path: \(Self.decodeCodingPath(context.codingPath))\nError message: \(context.debugDescription)\n."
            throw HellfireError.JSONSerializableError.decodingError.keyNotFound(message: message)
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            let message = "Type mismatch error decoding instance of '\(Self.typeName)'.\nExpected Type: \(expectedKeyType)\nDecoding path: \(Self.decodeCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw HellfireError.JSONSerializableError.decodingError.typeMismatch(message: message)
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            let message = "Value not found error decoding instance of '\(Self.typeName)'.\nMissing value for type: \(missingKeyType)\nDecoding path: \(Self.decodeCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw HellfireError.JSONSerializableError.decodingError.valueNotFound(message: message)
        } catch DecodingError.dataCorrupted(let context) {
            let message = "Data corrupted when decoding instance of '\(Self.typeName)'.\nDecoding path: \(Self.decodeCodingPath(context.codingPath))\nError message: \(context.debugDescription)."
            throw HellfireError.JSONSerializableError.decodingError.dataCorrupted(message: message)
        } catch {
            let message = "Decoding error of type '\(Self.typeName)'.\nError message: \(error.localizedDescription)."
            throw  HellfireError.JSONSerializableError.decodingError.exception(message: message)
        }
        return decodedObject
    }
    
    static func decodeCodingPath(_ codingPath: [CodingKey]) -> String {
        return codingPath.compactMap({ $0.stringValue }).joined(separator: " ")
    }
    
    static func initialize(dictionary: [String: Any]?) throws -> Self {
        guard let dictionary = dictionary, dictionary.keys.count > 0 else {
            throw HellfireError.JSONSerializableError.zeroLengthResponseFromServer
        }
        
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        return try Self.initialize(jsonData: data)
    }
    
    //MARK: - Private Static API
    
    fileprivate static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssX"
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        return encoder
    }
    
    fileprivate static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = JSONDateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }
    
    fileprivate static var typeName: String {
        let metaTypeStr = String(describing: type(of: self))
        let index = metaTypeStr.index(metaTypeStr.endIndex, offsetBy: -5)
        let typeName = metaTypeStr[..<index]
        return String(typeName)
    }
}

extension Array: JSONSerializable where Element: JSONSerializable {
    
    public func toJSONData() throws -> Data {
        do {
            let encoder = Element.encoder
            let encodeObject: Data = try encoder.encode(self)
            return encodeObject
        } catch EncodingError.invalidValue(let invalidValue, let context) {
            let message = "An error occurred encoding object of type \(Element.typeName).  Error message: \(context.debugDescription)  Invalid Value: \(invalidValue)   Decoding path: \(context.codingPath)."
            throw HellfireError.JSONSerializableError.encodingError.invalidValue(message: message)
        } catch {
            let message = "An error occurred encoding object of type \(Element.typeName).  Error message: \(error.localizedDescription)."
            throw HellfireError.JSONSerializableError.encodingError.exception(message: message)
        }
    }
    
    public static func initialize(jsonData: Data?) throws -> [Element] {
        guard let modelData = jsonData, modelData.count > 0 else {
            throw HellfireError.JSONSerializableError.zeroLengthResponseFromServer
        }
        
        var decodedObject: [Element]
        do {
            decodedObject = try Element.decoder.decode([Element].self, from: modelData)
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            let message = "Key not found error decoding instance of `\(Self.typeName)`.Expected value for key '\(codingKey.stringValue)'.\nDecoding path: \(Self.decodeCodingPath(context.codingPath))\nError message: \(context.debugDescription)\n."
            throw HellfireError.JSONSerializableError.decodingError.keyNotFound(message: message)
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            let message = "Type mismatch error decoding instance of '\(Self.typeName)'.\nExpected Type: \(expectedKeyType)\nDecoding path: \(Self.decodeCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw HellfireError.JSONSerializableError.decodingError.typeMismatch(message: message)
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            let message = "Value not found error decoding instance of '\(Self.typeName)'.\nMissing value for type: \(missingKeyType)\nDecoding path: \(Self.decodeCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw HellfireError.JSONSerializableError.decodingError.valueNotFound(message: message)
        } catch DecodingError.dataCorrupted(let context) {
            let message = "Data corrupted when decoding instance of '\(Self.typeName)'.\nDecoding path: \(Self.decodeCodingPath(context.codingPath))\nError message: \(context.debugDescription)."
            throw HellfireError.JSONSerializableError.decodingError.dataCorrupted(message: message)
        } catch {
            let message = "Decoding error of type '\(Self.typeName)'.\nError message: \(error.localizedDescription)."
            throw  HellfireError.JSONSerializableError.decodingError.exception(message: message)
        }
        return decodedObject
    }
    
    public static func initialize(dictionary: [String : Any]?) throws -> Array<Element> {
        throw HellfireError.JSONSerializableError.inappropriateInit(message: "Init of Array<JSONSerializable> from dictionary is not supported.")
    }
}
