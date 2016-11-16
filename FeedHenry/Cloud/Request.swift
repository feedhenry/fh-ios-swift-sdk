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

let FHSDKNetworkOfflineErrorType = 1

public protocol Request {
    func exec(_ completionHandler: @escaping CompletionBlock) -> Void
}
extension Request {
    public func request(_ method: HTTPMethod, host: String, path: String, args: [String: AnyObject]?, headers: [String: String]? = nil, completionHandler: @escaping CompletionBlock) {
        let aerogearMethod = HttpMethod(rawValue: method.rawValue)!
        
        // Early catch of offline mode
        if FH.props != nil && FH.isOnline == false {
            let error = NSError(domain: "FHHttpClient", code: FHSDKNetworkOfflineErrorType, userInfo: [NSLocalizedDescriptionKey : "Offline mode", "error":"offline"])
            let response = Response()
            response.error = error
            completionHandler(response, error)
            return
        }
        
        let serializer = JsonRequestSerializer()
        serializer.headers = headers
        
        let http = Http(baseURL: host, sessionConfig: URLSessionConfiguration.default,
                        requestSerializer: serializer,
                        responseSerializer: JsonResponseSerializer(response: { (data: Data, status: Int) -> AnyObject? in
                            do {
                                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
                                let finalResponse = ["status": status, "data": jsonResponse]
                                return finalResponse as AnyObject?
                            } catch _ {
                                return nil
                            }
                            
                        }))        
        
        http.request(method: aerogearMethod, path: path, parameters: args, completionHandler: {(response: Any?, error: NSError?) -> Void in
            let fhResponse = Response()
            if let resp = response as? [String: AnyObject] {
                fhResponse.responseStatusCode = resp["status"] as? Int
                let data = try! JSONSerialization.data(withJSONObject: resp["data"]!, options: .prettyPrinted)
                fhResponse.rawResponseAsString = String(data: data, encoding: String.Encoding.utf8)
                fhResponse.rawResponse = data
                fhResponse.parsedResponse = resp["data"] as? NSDictionary
            }
            DispatchQueue.main.async(execute: {
                if let error = error {
                    let customData = error.userInfo["CustomData"] as? [String: Any]
                    if let errorData = customData { // Add more info in the error
                        let errorMessage = errorData["msg"] != nil ? errorData["msg"] : errorData["message"]
                        let errorToRethrow = NSError(domain: "FeedHenryHTTPRequestErrorDomain", code: error.code, userInfo: [NSLocalizedDescriptionKey : errorMessage ?? ""])
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
                    completionHandler(fhResponse, nil)
                }
            })
        })
    }
}
