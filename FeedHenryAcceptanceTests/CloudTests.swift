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
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFHInitFailedWithCustomDataError() {
        // given no config file specified
        let getExpectation = expectationWithDescription("FH init should fail due to lack of appId")
        let config = Config(propertiesFile: "fhconfig", bundle: NSBundle(forClass: self.dynamicType))
        config.properties.removeValueForKey("appid")
        // when
        FH.setup(config, completionHandler: {(resp: Response, err: NSError?) -> Void in
            defer {
                getExpectation.fulfill()
            }
            if err != nil {
                XCTAssertNotNil(err!.userInfo.description)
                XCTAssertTrue((err!.userInfo["NSLocalizedDescription"] as! String).hasPrefix("The field 'appid' is not defined in"))
                XCTAssertTrue(resp.responseStatusCode! == 400)
            } else {
                XCTAssertTrue(false, "This test sgould failed because no valid fhconfig file was provided")
            }
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testFHInitSucceed() {
        // given a test config file
        let getExpectation = expectationWithDescription("FH successful")
        let config = Config(propertiesFile: "fhconfig", bundle: NSBundle(forClass: self.dynamicType))
        XCTAssertNotNil(config.properties.count == 5)
        // when
        FH.setup(config, completionHandler: { (resp: Response, err: NSError?) -> Void in
            defer { getExpectation.fulfill()}
            if err == nil {
                XCTAssertNotNil(FH.props)
                XCTAssertTrue(FH.props?.cloudProps.count == 6)
            }
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testFHPerformCloudRequestSucceed() {
        // given a test config file
        let getExpectation = expectationWithDescription("FH successful")
        let config = Config(propertiesFile: "fhconfig", bundle: NSBundle(forClass: self.dynamicType))
        XCTAssertNotNil(config.properties.count == 5)
        
        // when
        FH.setup(config, completionHandler: { (resp: Response, err: NSError?) -> Void  in
            if (err == nil) {
                FH.performCloudRequest("/hello",  method: "POST", headers: nil, args: nil, completionHandler: {(resp: Response, err: NSError?) -> Void  in
                    defer {
                        getExpectation.fulfill()
                    }
                    if err == nil {
                        XCTAssertNotNil(FH.props)
                        XCTAssertTrue(FH.props?.cloudProps.count == 6)
                    }
                })
            } else {
                XCTAssertTrue(false, "This test should not fail")
            }
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
}