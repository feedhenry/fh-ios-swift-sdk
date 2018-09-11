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
 Config contains the setting available in `fhconfig.plist`, populated by customers or by RHMAP platform at project creation.
 */
open class Config {
    let dataManager: UserDefaults
    var properties: [String: String]
    let propertiesFile: String
    var bundle: Bundle
    /// Singleton instance.
    open static var instance = Config()
    
    /**
     Constructor.
     
     - parameter propertiesFile: the name of the file, defaulted to `fhconfig.plist`.
     - parameter bundle: which bundle to find the file.
     - parameter storage: where to store the config and the cloud properties info. Defaulted to UserDefaults.standard.
     */
    init(propertiesFile: String = "fhconfig", bundle:Bundle, storage: UserDefaults = UserDefaults.standard, customProperties: [String : String] = [:]) {
        self.propertiesFile = propertiesFile
        self.bundle = bundle
        let pathBundle = bundle.path(forResource: propertiesFile, ofType: "plist")
        dataManager = storage
        if let path = pathBundle, let properties = NSDictionary(contentsOfFile: path) {
            self.properties = properties as! [String : String]
        } else {
            self.properties = [:]
        }
        self.properties.merge(customProperties);
    }
    
    /**
     Convenience constructor.
     
     - parameter propertiesFile: the name of the file, defaulted to `fhconfig.plist`.
     */
    public convenience init(propertiesFile: String = "fhconfig") {
        self.init(propertiesFile: propertiesFile, bundle: Bundle.main)
    }
    
    /**
     Subscript operator's overload to access cloud properties returned after a `FH.init` call.
     */
    open subscript(key: String) -> String? {
        get {
            guard let property = properties[key] else {return nil}
            return property == "" ? nil : property
        }
        set {
            self.properties[key] = newValue
        }
    }
    
    /**
     Parameters used for `FH.init` call.
     */
    open var params: [String: Any] {
        var params: [String: Any] = [:]
        params["appid"] = self["appid"]
        params["appkey"] = self["appkey"]
        params["projectid"] = self["projectid"]
        params["connectiontag"] = self["connectiontag"]
        params["sdk_version"] = self["FH_IOS_SDK/\(FH_SDK_VERSION)"]
        params["destination"] = "ios"
        let uuidGenerated = uuid
        params["cuid"] = uuidGenerated
        
        var cuidArray: [[String: String]] = [["name": "CFUUID",
                                              "cuid": uuidGenerated]]
        var vendorMap = ["name": "vendorIdentifier"]
        if let vendorId = vendorId {
            vendorMap["cuid"] = vendorId
        }
        cuidArray.append(vendorMap)
        
        params["cuidMap"] = cuidArray
        
        if let sessionToken = sessionToken {
            params["sessionToken"] = sessionToken
        }
        return params
    }
    
    /**
     Store the token used for Auth.
     */
    open var sessionToken: String? {
        get {
            return dataManager.string(forKey: "sessionToken")
        }
        set {
            dataManager.set(newValue, forKey: "sessionToken")
        }
    }
    
    /**
     The unique UUID of the device.
     */
    open var uuid: String {
        get {
            if let uuid = dataManager.string(forKey: "FHUUID") {
                return uuid
            }
            let uuid = UUID().uuidString
            dataManager.set(uuid, forKey: "FHUUID")
            
            return uuid
        }
    }
    
    /**
     An alphanumeric string that uniquely identifies a device to the app's vendor.
     */
    open var vendorId: String? {
        if let vendorId = UIDevice.current.identifierForVendor {
            return vendorId.uuidString
        }
        return nil
    }
}
