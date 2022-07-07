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
    
    //MARK: - 2xx Success codes
    
    case ok = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    
    //MARK: - 3xx Redirection
    
    case multipleChoices = 300
    case moved = 301
    case found = 302
    case method = 303
    case notModified = 304
    case useProxy = 305
    case temporaryRedirect = 307
    
    //MARK: - 4xx Errors
    
    /// The server cannot or will not process the request due to an apparent client error (e.g., malformed request syntax, size too large, invalid request message framing,
    /// or deceptive request routing).
    case badRequest = 400

    /// Authentication is required and has failed or has not yet been provided.  The response must include a WWW-Authenticate header field containing
    /// a challenge applicable to the requested resource.
    case unauthorized = 401
    
    /// Reserved for future use. The original intention was that this code might be used as part of some form of digital cash or micropayment scheme.
    case paymentRequired = 402
    
    /// The request contained valid data and was understood by the server, but the server is refusing action. This may be due to the user not having the necessary permissions for a resource or needing an account of some sort, or attempting a prohibited action (e.g. creating a duplicate record where only one is allowed).
    case forbidden = 403
    
    /// The requested resource could not be found but may be available in the future. Subsequent requests by the client are permissible.
    case resourceNotFound = 404
    
    /// A request method is not supported for the requested resource; for example, a GET request on a form that requires data to be presented via POST,
    /// or a PUT request on a read-only resource.
    case methodNotAllowed = 405
    
    /// The requested resource is capable of generating only content not acceptable according to the Accept headers sent in the request.
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
    
    /// The request was well-formed but was unable to be followed due to semantic errors.
    case unprocessableEntity = 422
    
    /// The client should switch to a different protocol such as TLS/1.3, given in the Upgrade header field.
    case upgradeRequired = 426
    
    /// The user has sent too many requests in a given amount of time. Intended for use with rate-limiting schemes.
    case tooManyRequests = 429
    
    //MARK: - 5xx Errors
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
    
    //MARK: - Hellfire custom errors
    
    /// The request was successful, but the response was not able to be deserialized into the requested JSONSerializable object.
    ///
    /// Failure to deserialize might be a malformed response, or a malformed object definition (think miss-spelled, miss-cased, or just plain wrong) property definition.
    /// It can also be caused by non-optional properties in the model not having a corresponding value supplied by the server.
    case jsonDeserializationError = -50000
}

extension HTTPCode {
    
    ///Returns true if status code is in the range of 200...299.
    public static func isOk(_ statusCode: StatusCode) -> Bool {
        return (200...299 ~= statusCode)
    }
    
    ///Returns true when the status code == -999, which is the value of NSURLErrorCancelled defined in 'URL Loading System Error Codes'.
    internal static func wasRequestCancelled(statusCode: StatusCode) -> Bool  {
        return (statusCode == HellfireError.userCancelled)
    }
}
