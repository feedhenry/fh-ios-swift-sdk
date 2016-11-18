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

class CloudPropsTest: XCTestCase {
    var cloudProps: CloudProps?
    var dict: [String: Any]!
    
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
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFailedInitDueToLackOfHostsProps() {
        dict.removeValue(forKey: "hosts")
        cloudProps = CloudProps(props: dict as [String: AnyObject])
        XCTAssertNil(cloudProps, "CloudProps should be nil. No hosts provided.")
    }
    
    func testFailedInitDueTLackOfInitProps() {
        dict.removeValue(forKey: "init")
        cloudProps = CloudProps(props: dict as [String: AnyObject])
        XCTAssertNil(cloudProps, "CloudProps should be nil. No Init/TrackId provided.")
    }
    
    func testSucceedInit() {
        cloudProps = CloudProps(props: dict as [String: AnyObject])
        XCTAssertNotNil(cloudProps, "CloudProps should not be nil")
        XCTAssertEqual(cloudProps?.cloudHost, "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net/")
        XCTAssertEqual(cloudProps?.env, "ENV")
        XCTAssertTrue(cloudProps?.cloudProps.count == 6)
        XCTAssertTrue(cloudProps?.trackId == "eVtZFmW5NAbyEIJ8aecE2jJJ", "TrackId stored in NSUserDefaults.")
    }
    
    func testSucceedInitWithMockedStorage() {
        class NSUserDefaultsMock: UserDefaults {
            
            override open class var standard: UserDefaults {
                return NSUserDefaultsMock()
            }
            
            override func string(forKey defaultName: String) -> String? {
                return "TRACK"
            }
            
            override func set(_ value: Any?, forKey defaultName: String) {
            }
        }
        
        cloudProps = CloudProps(props: dict as [String: AnyObject], storage: NSUserDefaultsMock())
        XCTAssertNotNil(cloudProps, "CloudProps should not be nil")
        XCTAssertEqual(cloudProps?.cloudHost, "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net/")
        XCTAssertEqual(cloudProps?.env, "ENV")
        XCTAssertTrue(cloudProps?.cloudProps.count == 6)
        XCTAssertTrue(cloudProps?.trackId == "TRACK", "TrackId stored in NSUserDefaults.")
    }

    
    func testSuccedInitWithURL() {
        var hosts = dict["hosts"] as! [String: Any]
        hosts["url"] = "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net/"
        dict["hosts"] = hosts
        cloudProps = CloudProps(props: dict as [String: AnyObject])
        XCTAssertNotNil(cloudProps, "CloudProps should not be nil")
        XCTAssertEqual(cloudProps?.cloudHost, "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net/")
    }
    
    func testSucceedWithoutEnvProps() {
        cloudProps = CloudProps(props: dict as [String : AnyObject])
        XCTAssertNotNil(cloudProps, "CloudProps should be nil. No hosts provided.")
    }
    
}
