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
    
    init() {
        self.diskCacheEnabled = self.initializeCacheSettings()
        self.updateCurrentByteSizeForAllPolicies()
        
        #if DEBUG
        if let policy = self.cachePolicies.allPolicies().first {
            print("DiskCache root path: \(policy.rootPath.path)")
        }
        #endif
    }
    
    //MARK: - Private API

    private let fileExtension = "dkc"
    private lazy var hasher = MD5Hash()
    private lazy var cachePolicies = CachePolicy()
    private var diskCacheEnabled = true
    private var cacheTrimQueue = Set<String>.init()
    private var queue = DispatchQueue(label: "DiskCache_CacheTrimQueue", qos: DispatchQoS.userInitiated, attributes: .concurrent)
    
    private func initializeCacheSettings() -> Bool {
        var success = true
        for policySetting in self.cachePolicies.allPolicies() {
            success = self.createFolderForSetting(policySetting: policySetting)
            if (success == false) { break }
        }
        return success
    }

    private func createFolderForSetting(policySetting: CachePolicySetting) -> Bool {
        var pathCreated = true
        if (FileManager.pathExists(path: policySetting.folderURL) == false) {
            pathCreated = FileManager.createWithIntermediateDirectories(path: policySetting.folderURL)
        }
        return pathCreated
    }

    private func updateCurrentByteSizeForAllPolicies() {
        if (self.diskCacheEnabled) {
            for policySetting in self.cachePolicies.allPolicies() {
                self.updateCurrentByteSize(forPolicySetting: policySetting)
            }
        }
    }

    private func updateCurrentByteSize(forPolicySetting policySetting: CachePolicySetting) {
        var fileDiskBytesUsed: UInt64 = 0

        if let directoryContents = FileManager.contentsOfDirectory(path: policySetting.folderURL, withFileExtension: self.fileExtension)  {
            for fileUrl in directoryContents {
                if let fileAttributes = try? fileUrl.resourceValues(forKeys: [.fileSizeKey]) {
                    let fileSize = UInt64(fileAttributes.fileSize!)
                    fileDiskBytesUsed += fileSize
                }
            }
        }
        policySetting.bytesUsed = fileDiskBytesUsed
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
        try? FileManager.default.removeItem(at: policySetting.folderURL)
        success = self.createFolderForSetting(policySetting: policySetting)
        if (success) {
            policySetting.bytesUsed = 0
        }
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
            httpBody = String.init(data: bodyData, encoding: String.Encoding.utf8) ?? ""
        }
        let url = request.url.absoluteString
        let languageIdentifier = NSLocale.current.identifier
        let requestString = url + httpBody + languageIdentifier
        let requestKey = self.hasher.MD5(requestString)
        return requestKey
    }
    
    private func trimCache(forPolicySetting policySetting: CachePolicySetting) {
        self.queue.async { [weak self] in
            guard let strongSelf = self else { return }
            let targetBytes = UInt64(Double(policySetting.maxByteSize) * 0.75)
            
            if (strongSelf.cacheTrimQueue.contains(policySetting.typeName)) { return }
            
            if (targetBytes > policySetting.bytesUsed) { return }
            
            strongSelf.cacheTrimQueue.insert(policySetting.typeName)
            
            if let directoryContents = FileManager.contentsOfDirectory(path: policySetting.folderURL, withFileExtension: strongSelf.fileExtension) {
                
                //Sort oldest files first in the array.
                let sortedFilteredContents = try? directoryContents.sorted(by: { (lhs, rhs) -> Bool in
                    let lhsfileAttributes = try lhs.resourceValues(forKeys: [.creationDateKey])
                    let rhsfileAttributes = try rhs.resourceValues(forKeys: [.creationDateKey])
                    let lhsCreationDate = lhsfileAttributes.creationDate!
                    let rhsCreationDate = rhsfileAttributes.creationDate!
                
                    return lhsCreationDate < rhsCreationDate
                })
                
                //Remove files until we are within targetBytes
                if var sortedCache = sortedFilteredContents {
                    while (targetBytes < policySetting.bytesUsed && sortedCache.count > 0) {
                        let fileUrl = sortedCache.first
                        let fileAttributes = try? fileUrl!.resourceValues(forKeys: [.fileSizeKey])
                        let fileSize = fileAttributes!.fileSize!
                        try? FileManager.default.removeItem(at: fileUrl!)
                        let result = Int64(policySetting.bytesUsed) - Int64(fileSize)
                        policySetting.bytesUsed = UInt64(max(0, result))
                        sortedCache.removeFirst()
                    }
                }
            }
         strongSelf.cacheTrimQueue.remove(policySetting.typeName)
        }
    }
    
    //MARK: - Public API
    
    ///Returns the data for the request.
    internal func getCacheDataFor(request: NetworkRequest) -> Data? {
        let policySetting = self.cachePolicies.policy(forType: request.cachePolicyType)
        let requestKey = self.key(forRequest: request)
        
        if (self.diskCacheEnabled && policySetting.typeName != CachePolicyType.doNotCache.typeName && requestKey.count > 0) {
            let fileName = requestKey + "." + self.fileExtension
            let cachePath = policySetting.folderURL.appendingPathComponent(fileName)
            if (FileManager.pathExists(path: cachePath) && self.doesCachedItem(atPath: cachePath, violateTTLFor: policySetting) == false) {
                let data = try? Data.init(contentsOf: cachePath)
                return data
            }
        }
        
        return nil
    }
    
    ///Stores the data on disk for the request using the specified cache policy
    internal func cache(data: Data, forRequest request: NetworkRequest) {
        let policySetting = self.cachePolicies.policy(forType: request.cachePolicyType)
        if (data.count < 3) { return }
        let requestKey = self.key(forRequest: request)
        
        if (self.diskCacheEnabled && policySetting.typeName != CachePolicyType.doNotCache.typeName && requestKey.count > 0) {

            //Queue up trimming if not already in process for this cache policy type.
            if (self.cacheTrimQueue.contains(policySetting.typeName) == false) {
                self.trimCache(forPolicySetting: policySetting)
            }

            //Save the data
            let fileName = requestKey + "." + self.fileExtension
            let cachePath = policySetting.folderURL.appendingPathComponent(fileName)
            if (FileManager.pathExists(path: policySetting.folderURL) == false) {
                let _ = FileManager.createWithIntermediateDirectories(path: policySetting.folderURL)
            }
            if (FileManager.pathExists(path: cachePath)) {
                try? FileManager.default.removeItem(at: cachePath)
            }
            FileManager.default.createFile(atPath: cachePath.path, contents: data, attributes: nil)

            //Update bytes used.
            let fileSize = UInt64(data.count)
            let currentSize = policySetting.bytesUsed
            policySetting.bytesUsed = fileSize + currentSize
        }
    }
    
    ///Clear the cache for a specific cache policy.
    internal func clearCache(policyType: CachePolicyType) {
        let policySetting = self.cachePolicies.policy(forType: policyType)
        let _ = self.flushCacheFor(policySetting: policySetting)
    }
    
    ///Clear all cache from disk.
    internal func clearCache() {
        let _ = self.flushCache()
    }
}
