//
//  HTTPCode.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation
import CoreFoundation

public typealias StatusCode = Int

/// Common HTTP codes
public enum HTTPCode: StatusCode, JSONSerializable {
    //2xx Success codes
    case ok = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    
    //3xx Redirection
    case multipleChoices = 300
    case moved = 301
    case found = 302
    case method = 303
    case notModified = 304
    case useProxy = 305
    case temporaryRedirect = 307
    
    //4xx Errors
    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case resourceNotFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionRequired = 412
    
    /// I'm a teapot client error response code indicates that the server refuses to brew coffee because it is, permanently, a teapot.
    ///
    /// The sprit of this code can be used to indicate the server does not support this kind of request.
    ///
    /// __See Also__
    ///
    /// [I'm a teapot](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/418)
    case imaTeapot = 418
    case upgradeRequired = 426
    case tooManyRequests = 429
    
    //5xx Errors
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
}

extension HTTPCode {

    ///Returns true if status code is in the range of 200...299.
    public static func isOk(_ statusCode: StatusCode) -> Bool {
        return (200...299 ~= statusCode)
    }
    
    ///Returns true when the status code == -999, which is the value of NSURLErrorCancelled defined in 'URL Loading System Error Codes'.
    internal static func wasRequestCancelled(statusCode: StatusCode) -> Bool  {
        return (statusCode == NSURLErrorCancelled)
    }
}
