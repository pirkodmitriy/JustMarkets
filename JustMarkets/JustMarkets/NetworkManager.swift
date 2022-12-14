//
//  NetworkManager.swift
//  JustMarkets
//
//  Created by Dmitriy Pirko on 15.09.2022.
//

import Foundation
import Firebase
import WebKit

var checkWebsiteIsAvailableAnswer: Int!

class NetworkManager {
    
    var languageEndpoint = ""
    var registrationEndpoint = "registration/trader"
    var loginEndpoint = "login"
    var alreadyLoggedInEndpoint = "login"//"spa/account-operations/accounts"
    var checkLoginStatusEndpoint = "graphql"

    
    func checkWebsiteIsAvailable(link: String, completion: @escaping (Bool) -> Void ) {
        guard let url = URL(string: link) else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        
        request.timeoutInterval = 20.0

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("\(error.localizedDescription)")
                completion(false)
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("statusCode: \(httpResponse.statusCode)")
                // do your logic here
                if httpResponse.statusCode == 200 {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
        task.resume()
    }
    
    func checkLoginStatus(link: String, userAgent: String, completion: @escaping(Bool) -> Void) {
        guard var url = URL(string: link) else { return }
        
        let cookiesStorage = HTTPCookieStorage.shared
        let userDefaults = UserDefaults.standard

        if let cookieDictionary = userDefaults.dictionary(forKey: "cookies") {
            for (_, cookieProperties) in cookieDictionary {
                if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any] ) {
                    cookiesStorage.setCookie(cookie)
                }
            }
        }
        var refresh_token = ""
        let cookies = HTTPCookieStorage.shared.cookies!
        for cookie in cookies {
            if let name = cookie.value(forKey: "name") {
                if name as! String == "refresh_token" {
                    refresh_token = cookie.value(forKey: "value") as! String
                }
            }
        }
        
        if refresh_token != "" && refresh_token.count > 9 {
            completion(true)
//            var request = URLRequest(url: url)
//            request.timeoutInterval = 10.0
//            request.httpMethod = "POST"
//            request.setValue("Content-Type", forHTTPHeaderField: "application/json")
//            request.setValue("Cookie", forHTTPHeaderField: "refresh_token=\(refresh_token)")
//            DispatchQueue.main.async {
//                request.setValue("\(userAgent)", forHTTPHeaderField: "User-Agent")
//            }
//            var dataString = """
//        [{"operationName":"RefreshTokens","variables":{},"extensions":{},"query":"mutation RefreshTokens {\n  refreshTokens {\n    expiry\n  }\n}"}]
//        """
//
//            let jsonData = Data(dataString.utf8)
//            request.httpBody = jsonData
//
//            let task = URLSession.shared.dataTask(with: request) { data, response, error in
//                if let error = error {
//                    print("\(error.localizedDescription)")
//                    checkWebsiteIsAvailableAnswer = 0
//                    completion(false)
//                }
//                if let httpResponse = response as? HTTPURLResponse {
//                    if firebaseRemoteConfig == "DEV" {
//                        checkWebsiteIsAvailableAnswer = httpResponse.statusCode
//                    }
//                    print("statusCode: \(httpResponse.statusCode)")
//                    // do your logic here
//                    if httpResponse.statusCode == 200 {
//                        completion(true)
//                    } else {
//                        completion(false)
//                    }
//                }
//            }
//            task.resume()
        } else {
            completion(false)
        }
    }
    
}
