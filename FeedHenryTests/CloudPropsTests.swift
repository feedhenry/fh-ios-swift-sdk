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
import FeedHenry


class CloudPropsTest: XCTestCase {
    var cloudProps: CloudProps?
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
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFailedInitDueToLackOfHostsProps() {
        dict.removeValueForKey("hosts")
        cloudProps = CloudProps(props: dict)
        XCTAssertNil(cloudProps, "CloudProps should be nil. No hosts provided.")
    }
    
    func testFailedInitDueTLackOfInitProps() {
        dict.removeValueForKey("init")
        cloudProps = CloudProps(props: dict)
        XCTAssertNil(cloudProps, "CloudProps should be nil. No Init/TrackId provided.")
    }
    
    func testSucceedInit() {
        cloudProps = CloudProps(props: dict)
        XCTAssertNotNil(cloudProps, "CloudProps should not be nil")
        XCTAssertEqual(cloudProps?.cloudHost, "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net/")
        XCTAssertEqual(cloudProps?.env, "ENV")
        XCTAssertTrue(cloudProps?.cloudProps.count == 6)
        XCTAssertTrue(cloudProps?.trackId == "eVtZFmW5NAbyEIJ8aecE2jJJ", "TrackId stored in NSUserDefaults.")
    }
    
    func testSucceedInitWithMockedStorage() {
        class NSUserDefaultsMock: NSUserDefaults {
            override class func standardUserDefaults() -> NSUserDefaults {
                return NSUserDefaultsMock()
            }
            override func stringForKey(defaultName: String) -> String? {
                return "TRACK"
            }
            
            override func setObject(value: AnyObject?, forKey defaultName: String) {
            }
        }
        
        cloudProps = CloudProps(props: dict, storage: NSUserDefaultsMock())
        XCTAssertNotNil(cloudProps, "CloudProps should not be nil")
        XCTAssertEqual(cloudProps?.cloudHost, "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net/")
        XCTAssertEqual(cloudProps?.env, "ENV")
        XCTAssertTrue(cloudProps?.cloudProps.count == 6)
        XCTAssertTrue(cloudProps?.trackId == "TRACK", "TrackId stored in NSUserDefaults.")
    }

    
    func testSuccedInitWithURL() {
        var hosts = dict["hosts"] as! [String: AnyObject]
        hosts["url"] = "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net/"
        dict["hosts"] = hosts
        cloudProps = CloudProps(props: dict)
        XCTAssertNotNil(cloudProps, "CloudProps should not be nil")
        XCTAssertEqual(cloudProps?.cloudHost, "https://myDomain-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net/")
    }
    
    func testSucceedWithoutEnvProps() {
        var hosts = dict["hosts"] as? [String: AnyObject]
        hosts?.removeValueForKey("environment")
        cloudProps = CloudProps(props: dict)
        XCTAssertNotNil(cloudProps, "CloudProps should be nil. No hosts provided.")
    }
    
}
