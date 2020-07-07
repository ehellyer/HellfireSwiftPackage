//
//  ReachabilityStatus.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

public enum ReachabilityConnectionType {
    case wiFiOrEthernet
    case cellular
}

public enum ReachabilityStatus {
    case unknown
    case notReachable
    case reachable(ReachabilityConnectionType)
}

extension ReachabilityStatus: Equatable {
    public static func == (lhs: ReachabilityStatus, rhs: ReachabilityStatus) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true
        case (.notReachable, .notReachable):
            return true
        case let (.reachable(lhsConnectionType), .reachable(rhsConnectionType)):
            return lhsConnectionType == rhsConnectionType
        default:
            return false
        }
    }
}
