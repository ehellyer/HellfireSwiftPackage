//
//  CustomDateCodable.swift
//  HellFire
//
//  Created by Ed Hellyer on 12/13/23.
//  Copyright © 2023 Ed Hellyer. All rights reserved.
//

import Foundation

public protocol CustomDateCodable {
    static var dateFormats: [String: String] { get }
}

extension CustomDateCodable {
    var dateFormats: [String: String] { Self.dateFormats }
}
