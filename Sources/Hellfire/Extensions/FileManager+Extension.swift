//
//  FileManager+Extension.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

internal extension FileManager {
    
    ///Creates the directory path tree, returns true for success and false for failure.
    class func createWithIntermediateDirectories(path: URL) -> Bool {
        var pathCreated = true
        do {
            try FileManager.default.createDirectory(atPath: path.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            #if DEBUG
            print("Something went wrong while creating a new folder")
            print("Directory Creation Error: " + error.localizedDescription)
            #endif
            pathCreated = false
        }
        return pathCreated
    }
    
    ///Returns true if the directory or file specified by the url exists else returns false.
    class func pathExists(path: URL) -> Bool {
        var isPathValid = false
        isPathValid = FileManager.default.fileExists(atPath: path.path)
        return isPathValid
    }
    
    ///Returns the contents of the specified directory, will ignore hidden files, sub directories and package contents.  Response includes .fileSizeKey and .createdDate properties.
    class func contentsOfDirectory(path: URL, withFileExtension fileExtension: String = "") -> [URL]? {
        var filteredContents: [URL]? = nil
        let propertyKeys: [URLResourceKey] = [.creationDateKey,
                                              .fileSizeKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsSubdirectoryDescendants,
                                                                .skipsHiddenFiles,
                                                                .skipsPackageDescendants]
        let directoryContents = try? FileManager.default.contentsOfDirectory(at: path,
                                                                             includingPropertiesForKeys: propertyKeys,
                                                                             options: options)
        filteredContents = fileExtension.isEmpty ? directoryContents : directoryContents?.filter { $0.pathExtension == fileExtension }
        return filteredContents
    }
}
