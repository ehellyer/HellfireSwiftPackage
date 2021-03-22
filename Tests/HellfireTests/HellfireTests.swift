import XCTest
@testable import Hellfire

final class HellfireTests: XCTestCase {
    
    static var allTests = [
        ("testSuite", testSuite),
    ]
    
    func testSuite() {
        self.stressTestDiskCache()
        self.testPerson()
        //self.testBirthdayDate()
    }


    func stressTestDiskCache() {
        let config = DiskCacheConfiguration(settings: [CachePolicyType.hour: 1000,
                                                       .fourHours: 1000,
                                                       .day: 1000,
                                                       .week: 1000,
                                                       .month: 1000,
                                                       .untilSpaceNeeded: 1000])
        
        
        let dc = DiskCache(config: config)
        dc.clearCache()
        
        for i in 10000000...10006000 {
            autoreleasepool {
                let data = "\(i)".data(using: .utf8)!
                let request1 = NetworkRequest(url: URL(string: "https://www.apple.com/\(i)")!, method: .get, cachePolicyType: .hour, body: data)
                let request2 = NetworkRequest(url: URL(string: "https://www.apple.com/\(i)")!, method: .get, cachePolicyType: .day, body: data)
                let request3 = NetworkRequest(url: URL(string: "https://www.apple.com/\(i)")!, method: .get, cachePolicyType: .week, body: data)
                let _ = dc.cache(data: data, forRequest: request1)
                let _ = dc.cache(data: data, forRequest: request2)
                let _ = dc.cache(data: data, forRequest: request3)
            }
        }
    }
    
    //Mark: - Testing JSONSerializable
    
    func testPerson() {
        let jsonStr = """
        {
        "first_Name": "Edward",
        "last_Name": "Hellyer",
        "a_fantastic_person": true
        }
        """
        let jsonData = Data(jsonStr.utf8)
        let person = Person.initialize(jsonData: jsonData)
        XCTAssert(person?.firstName == "Edward", "Failed to map external property to internal property on Person.")
        XCTAssert(person?.lastName == "Hellyer", "Failed to map external property to internal property on Person.")
        XCTAssert(person?.isAwesome == true, "Failed to instantiate Person from JSON data.")
    }
    
//    func testBirthdayDate() {
//        let jsonStr = """
//        {
//        "birthdate": "1975-03-21"
//        }
//        """
//        let jsonData = Data(jsonStr.utf8)
//        let bday = Birthday.initialize(jsonData: jsonData)
//        XCTAssert(bday?.birthdate != nil, "Failed to create date object from JSON data.")
//    }
}
