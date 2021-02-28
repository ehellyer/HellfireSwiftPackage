//
//  URLSessionTask+Extension.swift
//  Hellfire
//
//  Created by Ed Hellyer on 2/23/21.
//

import Foundation

private var associateKey: Void?

public extension URLSessionTask {
    var requestItem: RequestItem? {
        get {
            return objc_getAssociatedObject(self, &associateKey) as? RequestItem
        }
        set {
            objc_setAssociatedObject(self, &associateKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}
