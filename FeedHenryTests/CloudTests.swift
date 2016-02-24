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
    var config: Config?
    override func setUp() {
        super.setUp()
        // given a test config file
        let getExpectation = expectationWithDescription("FH successful")
        config = Config(propertiesFile: "fhconfig", bundle: NSBundle(forClass: self.dynamicType))
        
        // when
        FH.setup(config!, completionHandler: { (inner: () throws -> Response) -> Void in
            defer { getExpectation.fulfill()}
            do {
                let result = try inner()
                print("initialized OK \(result)")
            } catch _ {}
        })
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /*
    NSDictionary *args = [NSDictionary dictionaryWithObject:name.text forKey:@"hello"];
    FHCloudRequest *req = (FHCloudRequest *) [FH buildCloudRequest:@"/hello" WithMethod:@"POST" AndHeaders:nil AndArgs:args];
    
    [req execAsyncWithSuccess:^(FHResponse * res) {
    // Response
    NSLog(@"Response: %@", res.rawResponseAsString);
    result.text = [res.parsedResponse objectForKey:@"msg"];
    } AndFailure:^(FHResponse * res){
    // Errors
    NSLog(@"Failed to call. Response = %@", res.rawResponseAsString);
    result.text = res.rawResponseAsString;
    }];
    */
    
    /*
    + (void)performCloudRequest:(NSString *)path
    WithMethod:(NSString *)requestMethod
    AndHeaders:(NSDictionary *)headers
    AndArgs:(NSDictionary *)arguments
    AndSuccess:(void (^)(FHResponse *success))sucornil
    AndFailure:(void (^)(FHResponse *failed))failornil
    
    */
    
    // https://aerogear.feedhenry.com/box/srv/1.1/app/init
    // https://aerogear-fxpfgc8zld4erdytbixl3jlh-dev.df.dev.e111.feedhenry.net/hello
    func testFHPerformCloudRequestSucceed() {
        // given a test config file
        let getExpectation = expectationWithDescription("FH successful")
        
        FH.performCloudRequest("/hello",  method: "POST", headers: nil, args: nil, config: config!, completionHandler: { (inner: () throws -> Response) -> Void in
            defer {
                getExpectation.fulfill()
            }
            do {
                let result = try inner()
            } catch let error {
                print("error::::\(error)")
                XCTAssertTrue(false)
            }
        })
        XCTAssertNotNil(FH.props)
        XCTAssertTrue(FH.props?.cloudProps.count == 6)
        XCTAssertTrue(FH.props?.cloudProps["apptitle"] as! String == "Native")
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
}
