//
//  ISO8601DateStaticCodable.swift
//
//
//  Created by Ed Hellyer on 1/15/24.
//

import Foundation

/// Codable using format: "yyyy-MM-dd'T'HH:mm:ssZ"
public struct ISO8601DateStaticCodable: ISO8601DateFormatterStaticCodable {
    
    public static let iso8601DateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions =  [.withInternetDateTime, .withDashSeparatorInDate]
        return formatter
    }()
}

