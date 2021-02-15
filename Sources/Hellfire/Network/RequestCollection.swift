//
//  RequestCollection.swift
//  HellFire
//
//  Created by Ed Hellyer on 2/12/19.
//  Copyright © 2019 Ed Hellyer. All rights reserved.
//

import Foundation

public typealias RequestTaskIdentifier = UUID

internal struct RequestCollectionItem {
    
    let identifier: RequestTaskIdentifier
    
    var networkRequest: NetworkRequest
    
    var urlRequest: URLRequest
    
    var requestBodyURL: URL?
    
    var sessionTask: URLSessionTask
}

internal class RequestCollection {

    //MARK: - Class setup
    
    init() {
        let queueLabel = "ThreadSafeMessageQueue." + String.randomString(length: 12)
        self.serialMessageQueue = DispatchQueue(label: queueLabel)
    }

    //MARK: - Private API

    //Queue used to ensure synchronous access to the 'requests' collection and the index 'taskIndex'
    private var serialMessageQueue: DispatchQueue

    //Collection of concurrent requests in call
    private var requests = [RequestTaskIdentifier: RequestCollectionItem]()
    
    private var taskIndex = [URLSessionTask: RequestTaskIdentifier]()
    
    //MARK: - Internal API
    
    internal func removeTaskRequest(forTaskIdentifier taskIdentifier: RequestTaskIdentifier) {
        self.serialMessageQueue.sync {
            guard let item = self.requests.removeValue(forKey: taskIdentifier) else { return }
            self.taskIndex.removeValue(forKey: item.sessionTask)
            if item.sessionTask.state != URLSessionTask.State.completed {
                item.sessionTask.cancel()
            }
        }
    }
    
    internal func removeTaskRequest(networkRequest: NetworkRequest) {
        guard let identifier = self.requests.first(where: { $0.value.networkRequest === networkRequest })?.key else { return }
        self.removeTaskRequest(forTaskIdentifier: identifier)
    }
    
    internal func add(networkRequest: NetworkRequest, task: URLSessionTask, for request: URLRequest, requestBodyURL: URL?) -> RequestTaskIdentifier {
        self.serialMessageQueue.sync {
            let taskIdentifier = RequestTaskIdentifier()
            let item = RequestCollectionItem(identifier: taskIdentifier, networkRequest: networkRequest, urlRequest: request, requestBodyURL: requestBodyURL, sessionTask: task)
            let _ = self.requests.updateValue(item, forKey: taskIdentifier)
            let _ = self.taskIndex.updateValue(taskIdentifier, forKey: task)
            return taskIdentifier
        }
    }
    
    internal func allTaskIdentifiers() -> [RequestTaskIdentifier] {
        self.serialMessageQueue.sync {
            let taskIdentifiers = self.requests.compactMap { $0.key }
            return taskIdentifiers
        }
    }

    internal func taskRequestItem(forTaskIdentifier taskIdentifier: RequestTaskIdentifier) -> RequestCollectionItem? {
        self.serialMessageQueue.sync {
            return self.requests[taskIdentifier]
        }
    }
    
    internal func taskRequestItem(forSessionTask urlSessionTask: URLSessionTask) -> RequestCollectionItem? {
        self.serialMessageQueue.sync {
            guard let taskIdentifier = self.taskIndex[urlSessionTask] else { return nil }
            return self.requests[taskIdentifier]
        }
    }
}
