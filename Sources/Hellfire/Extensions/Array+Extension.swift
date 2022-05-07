//
//  Array+Extension.swift
//  Hellfire
//
//  Created by Ed Hellyer on 2/24/22.
//

import Foundation

public extension Array where Element == HTTPHeader {
    var headers: [AnyHashable: Any] {
        get {
            var _headers = [AnyHashable: Any]()
            self.forEach({
                _headers[$0.name] = $0.value
            })
            return _headers
        }
    }
}
