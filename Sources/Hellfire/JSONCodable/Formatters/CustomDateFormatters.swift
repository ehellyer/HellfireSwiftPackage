//
//  File.swift
//  
//
//  Created by Ed Hellyer on 1/15/24.
//

import Foundation

/// Codable using format: "yyyy-MM-dd"
public struct YearMonthDayFormatter: DateFormatterStaticCodable {
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

/// Codable using format: "yyyy-MM-dd'T'HH:mm:ss"
public struct ISO8601NoMillisecondsNoTZDateFormatter: DateFormatterStaticCodable {
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
}
