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


public protocol Request {
    func exec(completionHandler: CompletionBlock) -> Void
}
extension Request {
    func request(method: HttpMethod, host: String, path: String, args: [String: AnyObject]?, completionHandler: CompletionBlock) {
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
        
        // TODO set headers with appkey: is it needed??
        // FHHttpClient l52
        // [mutableHeaders setValue:apiKeyVal forKeyPath:@"x-fh-auth-app"];
        
        http.request(.POST, path: path, parameters: args, completionHandler: {(response: AnyObject?, error: NSError?) -> Void in
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
