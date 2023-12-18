import XCTest
@testable import Hellfire

final class HellfireTests: XCTestCase {
    
    static var allTests = [
        ("testSuite", testSuite),
    ]
    
    
    func testSuite() {
        //print(HTTPHeader.defaultUserAgent)
        //self.hashTest()
        //self.stressTestDiskCache()
        //self.testPerson()
        //self.testBirthdayDate()
    }
    
    func testHash() {
        let md5 = MD5Hash()
        
        for _ in 1 ... 1000 {
            let hash = md5.MD5(String.randomString(length: 5))
            let control = md5.MD5("Control string - Generate Same Hash")
            print (hash, control)
            XCTAssert(hash != control, "Incredible unexpected situation. Somehow you got a matching hash.")
        }
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
    
    //MARK: - Testing JSONSerializable - EmptyObject Decoding
    
    func testEmptyObjectDecoding1() {
        do {
            let _ = try EmptyObject.initialize(jsonData: nil)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testEmptyObjectDecoding2() {
        do {
            let jsonData = Data("{}".utf8)
            let _ = try EmptyObject.initialize(jsonData: jsonData)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    //MARK: - Testing JSONSerializable - Person Decoding
    
    func testPersonDataDecoding() {
        guard let path = Bundle.module.url(forResource: "Person", withExtension: "json") else {
            XCTFail("Failed to read JSONData from file.")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: path)
            let person = try Person.initialize(jsonData: jsonData)
            XCTAssert(person.firstName == "Edward", "Failed to map external property to internal property on Person.")
            XCTAssert(person.lastName == "Hellyer", "Failed to map external property to internal property on Person.")
            XCTAssert(person.isAwesome == true, "Failed to instantiate Person from JSON data.")
            XCTAssert(person.appointmentTime != nil, "Failed to decode appointmentTime")
            XCTAssert(person.someOtherDate != nil, "Failed to decode someOtherDate")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPersonDictionaryDecoding() {
        let jsonDict: [String : Any] = ["first_Name": "Edward",
                                        "last_Name": "Hellyer",
                                        "a_fantastic_person": true,
                                        "birthdate": "1970-01-01",
                                        "apt_time": "2020-01-01T21:45:00-0000",
                                        "someOtherDate": "2023-03-03T18:00:00"]
        
        do {
            let person = try Person(dictionary: jsonDict)
            XCTAssert(person.firstName == "Edward", "Failed to map external property to internal property on Person.")
            XCTAssert(person.lastName == "Hellyer", "Failed to map external property to internal property on Person.")
            XCTAssert(person.isAwesome == true, "Failed to instantiate Person from JSON data.")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    
    func testPersonArrayDataDecoding() {
        guard let path = Bundle.module.url(forResource: "PersonArray", withExtension: "json") else {
            XCTFail("Failed to read JSONData from file.")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: path)
            let person = try Array<Person>.initialize(jsonData: jsonData)
            XCTAssert(person.first?.firstName == "Edward", "Failed to map external property to internal property on Person.")
            XCTAssert(person.first?.lastName == "Hellyer", "Failed to map external property to internal property on Person.")
            XCTAssert(person.first?.isAwesome == true, "Failed to instantiate Person from JSON data.")
            XCTAssert(person.first?.appointmentTime != nil, "Failed to decode appointmentTime")
            XCTAssert(person.first?.someOtherDate != nil, "Failed to decode someOtherDate")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    //MARK: - Testing JSONSerializable - Person Encoding
    
    func testEmptyObjectEncoding() {
        let dc = EmptyObject()
        do {
            let _ = try dc.toJSONData()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPersonDataEncoding() {
        let person = Person(firstName: "Ed",
                            lastName: "Hellyer",
                            isAwesome: nil,
                            birthdate: Date(),
                            appointmentTime: Date(timeIntervalSince1970: 1703998800), //Dec 31st 2023 12:00 am
                            someOtherDate: Date())
        
        XCTAssertNoThrow(try person.toJSONData())
    }
    
    func testPersonDictionaryEncoding() {
        let person = Person(firstName: "Ed",
                            lastName: "Hellyer",
                            isAwesome: nil,
                            birthdate: Date(),
                            appointmentTime: Date(timeIntervalSince1970: 1703998800), //Dec 31st 2023 12:00 am
                            someOtherDate: Date())
        
        XCTAssertNoThrow(try person.toJSONObject())
    }
    
    func testPersonStringEncoding() {
        let person = Person(firstName: "Edward",
                            lastName: "Hellyer",
                            isAwesome: true,
                            birthdate: Date(),
                            appointmentTime: Date(timeIntervalSince1970: 1703998800), //Dec 31st 2023 12:00 am
                            someOtherDate: Date())
        XCTAssertNoThrow(try person.toJSONString())
    }
    
    func testPersonArrayEncoding() {
        let persons = [Person(firstName: "Ed", lastName: "Hellyer", isAwesome: nil, birthdate: Date()),
                       Person(firstName: "Jamie", lastName: "Hellyer", isAwesome: true, birthdate: Date()),
                       Person(firstName: "Bianca", lastName: "Hellyer", isAwesome: true, birthdate: Date()),
                       Person(firstName: "Hayden", lastName: "Hellyer", isAwesome: true, birthdate: Date()),
                       Person(firstName: "John", lastName: "Hellyer", isAwesome: true, birthdate: Date()),
                       Person(firstName: "Andrew", lastName: "Hellyer", isAwesome: true, birthdate: Date()),
                       Person(firstName: "Sue", lastName: "Hellyer", isAwesome: true, birthdate: Date()),
                       Person(firstName: "Albert", lastName: "Hellyer", isAwesome: false, birthdate: Date()),
                       Person(firstName: "Phyllis", lastName: "Hellyer", birthdate: Date())]
        
        XCTAssertNoThrow(try persons.toJSONData())
        XCTAssertNoThrow(try persons.toJSONString())
        XCTAssertThrowsError(try persons.toJSONObject())
        
        do {
            let personsJSONData = try persons.toJSONData()
            XCTAssertNoThrow(try Array<Person>.initialize(jsonData: personsJSONData))
        } catch {
            XCTFail("Failed to encode Array<Person> to JSONData.")
        }
    }
    

    
    func testCompanyDataDecoding() {

        guard let path = Bundle.module.url(forResource: "Company", withExtension: "json") else {
            XCTFail("Failed to read JSONData from file.")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: path)
            let company = try Company.initialize(jsonData: jsonData)
            let person = company.employees.first!
            XCTAssert(person.firstName == "Edward", "Failed to map external property to internal property on Person.")
            XCTAssert(person.lastName == "Hellyer", "Failed to map external property to internal property on Person.")
            XCTAssert(person.isAwesome == true, "Failed to instantiate Person from JSON data.")
            XCTAssert(person.appointmentTime != nil, "Failed to decode appointmentTime")
            XCTAssert(person.someOtherDate != nil, "Failed to decode someOtherDate")
        } catch {
            print(SessionInterface.sharedInstance.defaultJSONSerializableErrorHandler(error))
            XCTFail("Failed to decode TaskPage to JSONData.")
        }
    }
    
    func testPropertyWrapper() {
        guard let path = Bundle.module.url(forResource: "Company", withExtension: "json") else {
            XCTFail("Failed to read JSONData from file.")
            return
        }
        
        struct UserContainer: JSONSerializable {
            var user: User
        }
        
        struct User: JSONSerializable {
            let name: String
            
            @CodingUses<YearMonthDayFormatter>
            var dob: Date
            
            @CodingUses<ISO8601DateStaticCodable>
            var joinedAt: Date
        }
        
        do{
            let jsonData = try Data(contentsOf: path)
            let userContainer = try UserContainer.initialize(jsonData: jsonData)
            dump(userContainer)
        } catch {
            
        }
    }
    
    func testProductResponseDecoding() {
        
        guard let path = Bundle.module.url(forResource: "ProductsResponse", withExtension: "json") else {
            XCTFail("Failed to read JSONData from file.")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: path)
            let products = try [ProductElement].initialize(jsonData: jsonData)
            let product = products.first
            XCTAssert(product != nil, "Failed to decode products")
        } catch {
            print(SessionInterface.sharedInstance.defaultJSONSerializableErrorHandler(error))
            XCTFail("Failed to decode TaskPage to JSONData.")
        }
    }
}

