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

public class Config {
    let dataManager: NSUserDefaults
    var properties: [String: String]
    let propertiesFile: String
    var bundle: NSBundle
    public static var instance = Config()
    
    init(propertiesFile: String = "fhconfig", bundle:NSBundle, storage: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
        self.propertiesFile = propertiesFile
        self.bundle = bundle
        let pathBundle = bundle.pathForResource(propertiesFile, ofType: "plist")
        dataManager = storage
        if let path = pathBundle, properties = NSDictionary(contentsOfFile: path) {
            self.properties = properties as! [String : String]
        } else {
            self.properties = [:]
        }
    }
    
    public convenience init(propertiesFile: String = "fhconfig") {
        self.init(propertiesFile: propertiesFile, bundle: NSBundle.mainBundle())
    }
    
    public subscript(key: String) -> String? {
        get {
            guard let property = properties[key] else {return nil}
            return property == "" ? nil : property
        }
        set {
            self.properties[key] = newValue
        }
    }
    
    public var params: [String: AnyObject] {
        var params: [String: AnyObject] = [:]
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
    
    public var sessionToken: String? {
        get {
            return dataManager.stringForKey("sessionToken")
        }
        set {
            dataManager.setObject(newValue, forKey: "sessionToken")
        }
    }
    
    public var uuid: String {
        get {
            if let uuid = dataManager.stringForKey("FHUUID") {
                return uuid
            }
            let uuid = NSUUID().UUIDString
            dataManager.setObject(uuid, forKey: "FHUUID")
            
            return uuid
        }
    }
    
    public var vendorId: String? {
        if let vendorId = UIDevice.currentDevice().identifierForVendor {
            return vendorId.UUIDString
        }
        return nil
    }
}
