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
Struct used to stored cloud properties after an initial setup.
Before any call to the cloud is done.
*/
public struct CloudProps {
    let dataManager: UserDefaults
    
    /// String that represents the Cloud URL to teraget for REST call.
    public let cloudHost: String
    
    /// Environment is optional.
    public let env: String?
    
    /// Set of all properties returned by cloud app endpoints.
    public let cloudProps: [String: AnyObject]
    
    /// Computed propertie retrieved from ```setup``` cloud init call. 
    /// It represents the Id of the handshake between client/cloud app.
    /// The trackId is stored in local storage.
    public var trackId: String? {
        get {
            return dataManager.string(forKey: "init")
        }
        set {
            dataManager.set(newValue, forKey: "init")
        }
    }
    
    /**
     Failable initializer for CloudProps. If the Cloud call returns a JSON missing hosts, environment or init (trackId), the init will fail.
     For a successful init, the CloudProps contains all properties required for subsequent call to cloud.
    
     - parameter props: List of properties returned from cloud app
     - parameter dataManager: Identifies where to store the trackId returned by the cloud app. This parameter is used for dependency injection for unit testing. Its default value is UserDefaults.standard storage.
   */
    public init?(props: [String: AnyObject], storage: UserDefaults = UserDefaults.standard) {
        guard let host = props["hosts"], let url = host["url"] as? String else {return nil}
        guard let initProp = props["init"], let track = initProp["trackId"] as? String else {return nil}
        env = host["environment"] as? String
        cloudHost = url.hasSuffix("/") ? url : "\(url)/"
        cloudProps = props
        dataManager = storage
        trackId = track
    }
}
