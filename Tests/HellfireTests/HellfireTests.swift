import XCTest
@testable import Hellfire

final class HellfireTests: XCTestCase {
    
    
    static var allTests = [
        ("testSuite", testSuite),
    ]
    
    func testSuite() {
        self.testPerson()
        //self.testBirthdayDate()
    }

    
    //Mark: - Testing JSONSerializeable
    
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
        XCTAssert(person?.isAwesome == true, "Failed to instanciate Person from JSON data.")
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
