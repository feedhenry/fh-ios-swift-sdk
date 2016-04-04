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

class OAuthViewControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testQueryProcessingNoCompleteStatus() {
        // given
        let query = "https://accounts.google.com/ServiceLogin?passive=1209600&continue=https://accounts.google.com/o/oauth2/auth?scope%3Dhttps://www.googleapis.com/auth/userinfo.email%26response_type%3Dcode%26redirect_uri%3Dhttps://testing.zeta.feedhenry.com/box/srv/1.1/arm/authCallback%26state%3DeyJhcHBJZCI6IjV3bGE3bGF2d3h0cjNmaXhzdXllN2lzbSIsImNhY2hla2V5IjoiNzZmMjE1MWMwZmRiOGY3ZjlhNzhjOGRlODNkZTE3MTAiLCJjbGllbnRUb2tlbiI6IjV3bGE3bGF2d3h0cjNmaXhzdXllN2lzbSIsImRldmljZSI6IkY0ODc1OTk5LUE5RTEtNDhGMC05MTAzLTBCNzQ3NjQ1QjMwQSIsImRvbWFpbiI6InRlc3RpbmciLCJlbmRSZWRpcmVjdFVybCI6Imh0dHBzOi8vdGVzdGluZy56ZXRhLmZlZWRoZW5yeS5jb20vYm94L3Nydi8xLjEvYXJtL2F1dGhDYWxsYmFjayIsInBvbGljeSI6IkdPT0dMRSIsInBvbGljeUlkIjoiR29vZ2xlIiwicHJvdG9jb2wiOiJPQVVUSCJ9%26client_id%3D873670803862-mhdrf72agp9fv82n32dc7dia541mlu87.apps.googleusercontent.com%26hl%3Den-US%26from_login%3D1%26as%3D665d49a3965955de&ltmpl=popup&oauth=1&sarp=1&scc=1"
        // when
        let oauth = OAuthViewController()
        let result = try! oauth.processQuery(query)
        
        // assert
        XCTAssertTrue(result!.count == 0)
    }
    
    func testQueryProcessingCompleteStatus() {
        // given
        let query = "fh_auth_session=atmknuh4vclrft5d3emg2usv&authResponse=%7B%22authToken%22%3A%22ya29..ugKxZiiNa9It6sFYXuy2Op5F58fiVXACzN-Dcm6tb38G-v2H6zW8lP-aV4y28sdF9DU%22%2C%22email%22%3A%22corinnekrych%40gmail.com%22%2C%22family_name%22%3A%22Krych%22%2C%22gender%22%3A%22female%22%2C%22given_name%22%3A%22Corinne%22%2C%22id%22%3A%22115252170034907237047%22%2C%22link%22%3A%22https%3A%2F%2Fplus.google.com%2F115252170034907237047%22%2C%22name%22%3A%22Corinne+Krych%22%2C%22picture%22%3A%22https%3A%2F%2Flh4.googleusercontent.com%2F-8kZ8Zhawc00%2FAAAAAAAAAAI%2FAAAAAAAAAFU%2FhHkWO2c8Wv4%2Fphoto.jpg%22%2C%22verified_email%22%3Atrue%7D&status=complete&result=success"
        // when
        let oauth = OAuthViewController()
        let result = try! oauth.processQuery(query)
        
        // assert
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.count == 4)
        XCTAssertTrue(result!["fh_auth_session"] as! String == "atmknuh4vclrft5d3emg2usv")
        XCTAssertTrue(result!["status"] as! String == "complete")
        XCTAssertTrue(result!["result"] as! String == "success")
        let claims = result!["authResponse"] as! [String: AnyObject]
        XCTAssertTrue(claims["family_name"] as! String == "Krych")
        XCTAssertTrue(claims["given_name"] as! String == "Corinne")
        XCTAssertTrue(claims["gender"] as! String == "female")
        XCTAssertTrue(claims["authToken"] as! String == "ya29..ugKxZiiNa9It6sFYXuy2Op5F58fiVXACzN-Dcm6tb38G-v2H6zW8lP-aV4y28sdF9DU")
    }
    
}