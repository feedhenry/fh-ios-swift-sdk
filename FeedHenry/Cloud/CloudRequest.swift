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
open class CloudRequest: Request {

    let path: String
    let args: [String:AnyObject]?
    let headers: [String:String]?
    let method: HTTPMethod
    var props: CloudProps
    var config: Config?
    let dataManager: UserDefaults
    
    public init(props: CloudProps, config: Config? = nil, path: String, method: HTTPMethod = .POST, args: [String:AnyObject]? = nil, headers: [String:String]? = nil, storage: UserDefaults = UserDefaults.standard) {
        self.path = path
        self.args = args
        self.headers = headers
        self.method = method
        self.props = props
        self.config = config
        self.dataManager = storage
    }
    
    open func exec(_ completionHandler: @escaping CompletionBlock) -> Void {
        let host = props.cloudHost
        var headers: [String: String]?
        if let sessionToken = dataManager.string(forKey: "sessionToken") {
            headers = ["x-fh-sessionToken": sessionToken]
        }
        if let props = config?.params {
            headers = headers ?? [:]
            for (key, value) in props {
                let fhKey = "x-fh-\(key)"
                if let value = value as? String {
                    headers![fhKey] = value
                } else { // apppend JSOnified version
                    do {
                        let json = try JSONSerialization.data(withJSONObject: value, options: JSONSerialization.WritingOptions())
                        let string = NSString(data: json, encoding: String.Encoding.utf8.rawValue)
                        headers![fhKey] = string as? String
                    } catch _ {}
                }
            }
        }
        request(method, host: host, path: path, args: args, headers: headers, completionHandler: completionHandler)
    }
}
