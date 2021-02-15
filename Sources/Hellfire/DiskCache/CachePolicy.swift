//
//  CachePolicy.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

public enum CachePolicyType {
    case hour
    case fourHours
    case day
    case week
    case month
    case untilSpaceNeeded
    case doNotCache
    
    var ttlInSeconds: UInt32 {
        switch self {
        case .hour: return 3600
        case .fourHours: return 14400
        case .day: return 86400
        case .week: return 604800
        case .month: return 2721600
        case .untilSpaceNeeded: return 32659200
        case .doNotCache: return 0
        }
    }
    
    var folderName: String {
        switch self {
        case .hour: return "HourCache"
        case .fourHours: return "FourHourCache"
        case .day: return "DayCache"
        case .week: return "WeekCache"
        case .month: return "MonthCache"
        case .untilSpaceNeeded: return "UntilSpaceNeeded"
        case .doNotCache: return "DoNotCache"
        }
    }
    
    var maxByteSize: UInt64 {
        switch self {
        case .hour: return 50331648
        case .fourHours: return 104857600
        case .day: return 262144000
        case .week: return 524288000
        case .month: return 1073741824
        case .untilSpaceNeeded: return 1073741824
        case .doNotCache: return 0
        }
    }
}

internal class CachePolicySetting: Hashable {
    
    static func == (lhs: CachePolicySetting, rhs: CachePolicySetting) -> Bool {
        return lhs.policyType == rhs.policyType
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.policyType)
    }
    
    let policyType: CachePolicyType
    
    init(policyType:CachePolicyType) {

        self.policyType = policyType
        self.bytesUsed = 0
        
        let appName = ProcessInfo.processInfo.processName
        let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.absoluteURL
        self.rootPath = cachePath.appendingPathComponent(appName)
    }

    let rootPath: URL

    var folderURL: URL {
        get {
            return self.rootPath.appendingPathComponent(self.policyType.folderName)
        }
    }
    
    var bytesUsed: UInt64
    
    var ttlInSeconds: UInt32 {
        get {
            return self.policyType.ttlInSeconds
        }
    }
    
    var maxByteSize: UInt64 {
        get {
            return self.policyType.maxByteSize
        }
    }
    
    var cachePolicy: CachePolicyType {
        get {
            return self.policyType
        }
    }
}

internal class CachePolicy {
    
    private let policies: [CachePolicySetting] = [CachePolicySetting.init(policyType: CachePolicyType.doNotCache),
                                                  CachePolicySetting.init(policyType: CachePolicyType.hour),
                                                  CachePolicySetting.init(policyType: CachePolicyType.fourHours),
                                                  CachePolicySetting.init(policyType: CachePolicyType.day),
                                                  CachePolicySetting.init(policyType: CachePolicyType.week),
                                                  CachePolicySetting.init(policyType: CachePolicyType.month),
                                                  CachePolicySetting.init(policyType: CachePolicyType.untilSpaceNeeded)]
    
    func policy(forType policyType:CachePolicyType) -> CachePolicySetting {
        let setting = self.policies.first(where: { $0.policyType == policyType })
        //Force unwrap because this should always work.  If it doesn't work, you probably forgot to add the setting to the policies array.
        return setting!
    }
    
    func allPolicies() -> [CachePolicySetting] {
        return self.policies
    }
}

