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


let FH_SDK_VERSION = "4.0.0-alpha.1"

import Foundation
import AeroGearHttp

public typealias CompletionBlock = (Response, NSError?) -> Void
public enum HTTPMethod: String {
    case GET = "GET"
    case HEAD = "HEAD"
    case DELETE = "DELETE"
    case POST = "POST"
    case PUT = "PUT"
}
/*
This class provides static methods to initialize the library and create new
instances of all the API request objects.
*/
public class FH {
    static var props: CloudProps?
    
    /** 
     Check if the device is online. The device is online if either WIFI or 3G
     network is available.
     
     - Returns true if the device is online
     */
    static var isOnline: Bool = false
    
    /**
     Initialize the library.
     
     This must be called before any other API methods can be called. The
     initialization process runs asynchronously so that it won't block the main UI
     thread.
     
     You need to make sure it is successful before calling any other API methods. The
     best way to do is by catching the error that is thrown in case of failure to initialize.
     
     ```swift
     FH.init { (resp:Response, error: NSError?) -> Void in
       if let error = error {
         self.statusLabel.text = "FH init in error"
         print("Error: \(error)")
         return
       }
       self.statusLabel.text = "FH init successful"
       FH.cloud("hello", completionHandler: { (response: Response, error: NSError?) -> Void in
         if let error = error {
           print("Error: \(error)")
           return
         }
         print("Response from Cloud Call: \(response.parsedResponse)")
       })
       print("Response: \(resp.parsedResponse)")
     }
     ```
     
     - Param completionHandler: InnerCompletionBlock is a closure wrap-up that throws errors in case of init failure. If no error, the inner closure returns a JSON Object containing all the details from the init call.
     - Throws NSError: Networking issue details.
     - Returns: Void
     */
    public class func `init`(completionHandler: CompletionBlock) -> Void {
        setup(Config(), completionHandler: completionHandler)
    }
    
    // TODO: remove?
    /**
    Create a new instance of CloudRequest class and execute it immediately
    with the completionHandler closure. The request runs asynchronously.
    
    - Param path: The path of the cloud API
    - Param method: The HTTP request method to use for the request. Defaulted to .POST.
    - Param headers: The HTTP headers to use for the request. Can be nil. Defaulted to nil.
    - Param args: The request body data. Can be nil. Defaulted to nil.
    - Param completionHandler: Closure to be executed as a callback of http asynchronous call.
    */
    public class func performCloudRequest(path: String,  method: String, headers: [String:String]?, args: [String: String]?, completionHandler: CompletionBlock) -> Void {
        guard let httpMethod = HTTPMethod(rawValue: method) else {return}
        assert(props != nil, "FH init must be done prior th a Cloud call")
        let cloudRequest = CloudRequest(props: self.props!, path: path, method: httpMethod, args: args, headers: headers)
        cloudRequest.exec(completionHandler)
    }
    
    /** 
     Create a new instance of CloudRequest class and execute it immediately
     with the completionHandler closure. The request runs asynchronously.
     
     - Param path: The path of the cloud API
     - Param method: The HTTP request method to use for the request. Defaulted to .POST.
     - Param args: The request body data. Can be nil. Defaulted to nil.
     - Param headers: The HTTP headers to use for the request. Can be nil. Defaulted to nil.
     - Param completionHandler: Closure to be executed as a callback of http asynchronous call.
     */
    public class func cloud(path: String, method: HTTPMethod = .POST, args: [String: String]? = nil, headers: [String:String]? = nil, completionHandler: CompletionBlock) -> Void {
        let cloudRequest = CloudRequest(props: self.props!, path: path, method: method, args: args, headers: headers)
        cloudRequest.exec(completionHandler)
    }
    
    /**
     Create a new instance of CloudRequest.
     
     - Param path: The path of the cloud API
     - Param method: The HTTP request method to use for the request. Defaulted to .POST.
     - Param args: The request body data. Can be nil. Defaulted to nil.
     - Param headers: The HTTP headers to use for the request. Can be nil. Defaulted to nil.
     */
    public class func cloudRequest(path: String, method: HTTPMethod = .POST, args:[String: String]? = nil, headers: [String:String]? = nil) -> CloudRequest {
        assert(props != nil, "FH init must be done prior th a Cloud call")
        return CloudRequest(props: self.props!, path: path, method: method, args: args, headers: headers)
    }
    
    class func setup(config: Config, completionHandler: CompletionBlock) -> Void {
        let initRequest = InitRequest(config: config)
        initRequest.exec { (response: Response, error: NSError?) -> Void in
            if error == nil {// success
                self.props = initRequest.props
            }
            completionHandler(response, error)
        }
    }

}
