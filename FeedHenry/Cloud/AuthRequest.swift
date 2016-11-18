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
open class AuthRequest: Request {
    let path: String
    let headers: [String: String]?
    let method: HTTPMethod
    var props: CloudProps
    var config: Config
    var args: [String: Any]? {
        get {
            var params: [String:Any]?
            if let appid = config["appid"] {
                params = ["policyId": self.policyId,
                    "device": config.uuid,
                    "clientToken": appid]
                var param: [String: Any]?
                if let userName = userName, let password = password {
                    param = ["userId": userName, "password": password]
                }
                params!["params"] = param as Any?
                if let env = props.env {
                    params!["environment"] = env as Any?
                }
            }
            
            return params
        }
    }
    let dataManager: UserDefaults
    fileprivate var policyId: String
    open var userName: String?
    open var password: String?
    open var parentViewController: UIViewController?
    
    open var sessionToken: String? {
        get {
            return dataManager.string(forKey: "sessionToken")
        }
        set {
            dataManager.set(newValue, forKey: "sessionToken")
        }
    }
    
    public init(props: CloudProps, config: Config, method: HTTPMethod = .POST, policyId: String, userName: String? = nil, password: String? = nil, headers: [String:String]? = nil, storage: UserDefaults = UserDefaults.standard) {
        self.path = "box/srv/1.1/admin/authpolicy/auth"
        self.headers = headers
        self.method = method
        self.props = props
        self.policyId = policyId
        self.config = config
        self.dataManager = storage
        self.userName = userName
        self.password = password
    }
    
    open func exec(completionHandler: @escaping CompletionBlock) -> Void {
        guard let host = config["host"] else {return}
        
        request(method: method, host: host, path: path, args: args, completionHandler: {(response: Response, error: NSError?) -> Void in
            if let error = error {
                print("AuthRequest::Error \(error)")
                let response = Response()
                response.error = error
                completionHandler(response, error)
                return
            }
            if let result = response.parsedResponse as? [String: Any] {
                if let status = result["status"] as? String, status == "ok" {
                    if let urlString = result["url"] as? String, let parent = self.parentViewController {
                        guard let url = URL(string: urlString) else {return}
                        let controller = OAuthViewController()
                        controller.url = url
                        controller.completionHandler = completionHandler
                        parent.present(controller, animated: true, completion: nil)
                    } else {
                        if let sessionTokenKey = result["sessionToken"] as? String {
                            self.sessionToken = sessionTokenKey
                        }
                        completionHandler(response, error)
                    }
                } else if let status = result["status"] as? String, status == "error" {
                    let message = result["message"] as? String
                    let response = Response()
                    let error = NSError(domain: "FeedHenryAuthError", code: 0, userInfo: [NSLocalizedDescriptionKey : message ?? ""])
                    response.error = error
                    completionHandler(response, error)
                }
            }
        })
    }
}
