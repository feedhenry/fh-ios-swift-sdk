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

class AuthRequestTests: XCTestCase {
    var dict: [String: Any]!
    var dictAuth: [String: Any]!
    var dictAuthError: [String: Any]!
    var url: String!
    override func setUp() {
        url = "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=873670803862-mhdrf72agp9fv82n32dc7dia541mlu87.apps.googleusercontent.com&redirect_uri=https%3A%2F%2Ftesting.zeta.feedhenry.com%2Fbox%2Fsrv%2F1.1%2Farm%2FauthCallback&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email&state=eyJhcHBJZCI6IjV3bGE3bGF2d3h0cjNmaXhzdXllN2lzbSIsImNhY2hla2V5IjoiNWJhYmVhYzg0YTYwYTk3Y2M4NmRhYTNlYzNkNTg1M2QiLCJjbGllbnRUb2tlbiI6IjV3bGE3bGF2d3h0cjNmaXhzdXllN2lzbSIsImRldmljZSI6IjgxMDdGREY2LTBCNDgtNDExOS1CQUQyLTMyQUZENDdCNTE0NyIsImRvbWFpbiI6InRlc3RpbmciLCJlbmRSZWRpcmVjdFVybCI6Imh0dHBzOi8vdGVzdGluZy56ZXRhLmZlZWRoZW5yeS5jb20vYm94L3Nydi8xLjEvYXJtL2F1dGhDYWxsYmFjayIsInBvbGljeSI6IkdPT0dMRSIsInBvbGljeUlkIjoiR29vZ2xlIiwicHJvdG9jb2wiOiJPQVVUSCJ9"
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
        dictAuth = ["status": "ok",
            "url": url,
            "cachekey": "5babeac84a60a97cc86daa3ec3d5853d"]
        dictAuthError = ["status": "error"]
        
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAuthRequestConstruct() {
        let config = Config(propertiesFile: "fhconfig", bundle: Bundle(for: type(of: self)))
        let authRequest = AuthRequest(props: CloudProps(props: dict as [String: AnyObject])!, config: config, policyId: "hello")
        XCTAssertEqual(authRequest.method, HTTPMethod.POST)
        XCTAssertTrue(authRequest.props.cloudHost == "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net/")
        XCTAssertNil(authRequest.headers)
        XCTAssertNil(authRequest.args!["params"])
        XCTAssertTrue(authRequest.args!["policyId"] as! String == "hello")
        XCTAssertTrue(authRequest.args!["device"] as! String == config.uuid)
        XCTAssertTrue(authRequest.args!["clientToken"] as! String == "fXPFgWSN94DxoFoqgml6WeES")
        XCTAssertTrue(authRequest.args!["environment"] as! String == "ENV")
    }
    
    func testAuthRequestConstructWithUserIdAndPassword() {
        let config = Config(propertiesFile: "fhconfig", bundle: Bundle(for: type(of: self)))
        let authRequest = AuthRequest(props: CloudProps(props: dict as [String: AnyObject])!, config: config, policyId: "hello", userName: "Henrik", password: "secret")
        XCTAssertEqual(authRequest.method, HTTPMethod.POST)
        XCTAssertTrue(authRequest.props.cloudHost == "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net/")
        XCTAssertNil(authRequest.headers)
        XCTAssertTrue((authRequest.args!["params"] as AnyObject).count == 2)
        XCTAssertTrue(authRequest.args!["policyId"] as! String == "hello")
        XCTAssertTrue(authRequest.args!["device"] as! String == config.uuid)
        XCTAssertTrue(authRequest.args!["clientToken"] as! String == "fXPFgWSN94DxoFoqgml6WeES")
        XCTAssertTrue(authRequest.args!["environment"] as! String == "ENV")
        let params = authRequest.args!["params"] as! [String:String]
        XCTAssertTrue(params["userId"] == "Henrik")
        XCTAssertTrue(params["password"] == "secret")
    }
    
    func testSucceedInitWithMockedStorage() {
        class NSUserDefaultsMock: UserDefaults {
            var internalValue: String?
            override open class var standard: UserDefaults {
                return NSUserDefaultsMock()
            }
            override func string(forKey defaultName: String) -> String? {
                return internalValue
            }
            
            override func set(_ value: Any?, forKey defaultName: String) {
                internalValue = value as? String
            }
        }
        let config = Config(propertiesFile: "fhconfig", bundle: Bundle(for: type(of: self)))
        let authtRequest = AuthRequest(props: CloudProps(props: dict as [String: AnyObject])!, config: config, policyId: "hello", storage: NSUserDefaultsMock())
        authtRequest.sessionToken = "SessionTokenStored"
        XCTAssertTrue(authtRequest.sessionToken == "SessionTokenStored", "sessionToken stored in NSUserDefaults.")
    }
    

    func testFHAuthSucceed() {
        stub(condition: isHost("whatever.com")) { _ in
            let stubResponse = OHHTTPStubsResponse(jsonObject: self.dictAuth, statusCode: 200, headers: nil)
            return stubResponse
        }
        // given a test config file
        let getExpectation = expectation(description: "FH auth successful")
        let config = Config(propertiesFile: "fhconfig", bundle: Bundle(for: type(of: self)))
        
        // when
        let authRequest = AuthRequest(props: CloudProps(props: dict as [String: AnyObject])!, config: config, policyId: "hello", userName: "Henrik", password: "secret")
        authRequest.exec { (response: Response, error: NSError?) -> Void in
            //
            defer { getExpectation.fulfill()}
            XCTAssertTrue(response.parsedResponse!["status"] as! String == "ok")
            XCTAssertTrue(response.parsedResponse!["url"] as! String == self.url)
            XCTAssertTrue(response.parsedResponse!["cachekey"] as! String == "5babeac84a60a97cc86daa3ec3d5853d")
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFHAuthFailed() {
        stub(condition: isHost("whatever.com")) { _ in
            let stubResponse = OHHTTPStubsResponse(jsonObject: self.dictAuthError, statusCode: 200, headers: nil)
            return stubResponse
        }
        // given a test config file
        let getExpectation = expectation(description: "FH successful")
        let config = Config(propertiesFile: "fhconfig", bundle: Bundle(for: type(of: self)))
        
        // when
        let authRequest = AuthRequest(props: CloudProps(props: dict as [String: AnyObject])!, config: config, policyId: "hello", userName: "Henrik", password: "secret")
        authRequest.exec { (response: Response, error: NSError?) -> Void in
            //
            defer { getExpectation.fulfill()}
            XCTAssertTrue(response.error!.domain == "FeedHenryAuthError")
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFHAuthRequestFailed() {
        stub(condition: isHost("whatever.com")) { _ in
            let stubResponse = OHHTTPStubsResponse(jsonObject: self.dictAuthError, statusCode: 500, headers: nil)
            return stubResponse
        }
        // given a test config file
        let getExpectation = expectation(description: "FH successful")
        let config = Config(propertiesFile: "fhconfig", bundle: Bundle(for: type(of: self)))
        
        // when
        let authRequest = AuthRequest(props: CloudProps(props: dict as [String: AnyObject])!, config: config, policyId: "hello", userName: "Henrik", password: "secret")
        authRequest.exec { (response: Response, error: NSError?) -> Void in
            //
            defer { getExpectation.fulfill()}
            XCTAssertTrue(response.error!.domain == "FeedHenryHTTPRequestErrorDomain")
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    

}
