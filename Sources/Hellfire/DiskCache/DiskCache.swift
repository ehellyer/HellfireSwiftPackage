//
//  DiskCache.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

internal class DiskCache {
    
    deinit {
        #if DEBUG
        print("\(String(describing: type(of: self))) has deallocated. - \(#function)")
        #endif
    }
    
    internal init(config: DiskCacheConfiguration) {
        
        self.diskCacheEnabled = self.initializeCacheSettings(config: config)
        self.updateCurrentByteSizeForAllPolicies()
        
        #if DEBUG
        if let policy = self.cachePolicies.allPolicies().first {
            print("DiskCache root path: \(policy.cacheRootPath.path)")
        }
        #endif
    }
    
    //MARK: - Private API
    
    private let fileExtension = "dkc"
    private lazy var hasher = MD5Hash()
    private lazy var cachePolicies = CachePolicy()
    private var diskCacheEnabled = true
    private var activePolicyTrimming = Set<CachePolicyType>()
    private var cacheTrimConcurrentQueue = DispatchQueue(label: "DiskCache_CacheTrimQueue", qos: DispatchQoS.userInitiated, attributes: .concurrent)
    private var serialAccessQueue = DispatchQueue(label: "DiskCache_ActivePolicyQueue")
    
    private func getBytesUsed(forPolicy policy: CachePolicySetting) -> UInt64 {
        self.serialAccessQueue.sync {
            return policy.bytesUsed
        }
    }
    
    private func incrementBytesUsed(forPolicy policy: CachePolicySetting, bytes: UInt64) -> UInt64 {
        self.serialAccessQueue.sync {
            policy.bytesUsed += bytes
            return policy.bytesUsed
        }
    }
    
    private func decrementBytesUsed(forPolicy policy: CachePolicySetting, bytes: UInt64) -> UInt64 {
        self.serialAccessQueue.sync {
            let result = policy.bytesUsed - bytes
            policy.bytesUsed = max(0, result)
            return policy.bytesUsed
        }
    }
    
    private func isTrimmingPolicyType(_ policyType: CachePolicyType) -> Bool {
        self.serialAccessQueue.sync {
            return self.activePolicyTrimming.contains(policyType)
        }
    }
    
    private func insertTrimmingPolicyType(_ policyType: CachePolicyType) {
        self.serialAccessQueue.sync {
            _ = self.activePolicyTrimming.insert(policyType)
        }
    }

    private func removeTrimmingPolicyType(_ policyType: CachePolicyType) {
        self.serialAccessQueue.sync {
            _ = self.activePolicyTrimming.remove(policyType)
        }
    }

    private func initializeCacheSettings(config: DiskCacheConfiguration) -> Bool {
        var success = true
        for policySetting in self.cachePolicies.allPolicies() {
            policySetting.maxByteSize = config.policyMaxByteSize[policySetting.policyType] ?? 0
            success = self.createFolderForSetting(policySetting: policySetting)
            if (success == false) { break }
        }
        return success
    }
    
    private func createFolderForSetting(policySetting: CachePolicySetting) -> Bool {
        guard policySetting.policyType != .doNotCache else {
            return true
        }
        var pathCreated = true
        if (FileManager.pathExists(path: policySetting.cacheFolder) == false) {
            pathCreated = FileManager.createWithIntermediateDirectories(path: policySetting.cacheFolder)
        }
        return pathCreated
    }
    
    private func updateCurrentByteSizeForAllPolicies() {
        if (self.diskCacheEnabled) {
            for policySetting in self.cachePolicies.allPolicies() {
                var fileDiskBytesUsed: UInt64 = 0
                if let directoryContents = FileManager.contentsOfDirectory(path: policySetting.cacheFolder,
                                                                           withFileExtension: self.fileExtension)  {
                    for fileUrl in directoryContents {
                        if let fileAttributes = try? fileUrl.resourceValues(forKeys: [.fileSizeKey]) {
                            let fileSize = UInt64(fileAttributes.fileSize!)
                            fileDiskBytesUsed += fileSize
                        }
                    }
                }
                self.serialAccessQueue.sync {
                    policySetting.bytesUsed = fileDiskBytesUsed
                }
            }
        }
    }
    
    private func doesCachedItem(atPath filePath: URL, violateTTLFor policySetting: CachePolicySetting) -> Bool {
        var doesViolateTTL = false
        if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath.path) {
            let fileCreatedDate = attributes[FileAttributeKey.creationDate] as! Date
            let timeInterval = fileCreatedDate.timeIntervalSinceNow
            if (fabs(timeInterval) > TimeInterval(policySetting.ttlInSeconds)) {
                doesViolateTTL = true
                try? FileManager.default.removeItem(at: filePath)
            }
        }
        return doesViolateTTL
    }
    
    private func flushCacheFor(policySetting: CachePolicySetting) -> Bool {
        var success = false
        try? FileManager.default.removeItem(at: policySetting.cacheFolder)
        success = self.createFolderForSetting(policySetting: policySetting)
        return success
    }
    
    private func flushCache() -> Bool {
        var success = true
        for policySetting in self.cachePolicies.allPolicies() {
            success = self.flushCacheFor(policySetting: policySetting)
            if (!success) { break }
        }
        return success
    }
    
    private func key(forRequest request: NetworkRequest) -> String {
        var httpBody = ""
        if let bodyData = request.body {
            httpBody = String(data: bodyData, encoding: .utf8) ?? ""
        }
        let url = request.url.absoluteString
        let languageIdentifier = NSLocale.current.identifier
        let requestString = url + httpBody + languageIdentifier
        let requestKey = self.hasher.MD5(requestString)
        return requestKey
    }
    
    private func trimCache(forPolicy policy: CachePolicySetting) {
        self.cacheTrimConcurrentQueue.async { [weak self] in
            guard let strongSelf = self else { return }

            let targetBytes = UInt64(Double(policy.maxByteSize) * 0.75)
            if targetBytes > strongSelf.getBytesUsed(forPolicy: policy) || strongSelf.isTrimmingPolicyType(policy.policyType) {
                return
            }
           
            strongSelf.insertTrimmingPolicyType(policy.policyType)
            
            if let directoryContents = FileManager.contentsOfDirectory(path: policy.cacheFolder, withFileExtension: strongSelf.fileExtension) {
                //Sort oldest files first in the array.
                let sortedFilteredContents = try? directoryContents.sorted(by: { (lhs, rhs) -> Bool in
                    let lhsCreationDate = try lhs.resourceValues(forKeys: [.creationDateKey]).creationDate!
                    let rhsCreationDate = try rhs.resourceValues(forKeys: [.creationDateKey]).creationDate!
                    return lhsCreationDate < rhsCreationDate
                })
                
                //Remove files until we are within targetBytes
                if var sortedCache = sortedFilteredContents {
                    while (targetBytes < strongSelf.getBytesUsed(forPolicy: policy) && sortedCache.isEmpty == false) {
                        autoreleasepool {
                            let fileUrl = sortedCache.first
                            let fileAttributes = try? fileUrl!.resourceValues(forKeys: [.fileSizeKey])
                            let fileSize = UInt64(fileAttributes!.fileSize!)
                            try? FileManager.default.removeItem(at: fileUrl!)
                            _ = strongSelf.decrementBytesUsed(forPolicy: policy, bytes: fileSize)
                            sortedCache.removeFirst()
                        }
                    }
                }
            }
            strongSelf.removeTrimmingPolicyType(policy.policyType)
        }
    }
    
    //MARK: - Public API
    
    ///Returns the data for the request.
    internal func getCacheDataFor(request: NetworkRequest) -> Data? {
        guard self.diskCacheEnabled, request.cachePolicyType != CachePolicyType.doNotCache else { return nil }
        
        let policySetting = self.cachePolicies.policy(forType: request.cachePolicyType)
        let requestKey = self.key(forRequest: request)
        
        if (requestKey.isEmpty == false) {
            let fileName = requestKey + "." + self.fileExtension
            let cachePath = policySetting.cacheFolder.appendingPathComponent(fileName)
            if (FileManager.pathExists(path: cachePath) && self.doesCachedItem(atPath: cachePath, violateTTLFor: policySetting) == false) {
                let data = try? Data.init(contentsOf: cachePath)
                return data
            }
        }
        
        return nil
    }
    
    ///Stores the data on disk for the request using the specified cache policy
    internal func cache(data: Data, forRequest request: NetworkRequest) {
        guard self.diskCacheEnabled, data.isEmpty == false, request.cachePolicyType != CachePolicyType.doNotCache else { return }
        
        let policy = self.cachePolicies.policy(forType: request.cachePolicyType)
        let requestKey = self.key(forRequest: request)
        guard requestKey.isEmpty == false else { return }
        
        //Queue up trimming if not already in process for this cache policy type.
        if self.isTrimmingPolicyType(policy.policyType) == false {
            self.trimCache(forPolicy: policy)
        }
        
        //Save the data
        let fileName = requestKey + "." + self.fileExtension
        let cachePath = policy.cacheFolder.appendingPathComponent(fileName)
        if (FileManager.pathExists(path: policy.cacheFolder) == false) {
            let _ = FileManager.createWithIntermediateDirectories(path: policy.cacheFolder)
        }
        if (FileManager.pathExists(path: cachePath)) {
            try? FileManager.default.removeItem(at: cachePath)
        }
        FileManager.default.createFile(atPath: cachePath.path, contents: data, attributes: nil)
        
        //Update bytes used.
        let fileSize = UInt64(data.count)
        _ = self.incrementBytesUsed(forPolicy: policy, bytes: fileSize)
        //print("Cached \(fileSize) bytes  Total used \(self.bytesUsed) bytes for type \(policySetting.policyType.folderName)")
    }
    
    ///Clear the cache for a specific cache policy.
    internal func clearCache(policyType: CachePolicyType) {
        let policySetting = self.cachePolicies.policy(forType: policyType)
        let _ = self.flushCacheFor(policySetting: policySetting)
        self.updateCurrentByteSizeForAllPolicies()
    }
    
    ///Clear all cache from disk.
    internal func clearCache() {
        let _ = self.flushCache()
        self.updateCurrentByteSizeForAllPolicies()
    }
}

internal struct DiskCacheConfiguration {
    
    init(settings: [CachePolicyType: UInt64]) {
        self.policyMaxByteSize = settings
    }
    
    init() {
        self.policyMaxByteSize = [CachePolicyType.hour: 50331648,
                                  .fourHours: 104857600,
                                  .day: 262144000,
                                  .week: 524288000,
                                  .month: 1073741824,
                                  .untilSpaceNeeded: 1073741824]
    }
    
    let policyMaxByteSize: [CachePolicyType: UInt64]
}

public enum CachePolicyType: CaseIterable {
    case hour
    case fourHours
    case day
    case week
    case month
    case untilSpaceNeeded
    case doNotCache
    
    internal var ttlInSeconds: UInt32 {
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
    
    internal var folderName: String {
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
    
    internal var maxByteSize: UInt64 {
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

internal class CachePolicySetting {
    
    init(policyType: CachePolicyType) {
        let appName = ProcessInfo.processInfo.processName
        var cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.absoluteURL
        cachePath.appendPathComponent("HellfireDiskCache")
        cachePath.appendPathComponent(appName)
        self.cacheRootPath = cachePath
        self.policyType = policyType
        self.bytesUsed = 0
        self.maxByteSize = self.policyType.maxByteSize
        self.cacheFolder = cachePath.appendingPathComponent(self.policyType.folderName)
        self.ttlInSeconds = self.policyType.ttlInSeconds
        self.cachePolicy = self.policyType
    }
    
    let cacheRootPath: URL
    let policyType: CachePolicyType
    var bytesUsed: UInt64
    var maxByteSize: UInt64
    let cacheFolder: URL
    let ttlInSeconds: UInt32
    let cachePolicy: CachePolicyType
}

extension CachePolicySetting: Hashable {
    static func == (lhs: CachePolicySetting, rhs: CachePolicySetting) -> Bool {
        return lhs.policyType == rhs.policyType
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.policyType)
    }
}

internal class CachePolicy {
    
    private lazy var policies: [CachePolicySetting] = {
        return CachePolicyType.allCases.map { CachePolicySetting.init(policyType: $0) }
    }()
    
    func policy(forType policyType: CachePolicyType) -> CachePolicySetting {
        let setting = self.policies.first(where: { $0.policyType == policyType })
        //Force unwrap because we can guarantee the policy type is in the policies array.
        return setting!
    }
    
    func allPolicies() -> [CachePolicySetting] {
        return self.policies
    }
}
