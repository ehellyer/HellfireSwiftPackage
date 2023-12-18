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
        let appName = ProcessInfo.processInfo.processName
        var cachePath = FileManager.default.urls(for: .cachesDirectory,
                                                 in: .userDomainMask).first!.absoluteURL
        cachePath.appendPathComponent("HellfireDiskCache")
        cachePath.appendPathComponent(appName)
        self.cacheRootPath = cachePath
        self.diskCacheEnabled = self.initializeCacheSettings(config: config)
        self.updateCurrentByteSizeForAllPolicies()
        
        #if DEBUG
        print("DiskCache root path: \(self.cacheRootPath.path)")
        #endif
    }
    
    //MARK: - Private API
    
    private let fileExtension = "dkc"
    private lazy var hasher = MD5Hash()
    private var cacheRootPath: URL
    private lazy var cachePolicies = CachePolicies(cacheRootPath: self.cacheRootPath)
    private var diskCacheEnabled = true
    private var activePolicyTrimming = Set<CachePolicyType>()
    private var cacheTrimConcurrentQueue = DispatchQueue(label: "DiskCache_ConcurrentTrimCacheQueue",
                                                         qos: DispatchQoS.userInitiated, attributes: .concurrent)
    private var serialAccessQueue = DispatchQueue(label: "DiskCache_SerialAccessQueue")
    
    private func getBytesUsed(forPolicy policy: CachePolicy) -> UInt64 {
        self.serialAccessQueue.sync {
            return policy.bytesUsed
        }
    }
    
    private func incrementBytesUsed(forPolicy policy: CachePolicy, bytes: UInt64) -> UInt64 {
        self.serialAccessQueue.sync {
            policy.bytesUsed += bytes
            return policy.bytesUsed
        }
    }
    
    private func decrementBytesUsed(forPolicy policy: CachePolicy, bytes: UInt64) -> UInt64 {
        self.serialAccessQueue.sync {
            let result = policy.bytesUsed - bytes
            policy.bytesUsed = max(0, result)
            return policy.bytesUsed
        }
    }
    
    private func setBytesUsed(_ bytes: UInt64, forPolicy policy: CachePolicy) {
        self.serialAccessQueue.sync {
            policy.bytesUsed = bytes
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
        for policy in self.cachePolicies.allPolicies() {
            policy.maxByteSize = config.policyMaxByteSize[policy.policyType] ?? 0
            success = self.createFolder(forPolicy: policy)
            if (success == false) { break }
        }
        return success
    }
    
    private func createFolder(forPolicy policy: CachePolicy) -> Bool {
        guard policy.policyType != .doNotCache else {
            return true
        }
        var pathCreated = true
        if (FileManager.pathExists(path: policy.cacheFolder) == false) {
            pathCreated = FileManager.createWithIntermediateDirectories(path: policy.cacheFolder)
        }
        return pathCreated
    }
    
    private func updateCurrentByteSizeForAllPolicies() {
        guard  self.diskCacheEnabled else { return }
        for policy in self.cachePolicies.allPolicies() {
            var fileDiskBytesUsed: UInt64 = 0
            if let directoryContents = FileManager.contentsOfDirectory(path: policy.cacheFolder,
                                                                       withFileExtension: self.fileExtension)  {
                for fileUrl in directoryContents {
                    if let fileAttributes = try? fileUrl.resourceValues(forKeys: [.fileSizeKey]),
                       let fileSize = fileAttributes.fileSize {
                        let fileSizeU64 = UInt64(fileSize)
                        fileDiskBytesUsed += fileSizeU64
                    }
                }
            }
            self.setBytesUsed(fileDiskBytesUsed, forPolicy: policy)
        }
    }
    
    private func doesCachedItem(atPath filePath: URL, violateTTLFor policy: CachePolicy) -> Bool {
        var doesViolateTTL = false
        if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath.path),
           let fileCreatedDate = attributes[FileAttributeKey.creationDate] as? Date {
            let timeInterval = fileCreatedDate.timeIntervalSinceNow
            if (fabs(timeInterval) > TimeInterval(policy.ttlInSeconds)) {
                doesViolateTTL = true
                try? FileManager.default.removeItem(at: filePath)
            }
        }
        return doesViolateTTL
    }
    
    private func flushCacheFor(policy: CachePolicy) -> Bool {
        var success = false
        try? FileManager.default.removeItem(at: policy.cacheFolder)
        success = self.createFolder(forPolicy: policy)
        return success
    }
    
    private func flushCache() -> Bool {
        var success = true
        for policy in self.cachePolicies.allPolicies() {
            success = self.flushCacheFor(policy: policy)
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
    
    private func trimCache(forPolicy policy: CachePolicy) {
        self.cacheTrimConcurrentQueue.async { [weak self] in
            guard let self else { return }
            
            let targetBytes = UInt64(Double(policy.maxByteSize) * 0.75)
            if targetBytes > self.getBytesUsed(forPolicy: policy) || self.isTrimmingPolicyType(policy.policyType) {
                return
            }
            
            self.insertTrimmingPolicyType(policy.policyType)
            
            if let directoryContents = FileManager.contentsOfDirectory(path: policy.cacheFolder,
                                                                       withFileExtension: self.fileExtension) {
                //Sort oldest files first in the array.
                var sortedDirectoryContents: [URL] = (
                    try? directoryContents.sorted(by: { (lhs, rhs) -> Bool in
                        let lhsCreationDate = try lhs.resourceValues(forKeys: [.creationDateKey]).creationDate
                        let rhsCreationDate = try rhs.resourceValues(forKeys: [.creationDateKey]).creationDate
                        return self.isDate(lhsCreationDate, before: rhsCreationDate)
                    })
                ) ?? []
                
                //Remove files until we are within targetBytes
                while sortedDirectoryContents.isEmpty == false && (targetBytes < self.getBytesUsed(forPolicy: policy)) {
                    autoreleasepool {
                        if let fileUrl = sortedDirectoryContents.first,
                           let fileAttributes = try? fileUrl.resourceValues(forKeys: [.fileSizeKey]),
                           let fileSize = fileAttributes.fileSize {
                            let fileSizeU64 = UInt64(fileSize)
                            try? FileManager.default.removeItem(at: fileUrl)
                            _ = self.decrementBytesUsed(forPolicy: policy, bytes: fileSizeU64)
                        }
                        sortedDirectoryContents.removeFirst()
                    }
                }
            }
            self.removeTrimmingPolicyType(policy.policyType)
        }
    }
    
    private func isDate(_ lhs: Date?, before rhs: Date?) -> Bool {
        guard let lhs, let rhs else { return true }
        return lhs < rhs
    }
    
    //MARK: - Internal API
    
    /// Returns the data for the request.
    internal func getCacheDataFor(request: NetworkRequest) -> Data? {
        guard self.diskCacheEnabled, request.cachePolicyType != CachePolicyType.doNotCache else { return nil }
        
        let policy = self.cachePolicies.policy(forType: request.cachePolicyType)
        let requestKey = self.key(forRequest: request)
        guard requestKey.isEmpty == false else { return nil }
        
        let fileName = requestKey + "." + self.fileExtension
        let cachePath = policy.cacheFolder.appendingPathComponent(fileName)
        var data: Data? = nil
        if (FileManager.pathExists(path: cachePath) && self.doesCachedItem(atPath: cachePath, violateTTLFor: policy) == false) {
            data = try? Data.init(contentsOf: cachePath)
        }
        return data
    }
    
    /// Stores the data on disk for the request using the specified cache policy
    /// - Parameters:
    ///   - data: The data to be cached on disk.  If nil, this function does nothing and returns early.
    ///   - request: The network request that requested the data to be cached.  The requests cache policy effect how the caching works.  If the cache policy is do not cache, then this function returns early.
    internal func cache(data: Data?,
                        forRequest request: NetworkRequest) {
        
        guard self.diskCacheEnabled,
              let data,
              data.isEmpty == false,
              request.cachePolicyType != CachePolicyType.doNotCache else {
            return
        }
        
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
    }
    
    /// Clear the cache for a specific cache policy.
    internal func clearCache(policyType: CachePolicyType) {
        let policy = self.cachePolicies.policy(forType: policyType)
        let _ = self.flushCacheFor(policy: policy)
        self.updateCurrentByteSizeForAllPolicies()
    }
    
    /// Clear all cache from disk.
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
}

internal class CachePolicy {
    
    init(policyType: CachePolicyType, cacheRootPath: URL) {
        self.policyType = policyType
        self.bytesUsed = 0
        self.maxByteSize = 0 //Configured later
        self.cacheFolder = cacheRootPath.appendingPathComponent(self.policyType.folderName)
        self.ttlInSeconds = self.policyType.ttlInSeconds
    }
    
    let policyType: CachePolicyType
    var bytesUsed: UInt64
    var maxByteSize: UInt64
    let cacheFolder: URL
    let ttlInSeconds: UInt32
}

extension CachePolicy: Hashable {
    static func == (lhs: CachePolicy, rhs: CachePolicy) -> Bool {
        return lhs.policyType == rhs.policyType
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.policyType)
    }
}

internal class CachePolicies {
    
    init(cacheRootPath: URL) {
        self.policies = CachePolicyType.allCases.reduce(into: [CachePolicyType: CachePolicy]()) {
            $0[$1] = CachePolicy.init(policyType: $1, cacheRootPath: cacheRootPath)
        }
    }
    
    private var policies: [CachePolicyType: CachePolicy]
    
    func policy(forType policyType: CachePolicyType) -> CachePolicy {
        let setting = self.policies[policyType]
        return setting!
    }
    
    func allPolicies() -> [CachePolicy] {
        return Array(self.policies.values)
    }
}
