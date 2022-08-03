//
//  HellfireError+CustomStringConvertable.swift
//  Hellfire
//
//  Created by Ed Hellyer on 5/4/22.
//

import Foundation

extension HellfireError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .generalError:
            return "A general error occurred."
        case .multipartEncodingFailed(let reason):
            switch reason {
            case .formPartURLInvalid(let url):
                return "The URL provided is not a file URL: \(url)"
            case .formPartFilenameInvalid(let url):
                return "The URL provided does not have a valid filename: \(url)"
            case .formPartFileNotReachable(let url):
                return "The URL provided is not reachable: \(url)"
            case .formPartFileNotReachableWithError(let url, let error):
                return """
                The system returned an error while checking the provided URL for reachability.
                URL: \(url)
                Error: \(error)
                """
            case .formPartFileIsDirectory(let url):
                return "The URL provided is a directory: \(url)"
            case .formPartFileSizeNotAvailable(let url):
                return "Could not fetch the file size from the provided URL: \(url)"
            case .formPartFileSizeQueryFailedWithError(let url, let error):
                return """
                The system returned an error while attempting to fetch the file size from the provided URL.
                URL: \(url)
                Error: \(error)
                """
            case .formPartInputStreamCreationFailed(let url):
                return "Failed to create an InputStream for the provided URL: \(url)"
            case .outputStreamCreationFailed(let url):
                return "Failed to create an OutputStream for URL: \(url)"
            case .outputStreamFileAlreadyExists(let url):
                return "A file already exists at the provided URL: \(url)"
            case .outputStreamURLInvalid(let url):
                return "The provided OutputStream URL is invalid: \(url)"
            case .outputStreamWriteFailed(let error):
                return "OutputStream write failed with error: \(error)"
            case .inputStreamReadFailed(let error):
                return "InputStream read failed with error: \(error)"
            }
        }
    }
}
