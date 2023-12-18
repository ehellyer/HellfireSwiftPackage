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
    
    @OptionalCoding<CodingUses<ISO8601DateStaticCodable>>
    var creationAt: Date?
    
    @OptionalCoding<CodingUses<ISO8601DateStaticCodable>>
    var updatedAt: Date?
    
    let category: Category
}

struct Category: Codable {
    let id: Int?
    let name: String
    let image: String?
    let creationAt: String?
    let updatedAt: String?
}
