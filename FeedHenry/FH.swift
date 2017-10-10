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


let FH_SDK_VERSION = "5.0.5"

import Foundation
import AeroGearHttp
import Reachability
import AeroGearPush

public typealias CompletionBlock = (Response, NSError?) -> Void
/// HTTP standard methods.
public enum HTTPMethod: String {
    /// Http GET method.
    case GET = "GET"
    /// Http HEAD method.
    case HEAD = "HEAD"
    /// Http DELETE method.
    case DELETE = "DELETE"
    /// Http POST method.
    case POST = "POST"
    /// Http PUT method.
    case PUT = "PUT"
}
/**
 This class provides static methods to initialize the library and create new
 instances of all the API request objects.
 */
@objc(FH)
open class FH: NSObject {
    /// Properties is the returned object from a `FH.init` call when done successfully. It contains information like mbaas host name that are useful for FH.cloud call.
    static var props: CloudProps?
    /// Configuration object. Read form `fhconfig.plist` file.
    static var config: Config?
    /**
     Check if the device is online. The device is online if either WIFI or 3G
     network is available. Default value is true.

     - Returns: true if the device is online.
     */
    @objc
    open static var isOnline: Bool {
        guard let reachability = self.reachability else {return false}
        return reachability.isReachableViaWiFi || reachability.isReachableViaWWAN
    }

    /**
     If there was an error on FH.init it will be accessible from this method

     - Returns: the NSError from FH.init method.
     */
    open static var getInitError: NSError? {
        return initError
    }

    /// Boolean field to know if the reachability registration was done.
    static var initCalled: Bool = false
    /// Boolean field to indicate whether the app is online or offline.
    static var reachability: Reachability?

    /// NSError from FH.init method in case it fails
    static var initError: NSError? = nil

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

     - parameter completionHandler: InnerCompletionBlock is a closure wrap-up that throws errors in case of init failure. If no error, the inner closure returns a JSON Object containing all the details from the init call.
     - throws NSError: Networking issue details.
     - returns: Void
     */
    open class func `init`(_ completionHandler: @escaping CompletionBlock) -> Void {
        setup(config: Config(), completionHandler: completionHandler)
    }

    /**
     Create a new instance of CloudRequest class and execute it immediately
     with the completionHandler closure. The request runs asynchronously.

     - parameter path: The path of the cloud API
     - parameter method: The HTTP request method to use for the request. Defaulted to .POST.
     - parameter headers: The HTTP headers to use for the request. Can be nil. Defaulted to nil.
     - parameter args: The request body data. Can be nil. Defaulted to nil.
     - parameter completionHandler: Closure to be executed as a callback of http asynchronous call.
     */
    @objc
    open class func performCloudRequest(_ path: String,  method: String, headers: NSDictionary?, args: NSDictionary?, completionHandler: @escaping CompletionBlock) -> Void {
        guard let httpMethod = HTTPMethod(rawValue: method) else {return}
        assert(props != nil, "FH init must be done prior th a Cloud call")
        let cloudRequest = CloudRequest(props: self.props, config: self.config, path: path, method: httpMethod, args: args as? [String : AnyObject], headers: headers as? [String : String])
        cloudRequest.exec(completionHandler: completionHandler)
    }

    /**
     Create a new instance of CloudRequest class and execute it immediately
     with the completionHandler closure. The request runs asynchronously.

     - parameter path: The path of the cloud API
     - parameter method: The HTTP request method to use for the request. Defaulted to .POST.
     - parameter args: The request body data. Can be nil. Defaulted to nil.
     - parameter headers: The HTTP headers to use for the request. Can be nil. Defaulted to nil.
     - parameter completionHandler: Closure to be executed as a callback of http asynchronous call.
     */
    open class func cloud(path: String, method: HTTPMethod = .POST, args: [String: AnyObject]? = nil, headers: [String: String]? = nil, completionHandler: @escaping CompletionBlock) -> Void {
        let cloudRequest = CloudRequest(props: self.props, config: self.config, path: path, method: method, args: args, headers: headers)
        cloudRequest.exec(completionHandler: completionHandler)
    }

    /**
     Create a new instance of CloudRequest.

     - parameter path: The path of the cloud API
     - parameter method: The HTTP request method to use for the request. Defaulted to .POST.
     - parameter args: The request body data. Can be nil. Defaulted to nil.
     - parameter headers: The HTTP headers to use for the request. Can be nil. Defaulted to nil.
     */
    open class func cloudRequest(path: String, method: HTTPMethod = .POST, args:[String: AnyObject]? = nil, headers: [String: String]? = nil) -> CloudRequest {
        assert(props != nil, "FH init must be done prior th a Cloud call")
        return CloudRequest(props: self.props, config: self.config, path: path, method: method, args: args, headers: headers)
    }

    /**
     Private method called by `FH.init`.
     */
    class func setup(config: Config, completionHandler: @escaping CompletionBlock) -> Void {
        let initRequest = InitRequest(config: config)
        self.config = config
        initRequest.exec { (response: Response, error: NSError?) -> Void in
            if error == nil { // success
                self.props = initRequest.props
            }
            // register for reachability and retry init if it fails because of offline mode
            do {
                try reachabilityRegistration()
            } catch let error as NSError {
                let response = Response()
                response.error = error
                completionHandler(response, error)
            }

            initError = error

            // completion callback for success
            completionHandler(response, error)
        }
    }

    /**
     Register for reachability and retry init if it fails because of offline mode.
     */
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
    /**
     Register for remote notifications in AppDelegate's lifecycle method.

     - parameter application: the application parameter available in AppDelegate class.

     ```swift
     class AppDelegate: UIResponder, UIApplicationDelegate {
       func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FH.pushEnabledForRemoteNotification(application: application)
        return true
       }
     }
     ```
     */
    open class func pushEnabledForRemoteNotification(application: UIApplication) {
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        UIApplication.shared.registerForRemoteNotifications()
    }
    /**
     Register to AeroGear Unified Push Server. To be used in AppDelegate's lifecycle's method. `application(_, didRegisterForRemoteNotificationsWithDeviceToken:)`.

     - parameter application: the application parameter available in AppDelegate class.

     ```swift
     class AppDelegate: UIResponder, UIApplicationDelegate {
       func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
         FH.pushRegister(deviceToken: deviceToken, success: { res in
           print("Unified Push registration successful")
         }, error: {failed in
           print("Unified Push registration Error \(failed.error)")
         })
       }
     }
     ```
     */
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

    /**
     Utility method that registers to AeroGear Unified Push Server and configure an alias.

     - parameter alias: is a string to alias the device where to send push notifications.
     - parameter success: closure to run upon success of the push registration.
     - parameter error: closure to run unpon failure of push registration.
     */
    open class func setPush(alias: String, success: @escaping (Response) -> Void, error: @escaping (Response) -> Void) -> Void {
        let conf = PushConfig()
        conf.alias = alias
        pushRegister(deviceToken: nil, config: conf, success: success, error: error)
    }

    /**
     Utility method that registers to AeroGear Unified Push Server and configure an array list of categories.

     - parameter categories: NSArray
     - parameter success: (Response) -> ()
     - parameter error: (Response) -> ()
     */
    open class func setPush(categories: NSArray, success: @escaping (Response) -> Void, error: @escaping (Response) -> Void) -> Void {
        let conf = PushConfig()
        conf.categories = categories as? [String]
        pushRegister(deviceToken: nil, config: conf, success: success, error: error)
    }

    /**
     Send metrics to the AeroGear Push server when the app is launched due to a push notification.

     - parameter launchOptions: contains the message id used to collect metrics.
     */
    open class func sendMetricsWhenAppLaunched(launchOptions: [AnyHashable: Any]?) {
        PushAnalytics.sendMetricsWhenAppLaunched(launchOptions: launchOptions)
    }
    /**
     Send metrics to the AeroGear Push server when the app is brought from background to
     foreground due to a push notification.

     - parameter applicationState: to make sure the app was in background.
     - parameter userInfo: contains the message id used to collect metrics.
     */
    open class func sendMetricsWhenAppAwoken(applicationState: UIApplicationState, userInfo: [AnyHashable: Any]) {
        PushAnalytics.sendMetricsWhenAppAwoken(applicationState: applicationState, userInfo: userInfo)
    }

    /**
     Create a new instance of AuthRequest.

     - parameter policyId: The type of policy used in RHMAP platform. The string could be `FEEDHENRY`, `OAUTH2`, `MBAAS`.
     */
    class open func authRequest(_ policyId: String) -> AuthRequest {
        return AuthRequest(props: self.props!, config: Config(), method: .POST, policyId: policyId, headers: nil)
    }

    /**
     Call the auth remote service.

     - parameter policyId: The type of policy used in RHMAP platform. The string could be `FEEDHENRY`, `OAUTH2`, `MBAAS`.
     - parameter method: the type of http call: post, get...
     - parameter args: Http arguments. Default to nil.
     - parameter headers: Http headers. Default to nil.
     - parameter completionHandler: closure to run when the http call is completed. Error parameter should be tested to check for error.
     */
    class open func auth(policyId: String, method: HTTPMethod = .POST, args: [String: AnyObject]? = nil, headers: [String:String]? = nil, completionHandler: @escaping CompletionBlock) -> Void {
        let authRequest = AuthRequest(props: self.props!, config: Config(), method: .POST, policyId: policyId)
        authRequest.exec(completionHandler: completionHandler)
    }

    /**
     Call the auth remote service.

     - parameter policyId: The type of policy used in RHMAP platform. The string could be `FEEDHENRY`, `OAUTH2`, `MBAAS`.
     - parameter user: the username used for authentication.
     - parameter password: the password used for authentication.
     - parameter method: the type of http call: post, get...
     - parameter args: Http arguments. Default to nil.
     - parameter headers: Http headers. Default to nil.
     - parameter completionHandler: closure to run when the http call is completed. Error parameter should be tested to check for error.
     */
    class open func auth(policyId: String, userName: String, password: String, method: HTTPMethod = .POST, args: [String: AnyObject]? = nil, headers: [String:String]? = nil, completionHandler: @escaping CompletionBlock) -> Void {
        let authRequest = AuthRequest(props: self.props!, config: Config(), method: .POST, policyId: policyId, userName: userName, password: password)
        authRequest.exec(completionHandler: completionHandler)
    }
}
