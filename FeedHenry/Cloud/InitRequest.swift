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

import Foundation

/*
This class provides the layer to do http request.
*/
public class InitRequest: Request {
    var config: Config
    public var props: CloudProps?
    let path: String
    let args: [String:AnyObject]?
    let headers: [String:String]?
    let method: HTTPMethod
    
    public init(config: Config) {
        self.path = "/box/srv/1.1/app/init"
        let defaultParameters: [String: AnyObject]? = config.params
        self.args = defaultParameters
        self.headers = nil
        self.method = .POST
        self.props = nil
        self.config = config
    }
    
    public func exec(_ completionHandler: @escaping CompletionBlock) -> Void {
        assert(config["host"] != nil, "Property file fhconfig.plist must have 'host' defined.")
        let host = config["host"]!
        
        request(method, host: host, path: path, args: args, completionHandler: { (response: Response, err: NSError?) -> Void in
            if let error = err {
                completionHandler(response, error)
                return
            }
            guard let resp = response.parsedResponse as? [String: AnyObject] else {
                let error = NSError(domain: "FeedHenryHTTPRequestErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid Response format. It must be JSON."])
                completionHandler(response, error)
                return
            }
            self.props = CloudProps(props: resp)
            completionHandler(response, err)
        })
    }
}
