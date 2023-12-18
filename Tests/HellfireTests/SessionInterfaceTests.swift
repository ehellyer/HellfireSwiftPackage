//
//  SessionInterfaceTests.swift
//  
//
//  Created by Ed Hellyer on 1/6/24.
//

import XCTest
@testable import Hellfire

final class SessionInterfaceTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testDataTask() {
        let expectation = self.expectation(description: "Waiting for network call to complete.")
        
        let interface = SessionInterface.sharedInstance
        let request = NetworkRequest(url: URL(string: "https://api.escuelajs.co/api/v1/products")!, method: .get)
        let _ = interface.execute(request) { (result) in
            switch result {
                case .success(let dataResponse):
                    print(NSString(data: dataResponse.body!, encoding: 4)!)
                case .failure(let serviceError):
                    XCTFail(serviceError.localizedDescription)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 20)
    }
    
    func testJSONTask() {
        let expectation = self.expectation(description: "Waiting for network call to complete.")
        
        let interface = SessionInterface.sharedInstance
        let request = NetworkRequest(url: URL(string: "https://api.escuelajs.co/api/v1/products")!, method: .get)
        let _ = interface.execute(request) { (result: JSONSerializableResult<[ProductElement]>) in
            switch result {
                case .success(let dataResponse):
                    print(dataResponse.jsonObject)
                case .failure(let serviceError):
                    XCTFail(serviceError.localizedDescription)
            }
            
            expectation.fulfill()
        }
        waitForExpectations(timeout: 20)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
