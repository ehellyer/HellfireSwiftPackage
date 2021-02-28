//
//  RequestItem.swift
//  Hellfire
//
//  Created by Ed Hellyer on 2/23/21.
//

import Foundation

/// This object is associated with the URLSessionTask so that the application can identify the task.  Especially useful after application is relaunched after termination.
public struct RequestItem {
    
    /// Global unique identifier for the task, regardless of the session it is executing on.
    public let identifier: RequestTaskIdentifier
    
    
    /// The originating request.  The can be a downcast representation of the MultipartRequest, in which case this reference can be used to cleanup the request body if needed.
    public let networkRequest: NetworkRequest
}
