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
    
    //MARK: - 1xx Success codes
    
    
    
    //MARK: - 2xx Success codes
    
    /// The HTTP 200 OK success status response code indicates that the request has succeeded. A 200 response is cacheable by default.
    ///
    /// The meaning of a success depends on the HTTP request method:
    /// - GET: The resource has been fetched and is transmitted in the message body.
    /// - HEAD: The representation headers are included in the response without any message body
    /// - POST: The resource describing the result of the action is transmitted in the message body
    ///  - TRACE: The message body contains the request message as received by the server.
    ///
    ///  The successful result of a PUT or a DELETE is often not a 200 OK but a 204 No Content (or a 201 Created when the resource is uploaded for the first time).
    case ok = 200
    
    /// The HTTP 201 Created success status response code indicates that the request has succeeded and has led to the creation of a resource. 
    ///
    /// The new resource, or a description and link to the new resource, is effectively created before the response is sent back and the newly created items are returned in the body of the message, located at either the URL of the request, or at the URL in the value of the Location header.
    /// The common use case of this status code is as the result of a POST request.
    case created = 201
    
    /// The HyperText Transfer Protocol (HTTP) 202 Accepted response status code indicates that the request has been accepted for processing, but the processing has not been completed; in fact, processing may not have started yet. The request might or might not eventually be acted upon, as it might be disallowed when processing actually takes place.
    /// 202 is non-committal, meaning that there is no way for the HTTP to later send an asynchronous response indicating the outcome of processing the request. It is intended for cases where another process or server handles the request, or for batch processing.
    case accepted = 202
    
    /// The HTTP 203 Non-Authoritative Information response status indicates that the request was successful but the enclosed payload has been modified by a transforming proxy from that of the origin server's 200 (OK) response.
    /// The 203 response is similar to the value 214, meaning Transformation Applied, of the Warning header code, which has the additional advantage of being applicable to responses with any status code.
    case nonAuthoritativeInformation = 203
    
    /// The HTTP 204 No Content success status response code indicates that a request has succeeded, but that the client doesn't need to navigate away from its current page.
    ///
    /// This might be used, for example, when implementing "save and continue editing" functionality for a wiki site. In this case a PUT request would be used to save the page, and the 204 No Content response would be sent to indicate that the editor should not be replaced by some other page.
    /// A 204 response is cacheable by default (an ETag header is included in such a response).
    case noContent = 204
    
    /// The HTTP 205 Reset Content response status tells the client to reset the document view, so for example to clear the content of a form, reset a canvas state, or to refresh the UI.
    case resetContent = 205
    
    /// The HTTP 206 Partial Content success status response code indicates that the request has succeeded and the body contains the requested ranges of data, as described in the Range header of the request.
    /// If there is only one range, the Content-Type of the whole response is set to the type of the document, and a Content-Range is provided.
    /// If several ranges are sent back, the Content-Type is set to multipart/byte ranges and each fragment covers one range, with Content-Range and Content-Type describing it.
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
}

//MARK: - HTTPCode extension
extension HTTPCode {
        
    /// Returns true if `StatusCode` is in the range of 200...299.
    public static func isOk(_ statusCode: StatusCode?) -> Bool {
        return (200...299 ~= statusCode ?? -666) 
    }
}
