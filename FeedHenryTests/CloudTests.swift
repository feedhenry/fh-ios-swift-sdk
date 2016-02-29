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

class CloudTests: XCTestCase {
    var config: Config?
    var dict: [String: AnyObject]!
    
    override func setUp() {
        dict = ["apptitle": "Native",
            "domain": "myDomain",
            "firstTime": 0,
            "hosts": ["debugCloudType": "node",
                "debugCloudUrl": "ttps://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net",
                "releaseCloudType": "node",
                "releaseCloudUrl": "https://myDomain-fxpfgc8zld4erdytbixl3jlh-live.df.live.e111.feedhenry.net",
                "type": "cloud_nodejs",
                "url": "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net",
                "environment": "ENV"],
            "init": ["trackId": "eVtZFmW5NAbyEIJ8aecE2jJJ"],
            "status": "ok"]
        stub(isHost("whatever.com")) { _ in
            let stubResponse = OHHTTPStubsResponse(JSONObject: self.dict, statusCode: 200, headers: nil)
            return stubResponse
        }
        // given a test config file
        let getExpectation = expectationWithDescription("FH successful")
        config = Config(propertiesFile: "fhconfig", bundle: NSBundle(forClass: self.dynamicType))
        
        // when
        FH.setup(config!, completionHandler: { (response:Response, err: NSError?) -> Void in
            defer { getExpectation.fulfill()}
            
            print("initialized OK \(response)")
            
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFHPerformCloudRequestSucceed() {
        stub(isHost("myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net")) { _ in
            let stubResponse = OHHTTPStubsResponse(JSONObject: ["key":"value"], statusCode: 200, headers: nil)
            return stubResponse
        }
        // given a test config file
        let getExpectation = expectationWithDescription("FH successful")
        
        FH.performCloudRequest("/hello",  method: "POST", headers: nil, args: nil, config: config!, completionHandler: { (resp: Response, err: NSError?) -> Void in
            defer {
                getExpectation.fulfill()
            }
            
            if (err != nil) {
                XCTAssertTrue(false)
            }
        })
        XCTAssertNotNil(FH.props)
        XCTAssertTrue(FH.props?.cloudProps.count == 6)
        XCTAssertTrue(FH.props?.cloudProps["apptitle"] as! String == "Native")
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
}