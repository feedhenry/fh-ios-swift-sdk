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
import AeroGearHttp

public typealias CompletionBlock = (Response, NSError?) -> Void

/*
This class provides static methods to initialize the library and create new
instances of all the API request objects.
*/
public class FH {
    static var props: CloudProps?
    
    /**
     Initialize the library.
     
     This must be called before any other API methods can be called. The
     initialization process runs asynchronously so that it won't block the main UI
     thread.
     
     You need to make sure it is successful before calling any other API methods. The
     best way to do is by catching the error that is thrown in case of failure to initialize.
     
     ```swift
     FH.init {(inner: () throws -> [String: AnyObject]?) -> Void in
     do {
     let result = try inner()
     print("initialized OK \(result)")
     } catch let error {
     print("FH init failed. Error = \(error)")
     }
     }
     ```
     
     - Param completionHandler: InnerCompletionBlock is a closure wrap-up that throws errors in case of init failure. If no error, the inner closure returns a JSON Object containing all the details from the init call.
     - Throws NSError: Networking issue details.
     - Returns: Void
     */
    public class func `init`(completionHandler: CompletionBlock) -> Void {
        setup(Config(), completionHandler: completionHandler)
    }
    
    public class func performCloudRequest(path: String,  method: String, headers: [String:String]?, args: [String: String]?, config: Config = Config(), completionHandler: CompletionBlock) -> Void {
        guard let httpMethod = HttpMethod(rawValue: method) else {return}
        assert(props != nil, "FH init must be done prior th a Cloud call")
        let host = props!.cloudHost
        request(httpMethod, host: host, path: path, config: config, completionHandler: completionHandler)
    }
    
    class func setup(config: Config, completionHandler: CompletionBlock) -> Void {
        assert(config["host"] != nil, "Property file fhconfig.plist must have 'host' defined.")
        let host = config["host"]!
        request(.POST, host: host, path: "/box/srv/1.1/app/init", config: config, completionHandler: { (response: Response, err: NSError?) -> Void in
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
    
    class func request(method: HttpMethod, host: String, path: String, config: Config, completionHandler: CompletionBlock) {
        // TODO register for Reachability
        // TODO check if online otherwise send error
        let http = Http(baseURL: host, sessionConfig: NSURLSessionConfiguration.defaultSessionConfiguration(),
            requestSerializer: JsonRequestSerializer(),
            responseSerializer: JsonResponseSerializer(response: { (data: NSData, status: Int) -> AnyObject? in
                    do {
                        let jsonResponse = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
                        let finalResponse = ["status": status, "data": jsonResponse]
                        return finalResponse
                    } catch _ {
                        return nil
                    }
                    
            }))
        
        let defaultParameters: [String: AnyObject]? = config.params
        // TODO set headers with appkey: is it needed??
        // FHHttpClient l52
        // [mutableHeaders setValue:apiKeyVal forKeyPath:@"x-fh-auth-app"];
        
        http.request(.POST, path: path, parameters: defaultParameters, completionHandler: {(response: AnyObject?, error: NSError?) -> Void in
            let fhResponse = Response()
            if let resp = response as? [String: AnyObject] {
                fhResponse.responseStatusCode = resp["status"] as? Int
                let data = try! NSJSONSerialization.dataWithJSONObject(resp["data"]!, options: .PrettyPrinted)
                fhResponse.rawResponseAsString = String(data: data, encoding: NSUTF8StringEncoding)
                fhResponse.rawResponse = data
                fhResponse.parsedResponse = resp["data"] as? NSDictionary
            }
            dispatch_async(dispatch_get_main_queue(), {
                if let error = error {
                    let customData = error.userInfo["CustomData"] as? [String: AnyObject]
                    if let errorData = customData { // Add more info in the error
                        let errorMessage = errorData["msg"] != nil ? errorData["msg"] : errorData["message"]
                        let errorToRethrow = NSError(domain: "FeedHenryHTTPRequestErrorDomain", code: error.code, userInfo: [NSLocalizedDescriptionKey : errorMessage!])
                        fhResponse.error = errorToRethrow;
                        fhResponse.responseStatusCode = error.code
                        if let statusCode = error.userInfo["StatusCode"] as? Int {
                            fhResponse.responseStatusCode = statusCode
                        }
                        completionHandler(fhResponse, errorToRethrow)
                    } else { // Send only http eror code/msg
                        completionHandler(fhResponse, error)
                    }
                } else {
                    // TODO set init/ready or use cloudProps being filled as an indicator the init happen
                    completionHandler(fhResponse, nil)
                }
            })
        })
    }
}