//
//  NetworkManager.swift
//  JustMarkets
//
//  Created by Dmitriy Pirko on 15.09.2022.
//

import Foundation
import Firebase
import WebKit

class NetworkManager {
    
    var languageEndpoint = ""
    var registrationEndpoint = "registration/trader"
    var loginEndpoint = "login"
    var checkLoginStatusEndpoint = "graphql"
    
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
    
    func checkWebsiteIsAvailable(link: String, completion: @escaping (Bool) -> Void ) {
        guard let url = URL(string: link) else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 1.0

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
    
    func getWebViewCookies(link: String, completionHandler: @escaping () -> Void) {
        guard let url = URL(string: link) else { return }
        let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let url = response?.url,
                let httpResponse = response as? HTTPURLResponse,
                let fields = httpResponse.allHeaderFields as? [String: String]
                else { return }
        
            //            cok = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
            //            for i in cok {
            //                print(i)
            //            }
                        let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
                        HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
                        for cookie in cookies {
                            var cookieProperties = [HTTPCookiePropertyKey: Any]()
                            cookieProperties[.name] = cookie.name
                            cookieProperties[.value] = cookie.value
                            cookieProperties[.domain] = cookie.domain
                            cookieProperties[.path] = cookie.path
                            cookieProperties[.version] = cookie.version
                            cookieProperties[.expires] = Date().addingTimeInterval(31536000)
        
                            let newCookie = HTTPCookie(properties: cookieProperties)
                            HTTPCookieStorage.shared.setCookie(newCookie!)
        
                    //print("name: \(cookie.name) value: \(cookie.value)")
            }
            completionHandler()
        }
        task.resume()
    }
    
    func checkLoginStatus(link: String, completion: @escaping(Bool) -> Void) {
        guard let url = URL(string: link) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.0
        request.httpMethod = "POST"
        request.addValue("cookie from WebView", forHTTPHeaderField: "Accept-Language")
        DispatchQueue.main.async {
            request.setValue("\(String(describing: WKWebView().value(forKey: "userAgent")))", forHTTPHeaderField: "User-Agent")
        }
        let body = Data("operationName\":\"RefreshTokens\",\"variables\":{},\"extensions\":{},\"query\":\"mutation RefreshTokens {\n  refreshTokens { expiry }\n}".utf8)
        request.httpBody = body
        
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
    
}
