//
//  HellfireError+LocalizedError.swift
//  Hellfire
//
//  Created by Ed Hellyer on 5/4/22.
//

import Foundation

extension HellfireError: LocalizedError {
    public var errorDescription: String? {
        return self.description
    }
}
