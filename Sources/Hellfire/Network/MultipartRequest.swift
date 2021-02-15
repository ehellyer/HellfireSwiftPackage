//
//  MultipartUploadRequest.swift
//  Hellfire
//
//  Created by Ed Hellyer on 1/14/21.
//

import Foundation

public class MultipartRequest: NetworkRequest {
    
    private let fileManager: FileManager
    private var requestBodyURL: URL?
    
    public init(url: URL,
                method: HTTPMethod,
                multipartFormData: MultipartFormData) {
        self.multipartFormData = multipartFormData
        self.fileManager = multipartFormData.fileManager
        super.init(url: url,
                   method: method,
                   contentType: multipartFormData.contentType.value)
    }
    
    public var multipartFormData: MultipartFormData
    
    public func build() throws -> (request: URLRequest, requestBodyURL: URL) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = self.method.name
        urlRequest.setValue(self.multipartFormData.contentType.value, forHTTPHeaderField: self.multipartFormData.contentType.name)
        urlRequest.setValue("\(self.multipartFormData.contentLength)", forHTTPHeaderField: "Content-Length")
        
        let tempDirectoryURL = fileManager.temporaryDirectory
        let directoryURL = tempDirectoryURL.appendingPathComponent("hellfire/multipart.form.data")
        let fileName = "MultipartFormDataRequest\(String.randomString(length: 15)).txt"
        let _requestBodyURL = directoryURL.appendingPathComponent(fileName)
        self.requestBodyURL = _requestBodyURL
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)

        do {
            try multipartFormData.writeEncodedData(to: _requestBodyURL)
        } catch {
            self.cleanUpHttpBody()
            throw error
        }
        
        return (request: urlRequest, requestBodyURL: _requestBodyURL)
    }
    
    public func cleanUpHttpBody() {
        guard let _requestBodyURL = self.requestBodyURL else { return }
        try? self.fileManager.removeItem(at: _requestBodyURL)
    }
}



