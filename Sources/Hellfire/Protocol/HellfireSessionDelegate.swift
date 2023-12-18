//
//  HellfireSessionDelegate.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

/// A protocol this is implemented optionally by the `SessionInterface` delegate.
public protocol HellfireSessionDelegate: AnyObject {
    
    /// Asks delegate to return all the additional headers required for the `NetworkRequest`
    /// - Note: Duplicate headers returned in this call will override those that were set by the `SessionInterface` based on the `NetworkRequest` parameters and defaults.
    /// - Parameter dataRequest: The `NetworkRequest` that initiated this delegate call.
    func headerCollection(forRequest request: NetworkRequest) -> [HTTPHeader]?
    
    /// A  optional global way of telling the delegate the returned response headers for a given request.
    /// - Note: Response headers are also included in the `NetworkResponse` of a successful `NetworkRequest`
    /// - Parameters:
    ///   - headers: An array of headers returned in the response.
    ///   - forRequest: The `NetworkRequest` that initiated this response.
    func responseHeaders(headers: [HTTPHeader],
                         forRequest request: NetworkRequest)
    
    /// Tells the URL session that the session has been invalidated.
    ///
    ///  If you invalidate a session by calling its [finishTasksAndInvalidate()](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2Furlsession%2F1407428-finishtasksandinvalidate) method, the session waits until after the final task in the session finishes or fails before calling this delegate method. If you call the [invalidateAndCancel()](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2Furlsession%2F1411538-invalidateandcancel) method, the session calls this delegate method immediately.
    /// - Parameters:
    ///   - session: The session object that was invalidated.
    ///   - error: The error that caused invalidation, or nil if the invalidation was explicit.
    func session(_ session: URLSession,
                 didBecomeInvalidWithError error: Error?)
    
    /// Tells the delegate that the data task has received some of the expected data.
    ///
    /// Because the data object parameter is often pieced together from a number of different data objects, whenever possible, use the enumerateBytes(_:) method to iterate through the data rather than using the bytes method (which flattens the data object into a single memory block).
    ///
    /// This delegate method may be called more than once, and each call provides only data received since the previous call. The app is responsible for accumulating this data if needed.
    /// - Parameters:
    ///   - session: The session containing the data task that provided data.
    ///   - dataTask: The data task that provided data.
    ///   - data: A data object containing the transferred data.
    func session(_ session: URLSession,
                 dataTask: URLSessionDataTask,
                 didReceive data: Data)
    
    /// Tells the delegate that the background `URLSessionUploadTask` finished transferring data in the background.
    /// - Parameter result: Represents the success or failure result of a `NetworkRequest`.
    
    
    /// Tells the delegate that the background `URLSessionUploadTask` finished transferring data in the background.
    /// - Parameters:
    ///   - task: URLSessionTask for this response.
    ///   - requestTaskIdentifier: Unique task identifier for the URLSessionTask.
    ///   - result: Represents the success or failure result of a `NetworkRequest`.
    func backgroundTask(_ task: URLSessionTask,
                        didCompleteWithResult result: DataResult)
    
    /// Sent periodically to notify the delegate of upload progress.  This information is also available as properties of the task.
    /// - Parameters:
    ///   - task: URLSessionTask for this response.
    ///   - bytesSent: Number of bytes sent since the last time this delegate was called.
    ///   - totalBytesSent: The total number of bytes sent so far.
    ///   - totalBytesExpectedToSend: The expected length of the body data. The URL loading system can determine the length of the upload data in three ways:
    ///     * From the length of the NSData object provided as the upload body.
    ///     * From the length of the file on disk provided as the upload body of an upload task (not a download task).
    ///     * From the Content-Length in the request object, if you explicitly set it.
    ///
    ///     Otherwise, the value is [NSURLSessionTransferSizeUnknown](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2Fnsurlsessiontransfersizeunknown) (-1) if you provided a stream or body data object, or zero (0) if you did not.
    func backgroundTask(_ task: URLSessionTask,
                        didSendBytes bytesSent: Int64,
                        totalBytesSent: Int64,
                        totalBytesExpectedToSend: Int64)
    
    /// Requests credentials from the delegate in response to a session-level authentication request from the remote server.
    ///
    /// This method is called in two situations:
    /// * When a remote server asks for client certificates or Windows NT LAN Manager (NTLM) authentication, to allow your app to provide appropriate credentials
    /// * When a session first establishes a connection to a remote server that uses SSL or TLS, to allow your app to verify the server’s certificate chain
    ///
    /// If you do not implement this method, the session calls its delegate’s urlSession(_:task:didReceive:completionHandler:) method instead.
    ///
    /// - Note:
    ///   This method handles only the NSURLAuthenticationMethodNTLM, NSURLAuthenticationMethodNegotiate, NSURLAuthenticationMethodClientCertificate, and NSURLAuthenticationMethodServerTrust authentication types. For all other authentication schemes, the session calls only the urlSession(_:task:didReceive:completionHandler:) method.
    
    /// - Parameters:
    ///   - session: The session containing the task that requested authentication.
    ///   - challenge: An object that contains the request for authentication.
    ///   - completionHandler: A handler that your delegate method must call. This completion handler takes the following parameters:
    ///   * disposition - One of several constants that describes how the challenge should be handled.
    ///   * credential - The credential that should be used for authentication if disposition is NSURLSessionAuthChallengeUseCredential, otherwise NULL.
    func session(_ session: URLSession,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    
    //Handles task specific challenges.  e.g. Username/Password
    func session(_ session: URLSession,
                    task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    
    /// Tells the delegate that all messages enqueued for a session have been delivered.
    ///
    /// In iOS, when a background transfer completes or requires credentials, if your app is no longer running, your app is automatically relaunched in the background, and the app’s UIApplicationDelegate is sent an application(_:handleEventsForBackgroundURLSession:completionHandler:) message.
    /// This call contains the identifier of the session that caused your app to be launched. You should then store that completion handler before creating a background configuration object with the same identifier, and creating a session with that configuration.
    /// The newly created session is automatically associated with ongoing background activity.
    ///
    /// When your app later receives a urlSessionDidFinishEvents(forBackgroundURLSession:) message, this indicates that all messages previously enqueued for this session have been delivered, and that it is now safe to invoke the previously stored completion handler or to begin any internal updates that may result in invoking the completion handler.
    ///
    /// - Parameter session: The session that no longer has any outstanding requests.
    func backgroundSessionDidFinishEvents(session: URLSession)
}

// Protocol extension that enables default action for protocol implementation when the delegate does not implement them.
public extension HellfireSessionDelegate {
    
    func headerCollection(forRequest request: NetworkRequest) -> [HTTPHeader]? {
        return nil
    }
    
    func responseHeaders(headers: [HTTPHeader],
                         forRequest request: NetworkRequest) { }
    
    func session(_ session: URLSession,
                 didBecomeInvalidWithError error: Error?) { }
    
    func session(_ session: URLSession,
                 dataTask: URLSessionDataTask,
                 didReceive data: Data) { }
    
    func backgroundTask(_ task: URLSessionTask,
                        didCompleteWithResult result: DataResult) { }
    
    func backgroundTask(_ task: URLSessionTask,
                        didSendBytes bytesSent: Int64,
                        totalBytesSent: Int64,
                        totalBytesExpectedToSend: Int64) { }

    func session(_ session: URLSession,
                 task: URLSessionTask,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.previousFailureCount > 0 {
            completionHandler(.cancelAuthenticationChallenge, nil)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func session(_ session: URLSession,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.previousFailureCount > 0 {
            completionHandler(.cancelAuthenticationChallenge, nil)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func backgroundSessionDidFinishEvents(session: URLSession) { }
}
