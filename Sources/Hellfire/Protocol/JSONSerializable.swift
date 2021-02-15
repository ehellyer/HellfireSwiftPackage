//
//  JSONSerializable.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

///EJH - Quick hack for now to make it work.  I need to come up with a better implementation and update this pod.
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

///Extends the Codable protocol
public protocol JSONSerializable: Codable {
    
    ///Serializes the object into a data stream of the objects JSON representation.  Typically used for data requests or persisting state.
    func toJSONData() -> Data?
    
    ///Serializes the object into a JSON string representation.  Typically used for debug.
    func toJSONString() -> String?
    
    ///Serializes the object into a of type Dictionary<String, Any>
    func toJSONObject() -> Dictionary<String, Any>?
    
    ///Deserializes the JSON data stream into an instance of the object.  Returns nil if the data stream does not match the target object graph, or the object graphs optionallity descriptors.
    static func initialize(jsonData: Data?) -> Self?
    
    ///Deserializes the dictionary into an instance of the object.  Returns nil if the dictionary representation does not match the target object graph, or the object graphs optionallity descriptors.
    static func initialize(dictionary: [String: Any]) -> Self?
}

public extension JSONSerializable {

    func toJSONData() -> Data? {
        let encoder = Self.encoder
        var encodeObject: Data? = nil
        do {
            encodeObject = try encoder.encode(self)
        } catch EncodingError.invalidValue(let invalidValue, let context) {
            print("An error occurred encoding object of type \(Self.typeName).  Error message: \(context.debugDescription)   Invalid Value: \(invalidValue)   Decoding path: \(context.codingPath)")
        } catch {
            print("An error occurred encoding object of type \(Self.typeName).  Error message: \(error.localizedDescription)")
        }
        return encodeObject
    }
    
    func toJSONString() -> String? {
        if let jsonData = self.toJSONData() {
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString
        }
        return nil
    }
    
    func toJSONObject() -> Dictionary<String, Any>? {
        guard let modelData = self.toJSONData() else { return nil }
        
        var decodedObject: Dictionary<String, Any>? = nil
        do {
            decodedObject = try JSONSerialization.jsonObject(with: modelData, options: .allowFragments) as? [String: Any]
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            print("Key not found error decoding object of type '\(Self.typeName)'. Expected value for key '\(codingKey.stringValue)'   Decoding path: \(context.codingPath)")
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            print("Type mismatch error decoding object of type '\(Self.typeName)'.  Error message: \(context.debugDescription) Expected Key Type: \(expectedKeyType)   Decoding path: \(context.codingPath)")
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            print("Value not found error decoding object of type '\(Self.typeName)'.  Error message: \(context.debugDescription) Missing value for key type: \(missingKeyType)    Decoding path: \(context.codingPath)")
        } catch DecodingError.dataCorrupted(let context) {
            print("Data corrupted error decoding object of type '\(Self.typeName)'.  Error message: \(context.debugDescription)   Decoding path: \(context.codingPath)")
        } catch {
            print("Decoding error of type '\(Self.typeName)'.  Error message: \(error.localizedDescription)")
        }
        return decodedObject
    }

    //EJH - Quick hack - I will make this better.
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssX"
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        return encoder
    }
    
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = JSONDateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }
    
    static var typeName: String {
        let metaTypeStr = String(describing: type(of: self))
        let index = metaTypeStr.index(metaTypeStr.endIndex, offsetBy: -5)
        let typeName = metaTypeStr[..<index]
        return String(typeName)
    }
    
    static func initialize(jsonData: Data?) -> Self? {
        guard let modelData = jsonData else { return nil }
        
        let decoder = Self.decoder
        var decodedObject: Self? = nil
        do {
            decodedObject = try decoder.decode(Self.self, from: modelData)
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            print("Key not found error decoding object of type '\(Self.typeName)'. Expected value for key '\(codingKey.stringValue)'   Decoding path: \(context.codingPath)")
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            print("Type mismatch error decoding object of type '\(Self.typeName)'.  Error message: \(context.debugDescription) Expected Key Type: \(expectedKeyType)   Decoding path: \(context.codingPath)")
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            print("Value not found error decoding object of type '\(Self.typeName)'.  Error message: \(context.debugDescription) Missing value for key type: \(missingKeyType)    Decoding path: \(context.codingPath)")
        } catch DecodingError.dataCorrupted(let context) {
            print("Data corrupted error decoding object of type '\(Self.typeName)'.  Error message: \(context.debugDescription)   Decoding path: \(context.codingPath)")
        } catch {
            print("Decoding error of type '\(Self.typeName)'.  Error message: \(error.localizedDescription)")
        }
        return decodedObject
    }
    
    static func initialize(dictionary: [String: Any]) -> Self? {
        let data = try? JSONSerialization.data(withJSONObject: dictionary, options: [])
        return Self.initialize(jsonData: data)
    }
}

public extension Array where Element: JSONSerializable {
    
    static func initialize(jsonData: Data?) -> [Element]? {
        guard let modelData = jsonData else { return nil }
        
        let decoder = Element.decoder
        var decodedObject: [Element]? = nil
        do {
            decodedObject = try decoder.decode([Element].self, from: modelData)
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            print("Key not found error decoding object of type '\(Element.typeName)'. Expected value for key '\(codingKey.stringValue)'   Decoding path: \(context.codingPath)")
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            print("Type mismatch error decoding object of type '\(Element.typeName)'.  Error message: \(context.debugDescription) Expected Key Type: \(expectedKeyType)   Decoding path: \(context.codingPath)")
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            print("Value not found error decoding object of type '\(Element.typeName)'.  Error message: \(context.debugDescription) Missing value for key type: \(missingKeyType)   Decoding path: \(context.codingPath)")
        } catch DecodingError.dataCorrupted(let context) {
            print("Data corrupted error decoding object of type '\(Element.typeName)'.  Error message: \(context.debugDescription)   Decoding path: \(context.codingPath)")
        } catch {
            print("Decoding error of type '\(Element.typeName)'.  Error message: \(error.localizedDescription)")
        }
        return decodedObject
    }
}

public extension Array where Element: JSONSerializable {
    
    func toJSONData() -> Data? {
        let encoder = Element.encoder
        var encodeObject: Data? = nil
        do {
            encodeObject = try encoder.encode(self)
        } catch EncodingError.invalidValue(let invalidValue, let context) {
            print("An error occurred encoding object of type \(Element.typeName).  Error message: \(context.debugDescription)  Invalid Value: \(invalidValue)   Decoding path: \(context.codingPath)")
        } catch {
            print("An error occurred encoding object of type \(Element.typeName).  Error message: \(error.localizedDescription)")
        }
        return encodeObject
    }
    
    func toJSONString() -> String? {
        if let jsonData = self.toJSONData() {
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString
        }
        return nil
    }
}
