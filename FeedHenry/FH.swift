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
import ReachabilitySwift
import AeroGearPush

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
@objc(FH)
open class FH: NSObject {
    /// Private field to be used to know id FH.init was done successfully. it replaces `ready` boolean in ObjC FH SDK
    static var props: CloudProps?
    static var config: Config?
    /**
     Check if the device is online. The device is online if either WIFI or 3G
     network is available. Default value is true.
     
     - Returns true if the device is online
     */
    open static var isOnline: Bool {
        guard let reachability = self.reachability else {return false}
        return reachability.isReachableViaWiFi || reachability.isReachableViaWWAN
    }
    
    /// Private field to know if the reachability registration was done.
    static var initCalled: Bool = false
    static var reachability: Reachability?
    
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
    open class func `init`(_ completionHandler: @escaping CompletionBlock) -> Void {
        setup(config: Config(), completionHandler: completionHandler)
    }
    
    /**
     Create a new instance of CloudRequest class and execute it immediately
     with the completionHandler closure. The request runs asynchronously.
     
     - Param path: The path of the cloud API
     - Param method: The HTTP request method to use for the request. Defaulted to .POST.
     - Param headers: The HTTP headers to use for the request. Can be nil. Defaulted to nil.
     - Param args: The request body data. Can be nil. Defaulted to nil.
     - Param completionHandler: Closure to be executed as a callback of http asynchronous call.
     */
    @objc
    open class func performCloudRequest(_ path: String,  method: String, headers: NSDictionary?, args: NSDictionary?, completionHandler: @escaping CompletionBlock) -> Void {
        guard let httpMethod = HTTPMethod(rawValue: method) else {return}
        assert(props != nil, "FH init must be done prior th a Cloud call")
        let cloudRequest = CloudRequest(props: self.props!, config: self.config, path: path, method: httpMethod, args: args as? [String : AnyObject], headers: headers as? [String : String])
        cloudRequest.exec(completionHandler: completionHandler)
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
    open class func cloud(path: String, method: HTTPMethod = .POST, args: [String: AnyObject]? = nil, headers: [String: String]? = nil, completionHandler: @escaping CompletionBlock) -> Void {
        let cloudRequest = CloudRequest(props: self.props!, config: self.config, path: path, method: method, args: args, headers: headers)
        cloudRequest.exec(completionHandler: completionHandler)
    }
    
    /**
     Create a new instance of CloudRequest.
     
     - Param path: The path of the cloud API
     - Param method: The HTTP request method to use for the request. Defaulted to .POST.
     - Param args: The request body data. Can be nil. Defaulted to nil.
     - Param headers: The HTTP headers to use for the request. Can be nil. Defaulted to nil.
     */
    open class func cloudRequest(path: String, method: HTTPMethod = .POST, args:[String: AnyObject]? = nil, headers: [String: String]? = nil) -> CloudRequest {
        assert(props != nil, "FH init must be done prior th a Cloud call")
        return CloudRequest(props: self.props!, config: self.config, path: path, method: method, args: args, headers: headers)
    }
    
    class func setup(config: Config, completionHandler: @escaping CompletionBlock) -> Void {
        let initRequest = InitRequest(config: config)
        self.config = config
        initRequest.exec { (response: Response, error: NSError?) -> Void in
            if error == nil { // success
                self.props = initRequest.props
            }
            // register for reachability and rety init if it fails because of offline mode
            do {
                try reachabilityRegistration()
            } catch let error as NSError {
                let response = Response()
                response.error = error
                completionHandler(response, error)
            }
            // complet callback for success
            completionHandler(response, error)
        }
    }
    
    // register for reachability and rety init if it fails because of offline mode
    class func reachabilityRegistration() throws -> Void {
        if initCalled == false {
            
            if reachability == nil {
                reachability = Reachability()!
            }

            do {
                try reachability!.startNotifier()
                initCalled = true
            } catch {
                let error = NSError(domain: "FeedHenryInitErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey : "Unable to start Reachability notifier"])
                throw error
            }
        }
    }
    
    open class func pushEnabledForRemoteNotification(application: UIApplication) {
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    open class func pushRegister(deviceToken: Data?, config: PushConfig? = nil, success: @escaping (Response) -> Void, error: @escaping (Response) -> Void) -> Void {
        let registration = DeviceRegistration(config: "fhconfig")
        if let host = Config.instance["host"] {
            let baseURL = "\(host)/api/v2/ag-push"
            registration.override(pushProperties: ["serverURL" : baseURL])
        }
        registration.register(clientInfo: { (clientDevice: ClientDeviceInformation!) in
            clientDevice.deviceToken = deviceToken
            guard let config = config else {return}
            clientDevice.alias = config.alias
            clientDevice.categories = config.categories
            },
                                            success: {
                                                success(Response())
            },
                                            failure: {(err: NSError) -> Void in
                                                let response = Response()
                                                response.error = err
                                                error(response)
        })
    }
    
    open class func setPush(alias: String, success: @escaping (Response) -> Void, error: @escaping (Response) -> Void) -> Void {
        let conf = PushConfig()
        conf.alias = alias
        pushRegister(deviceToken: nil, config: conf, success: success, error: error)
    }
    
    open class func setPush(categories: NSArray, success: @escaping (Response) -> Void, error: @escaping (Response) -> Void) -> Void {
        let conf = PushConfig()
        conf.categories = categories as? [String]
        pushRegister(deviceToken: nil, config: conf, success: success, error: error)
    }
    
    open class func sendMetricsWhenAppLaunched(launchOptions: [AnyHashable: Any]?) {
        PushAnalytics.sendMetricsWhenAppLaunched(launchOptions: launchOptions)
    }
    
    open class func sendMetricsWhenAppAwoken(applicationState: UIApplicationState, userInfo: [AnyHashable: Any]) {
        PushAnalytics.sendMetricsWhenAppAwoken(applicationState: applicationState, userInfo: userInfo)
    }
    
    class open func authRequest(_ policyId: String) -> AuthRequest {
        return AuthRequest(props: self.props!, config: Config(), method: .POST, policyId: policyId, headers: nil)
    }
    
    class open func auth(policyId: String, method: HTTPMethod = .POST, args: [String: AnyObject]? = nil, headers: [String:String]? = nil, completionHandler: @escaping CompletionBlock) -> Void {
        let authRequest = AuthRequest(props: self.props!, config: Config(), method: .POST, policyId: policyId)
        authRequest.exec(completionHandler: completionHandler)
    }
    
    class open func auth(policyId: String, userName:String, password: String, method: HTTPMethod = .POST, args: [String: AnyObject]? = nil, headers: [String:String]? = nil, completionHandler: @escaping CompletionBlock) -> Void {
        let authRequest = AuthRequest(props: self.props!, config: Config(), method: .POST, policyId: policyId, userName: userName, password: password)
        authRequest.exec(completionHandler: completionHandler)
    }
}
