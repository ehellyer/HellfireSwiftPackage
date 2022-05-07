//
//  HellfireError.swift
//  Hellfire
//
//  Created by Ed Hellyer on 1/14/21.
//

import Foundation

public enum HellfireError: Error {
    
    /// General error occured.
    case generalError
    
    /// Multipart form encoding failed.
    case multipartEncodingFailed(reason: MultipartEncodingFailureReason)
    
    /// The underlying reason the `.multipartEncodingFailed` error occurred.
    public enum MultipartEncodingFailureReason {
        /// The `fileURL` provided for reading an encodable form part isn't a file `URL`.
        case formPartURLInvalid(url: URL)
        /// The filename of the `fileURL` provided has either an empty `lastPathComponent` or `pathExtension.
        case formPartFilenameInvalid(url: URL)
        /// The file at the `fileURL` provided was not reachable.
        case formPartFileNotReachable(url: URL)
        /// Attempting to check the reachability of the `fileURL` provided threw an error.
        case formPartFileNotReachableWithError(url: URL, error: Error)
        /// The file at the `fileURL` provided is actually a directory.
        case formPartFileIsDirectory(url: URL)
        /// The size of the file at the `fileURL` provided was not returned by the system.
        case formPartFileSizeNotAvailable(url: URL)
        /// The attempt to find the size of the file at the `fileURL` provided threw an error.
        case formPartFileSizeQueryFailedWithError(url: URL, error: Error)
        /// An `InputStream` could not be created for the provided `fileURL`.
        case formPartInputStreamCreationFailed(url: URL)
        /// An `OutputStream` could not be created when attempting to write the encoded data to disk.
        case outputStreamCreationFailed(url: URL)
        /// The encoded body data could not be written to disk because a file already exists at the provided `fileURL`.
        case outputStreamFileAlreadyExists(url: URL)
        /// The `fileURL` provided for writing the encoded body data to disk is not a file `URL`.
        case outputStreamURLInvalid(url: URL)
        /// The attempt to write the encoded body data to disk failed with an underlying error.
        case outputStreamWriteFailed(error: Error)
        /// The attempt to read an encoded form part `InputStream` failed with underlying system error.
        case inputStreamReadFailed(error: Error)
    }
    
    public enum JSONSerializableError: Error {
        /// No data in the response to create an instance from.
        case zeroLengthResponseFromServer
        
        /// Inappropriate JSONSerializable initializer for an array.
        case inappropriateInit(message: String)

        public enum encodingError: Error {
            case invalidValue(message: String)
            case exception(message: String)
        }
        
        public enum decodingError: Error {
            case keyNotFound(message: String)
            case typeMismatch(message: String)
            case valueNotFound(message: String)
            case dataCorrupted(message: String)
            case exception(message: String)
        }
    }
    
    /// The URLSessionTask was unable to be created.  Specific reasons, if known, will be in the ServiceError response.
    public enum ServiceRequestError: Error {
        case unableToCreateTask(result: DataResult)
    }
    
    /// An asynchronous task has been canceled.
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
