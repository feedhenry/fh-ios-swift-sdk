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
public class CloudRequest: Request {
    let path: String
    let args: [String:AnyObject]?
    let headers: [String:String]?
    let method: HTTPMethod
    var props: CloudProps
    let dataManager: NSUserDefaults
    
    public init(props: CloudProps, path: String, method: HTTPMethod = .POST, args: [String:AnyObject]? = nil, headers: [String:String]? = nil, storage: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.path = path
        self.args = args
        self.headers = headers
        self.method = method
        self.props = props
        self.dataManager = storage
    }
    
    public func exec(completionHandler: CompletionBlock) -> Void {
        let host = props.cloudHost
        var headers: [String: String]?
        if let sessionToken = dataManager.stringForKey("sessionToken") {
            headers = ["x-fh-sessionToken":sessionToken]
        }
        request(method, host: host, path: path, args: args, headers: headers, completionHandler: completionHandler)
    }
}
