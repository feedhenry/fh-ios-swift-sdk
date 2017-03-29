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

/**
 Response Object that contains the Http response information.
 */
@objc(FHResponse)
open class Response: NSObject {
    /// Get the raw response data
    open var rawResponse: Data?
    
    /// Get the raw response data as String
    open var rawResponseAsString: String?
    
    /// Get the response data as NSDictionary
    open var parsedResponse: NSDictionary? 
    
    /// Get the response's status code
    open var responseStatusCode: Int?
    
    /// Get the error of the response
    open var error: NSError?
}
