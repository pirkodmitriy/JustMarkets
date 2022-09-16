//
//  NetworkManager.swift
//  JustMarkets
//
//  Created by Dmitriy Pirko on 15.09.2022.
//

import Foundation
import Firebase

class NetworkManager {
    
    func getBaseURL() {
        setupRemoteConfigDefaults()
        fetchRemoteConfigDefaults()

    }
    
    private func setupRemoteConfigDefaults() {
        let defaultsValues = [
            "base_urls" : "[{\"DEV\":[\"https://justmarkets.com/\",\"https://iosjmdev9.justforex.net/\",\"https://justmarkets.com/\"],\"STABLE\":[\"https://ios.justforex.net/\"],\"PROD\":[\"https://ios.justforex.net/\"]}]" as NSObject,
            "forExternalOpens": "[{\"justmarkets.com\",\"justmarkets.biz\",\"justmarkets.asia\"}]" as NSObject
        ]
        RemoteConfig.remoteConfig().setDefaults(defaultsValues)
    }
    
    private func fetchRemoteConfigDefaults() {
        let debugSettings = RemoteConfigSettings()
        RemoteConfig.remoteConfig().configSettings = debugSettings
        RemoteConfig.remoteConfig().fetch(withExpirationDuration: 0) { status, error in
            guard error == nil else {
                print(error!)
                return
            }
            RemoteConfig.remoteConfig().activate { status, error in
                guard error == nil else {
                    print(error!)
                    return
                }
                
            }
        }
    }
    
}
