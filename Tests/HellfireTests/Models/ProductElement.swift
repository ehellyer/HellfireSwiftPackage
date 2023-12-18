//
//  ProductElement.swift
//
//
//  Created by Ed Hellyer on 1/7/24.
//

import Foundation
import Hellfire

struct ProductElement: JSONSerializable {
    
    let id: Int?
    let title: String?
    let price: Double?
    let description: String?
    let images: [String]
    let creationAt: Date?
    let updatedAt: Date?
    let category: Category
}

extension ProductElement: CustomDateCodable {
    static var dateFormats: [String: String] {
        return [CodingKeys.creationAt.stringValue: "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                CodingKeys.updatedAt.stringValue: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"]
    }
}

struct Category: Codable {
    let id: Int?
    let name: String
    let image: String?
    let creationAt: String?
    let updatedAt: String?
}
