//
//  Collection+Extension.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/28/20.
//  Copyright © 2020 Ed Hellyer. All rights reserved.
//

import Foundation

internal extension Collection where Element == String {
    func qualityEncoded() -> String {
        enumerated().map { index, encoding in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(encoding);q=\(quality)"
        }.joined(separator: ", ")
    }
}
