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

open class Config {
    let dataManager: UserDefaults
    var properties: [String: String]
    let propertiesFile: String
    var bundle: Bundle
    open static var instance = Config()
    
    init(propertiesFile: String = "fhconfig", bundle:Bundle, storage: UserDefaults = UserDefaults.standard) {
        self.propertiesFile = propertiesFile
        self.bundle = bundle
        let pathBundle = bundle.path(forResource: propertiesFile, ofType: "plist")
        dataManager = storage
        if let path = pathBundle, let properties = NSDictionary(contentsOfFile: path) {
            self.properties = properties as! [String : String]
        } else {
            self.properties = [:]
        }
    }
    
    public convenience init(propertiesFile: String = "fhconfig") {
        self.init(propertiesFile: propertiesFile, bundle: Bundle.main)
    }
    
    open subscript(key: String) -> String? {
        get {
            guard let property = properties[key] else {return nil}
            return property == "" ? nil : property
        }
        set {
            self.properties[key] = newValue
        }
    }
    
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
    
    open var sessionToken: String? {
        get {
            return dataManager.string(forKey: "sessionToken")
        }
        set {
            dataManager.set(newValue, forKey: "sessionToken")
        }
    }
    
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
    
    open var vendorId: String? {
        if let vendorId = UIDevice.current.identifierForVendor {
            return vendorId.uuidString
        }
        return nil
    }
}
