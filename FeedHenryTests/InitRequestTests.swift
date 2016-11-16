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
import OHHTTPStubs

class InitRequestTests: XCTestCase {
    var dict: [String: AnyObject]!
    
    override func setUp() {
        dict = ["apptitle": "Native" as AnyObject,
            "domain": "myDomain" as AnyObject,
            "firstTime": 0 as AnyObject,
            "hosts": ["debugCloudType": "node",
                "debugCloudUrl": "ttps://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net",
                "releaseCloudType": "node",
                "releaseCloudUrl": "https://myDomain-fxpfgc8zld4erdytbixl3jlh-live.df.live.e111.feedhenry.net",
                "type": "cloud_nodejs",
                "url": "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net",
                "environment": "ENV"] as AnyObject,
            "init": ["trackId": "eVtZFmW5NAbyEIJ8aecE2jJJ"] as AnyObject,
            "status": "ok" as AnyObject]
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFHInitFailedWithCustomDataError() {
        // stub http to return error
        stub(condition: isHost("whatever.com")) { _ in
            let userInfo = ["CustomData": ["msg": "The field 'appid' is not defined in"], "StatusCode":400] as [String : Any]
            let error = NSError(domain: "FeedHenryHTTPRequestErrorDomain", code: 0, userInfo: userInfo)
            let stubResponse = OHHTTPStubsResponse(error: error)
            return stubResponse
        }

        // given no config file specified
        let getExpectation = expectation(description: "FH init should fail due to lack of appId")
        let config = Config(propertiesFile: "fhconfig", bundle: Bundle(for: type(of: self)))
        config.properties.removeValue(forKey: "appid")
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
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFHInitSucceed() {
        stub(condition: isHost("whatever.com")) { _ in
            let stubResponse = OHHTTPStubsResponse(jsonObject: self.dict, statusCode: 200, headers: nil)
            return stubResponse
        }
        // given a test config file
        let getExpectation = expectation(description: "FH successful")
        let config = Config(propertiesFile: "fhconfig", bundle: Bundle(for: type(of: self)))
        XCTAssertNotNil(config.properties.count == 5)
        // when
        FH.setup(config, completionHandler: { (resp: Response, err: NSError?) -> Void in
            defer { getExpectation.fulfill()}
            if err == nil {
                XCTAssertNotNil(FH.props)
                XCTAssertTrue(FH.props?.cloudProps.count == 6)
            }
        })
        waitForExpectations(timeout: 10, handler: nil)
    }

//    func testFHPerformCloudRequestSucceed() {
//        stub(isHost("whatever.com")) { _ in
//            let stubResponse = OHHTTPStubsResponse(JSONObject: self.dict, statusCode: 200, headers: nil)
//            return stubResponse
//        }
//        stub(isHost("myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net")) { _ in
//            let stubResponse = OHHTTPStubsResponse(JSONObject: ["key":"value"], statusCode: 200, headers: nil)
//            return stubResponse
//        }
//        // given a test config file
//        let getExpectation = expectationWithDescription("FH successful")
//        let config = Config(propertiesFile: "fhconfig", bundle: NSBundle(forClass: self.dynamicType))
//        XCTAssertNotNil(config.properties.count == 5)
//        
//        // when
//        FH.setup(config, completionHandler: { (resp: Response, err: NSError?) -> Void  in
//            if (err == nil) {
//                FH.performCloudRequest("/hello",  method: "POST", headers: nil, args: nil, completionHandler: {(resp: Response, err: NSError?) -> Void  in
//                    defer {
//                        getExpectation.fulfill()
//                    }
//                    if err == nil {
//                        XCTAssertNotNil(FH.props)
//                        XCTAssertTrue(FH.props?.cloudProps.count == 6)
//                        XCTAssertNotNil(resp)
//                        XCTAssertTrue(resp.parsedResponse!["key"] as! String == "value")
//                    } else {
//                        XCTAssertTrue(false)
//                    }
//                })
//            } else {
//                XCTAssertTrue(false, "This test should not fail")
//            }
//        })
//        waitForExpectationsWithTimeout(10, handler: nil)
//    }
    
    func testInitRequestConstruct() {
        let config = Config(propertiesFile: "fhconfig", bundle: Bundle(for: type(of: self)))
        let initRequest = InitRequest(config: config)
        XCTAssertEqual(initRequest.method, HTTPMethod.POST)
        XCTAssertTrue(initRequest.args!.count == 7)
        XCTAssertNil(initRequest.headers)
    }

    
//    func testInitRequestExec() {
//        let getExpectation = expectationWithDescription("FH successful")
//        let config = Config(propertiesFile: "fhconfig", bundle: NSBundle(forClass: self.dynamicType))
//        let initRequest = InitRequestMock(config: config)
//        
//        initRequest.exec { (resp:Response, err:NSError?) -> Void in
//            defer {
//                getExpectation.fulfill()
//            }
//        }
//        waitForExpectationsWithTimeout(10, handler: nil)
//    }
}
