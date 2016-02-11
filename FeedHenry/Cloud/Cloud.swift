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

//public typealias CompletionBlock = (AnyObject?, NSError?) -> Void
public typealias InnerCompletionBlock = (() throws -> Response) -> Void

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
    public class func `init`(completionHandler: (InnerCompletionBlock)) -> Void {
        setup(Config(), completionHandler: completionHandler)
    }
    
    class func setup(config: Config, completionHandler: (InnerCompletionBlock)) -> Void {
        // TODO register for Reachability
        // TODO check if online otherwise send error
        assert(config["host"] != nil, "Property file fhconfig.plist must have 'host' defined.")
        let http = Http(baseURL: config["host"]!)
        let defaultParameters: [String: AnyObject]? = config.params
        // TODO set headers with appkey: is it needed??
        // FHHttpClient l52
        // [mutableHeaders setValue:apiKeyVal forKeyPath:@"x-fh-auth-app"];
        
        // customize jsonSerializer
        let responseSerializer = JsonResponseSerializer(validateResponse: { (response: NSURLResponse!, data: NSData) -> Void in
            var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
            let httpResponse = response as! NSHTTPURLResponse
            let dataAsJson: [String: AnyObject]?
            
            // validate JSON
            do {
                dataAsJson = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [String: AnyObject]
            } catch  _  {
                let userInfo = [NSLocalizedDescriptionKey: "Invalid response received, can't parse JSON" as NSString,
                    NetworkingOperationFailingURLResponseErrorKey: response]
                let customError = NSError(domain: HttpResponseSerializationErrorDomain, code: NSURLErrorBadServerResponse, userInfo: userInfo)
                throw customError;
            }
            
            if !(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                var userInfo = [NSLocalizedDescriptionKey: NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode),
                    NetworkingOperationFailingURLResponseErrorKey: response]
                if let dataAsJson = dataAsJson {
                    userInfo["CustomData"] = dataAsJson
                }
                error = NSError(domain: HttpResponseSerializationErrorDomain, code: httpResponse.statusCode, userInfo: userInfo)
                throw error
            }
            
        })
        
        http.POST("/box/srv/1.1/app/init", parameters: defaultParameters, credential: nil, responseSerializer: responseSerializer, completionHandler: {(response: AnyObject?, error: NSError?) -> Void in
            let fhResponse = Response()
            if let resp = response as? [String: AnyObject] {
                fhResponse.responseStatusCode = 200 //TODO
                let data = try! NSJSONSerialization.dataWithJSONObject(resp, options: .PrettyPrinted)
                fhResponse.rawResponseAsString = String(data: data, encoding: NSUTF8StringEncoding)
                fhResponse.rawResponse = data
                fhResponse.parsedResponse = resp
            }
            dispatch_async(dispatch_get_main_queue(), {
                if let error = error {
                    let customData = error.userInfo["CustomData"] as? [String: AnyObject]
                    if let errorData = customData { // Add more info in the error
                        let errorMessage = errorData["msg"] != nil ? errorData["msg"] : errorData["message"]
                        let errorToRethrow = NSError(domain: "FeedHenryHTTPRequestErrorDomain", code: error.code, userInfo: [NSLocalizedDescriptionKey : errorMessage!])
                        fhResponse.error = errorToRethrow;
                        fhResponse.responseStatusCode = error.code
                        completionHandler({throw errorToRethrow})
                    } else { // Send only http eror code/msg
                        completionHandler({throw error})
                    }
                } else {
                    if let resp = response as? [String: AnyObject] {
                        props = CloudProps(props: resp)
                    }
                    completionHandler({return fhResponse})
                }
            })
        })
    }
    
    public class func performCloud(path: String, completionHandler: InnerCompletionBlock) {
        
    }
}
