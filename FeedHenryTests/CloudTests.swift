/*
* JBoss, Home of Professional Open Source.
* Copyright Red Hat, Inc., and individual contributors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import XCTest
@testable import FeedHenry

class CloudTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // TODO mock this test
    // atm we really hit FH domain
    func testFHInitFailedWithCustomDataError() {
        // given no config file specified
        let getExpectation = expectationWithDescription("FH init should fail due to lack of appId")
        let config = Config(propertiesFile: "fhconfig", bundle: NSBundle(forClass: self.dynamicType))
        config.properties.removeValueForKey("appid")
        // when
        FH.setup(config, completionHandler: {(inner: () throws -> Response) -> Void in
            defer {
                getExpectation.fulfill()
            }
            do {
                let _ = try inner()
            } catch let error {
                // then
                XCTAssertNotNil((error as NSError).userInfo.description)
                XCTAssertTrue(((error as NSError).userInfo["NSLocalizedDescription"] as! String).hasPrefix("The field 'appid' is not defined in"))
                return
            }
            XCTAssertTrue(false, "This test sgould failed because no valid fhconfig file was provided")
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    // TODO mock this test
    // atm we really hit FH domain
    func testFHInitSucceed() {
        // given a test config file
        let getExpectation = expectationWithDescription("FH successful")
        let config = Config(propertiesFile: "fhconfig", bundle: NSBundle(forClass: self.dynamicType))
        XCTAssertNotNil(config.properties.count == 5)
        XCTAssertNil(FH.props)
        // when
        FH.setup(config, completionHandler: { (inner: () throws -> Response) -> Void in
            defer {
                getExpectation.fulfill()
            }
            do {
                let result = try inner()
                print("initialized OK \(result)")
                XCTAssertNotNil(FH.props)
                XCTAssertTrue(FH.props?.cloudProps.count == 6)
                XCTAssertTrue(FH.props?.cloudProps["apptitle"] as! String == "Native")
                ////let customData = (error as NSError).userInfo["CustomData"] as? [String: AnyObject]
                //XCTAssertNotNil(customData)
                // XCTAssertNotEqual(customData!, [:])
                //let msg = customData!["msg"] as! String
                //XCTAssertTrue(msg.hasPrefix("The field 'appid' is not defined in"))
            } catch let _ {

            }
            
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }


}
