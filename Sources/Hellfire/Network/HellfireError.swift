//
//  HellfireError.swift
//  Hellfire
//
//  Created by Ed Hellyer on 1/14/21.
//

import Foundation

public enum HellfireError: Error {
    /// The underlying reason the `.multipartEncodingFailed` error occurred.
    public enum MultipartEncodingFailureReason {
        /// The `fileURL` provided for reading an encodable body part isn't a file `URL`.
        case bodyPartURLInvalid(url: URL)
        /// The filename of the `fileURL` provided has either an empty `lastPathComponent` or `pathExtension.
        case bodyPartFilenameInvalid(in: URL)
        /// The file at the `fileURL` provided was not reachable.
        case bodyPartFileNotReachable(at: URL)
        /// Attempting to check the reachability of the `fileURL` provided threw an error.
        case bodyPartFileNotReachableWithError(atURL: URL, error: Error)
        /// The file at the `fileURL` provided is actually a directory.
        case bodyPartFileIsDirectory(at: URL)
        /// The size of the file at the `fileURL` provided was not returned by the system.
        case bodyPartFileSizeNotAvailable(at: URL)
        /// The attempt to find the size of the file at the `fileURL` provided threw an error.
        case bodyPartFileSizeQueryFailedWithError(forURL: URL, error: Error)
        /// An `InputStream` could not be created for the provided `fileURL`.
        case bodyPartInputStreamCreationFailed(for: URL)
        /// An `OutputStream` could not be created when attempting to write the encoded data to disk.
        case outputStreamCreationFailed(for: URL)
        /// The encoded body data could not be written to disk because a file already exists at the provided `fileURL`.
        case outputStreamFileAlreadyExists(at: URL)
        /// The `fileURL` provided for writing the encoded body data to disk is not a file `URL`.
        case outputStreamURLInvalid(url: URL)
        /// The attempt to write the encoded body data to disk failed with an underlying error.
        case outputStreamWriteFailed(error: Error)
        /// The attempt to read an encoded body part `InputStream` failed with underlying system error.
        case inputStreamReadFailed(error: Error)
    }
    
    /// The URLSessionTask was unable to be created.  Specific reasons, if known, will be in the ServiceError response.
    public enum ServiceRequestError: Error {
        case unableToCreateTask(result: RequestResult)
    }
    
    /// Multipart form encoding failed.
    case multipartEncodingFailed(reason: MultipartEncodingFailureReason)
    
    /// An asynchronous load has been canceled.
    public static let userCancelled = URLError.cancelled.rawValue
    
    /// An asynchronous operation timed out.
    ///
    /// A URL session sends this error to its delegate when the timeoutInterval of a request expires before a load can complete.
    public static let timedOut = URLError.timedOut.rawValue

    /// An attempt to establish a secure connection failed for reasons that can’t be expressed more specifically.
    public static let secureConnectionFailed = URLError.secureConnectionFailed.rawValue
    
    /// The host name for a URL couldn’t be resolved.
    public static let cannotFindHost = URLError.cannotFindHost.rawValue
}
