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

    
    func checkWebsiteIsAvailable(link: String, completion: @escaping (Bool) -> Void ) {
        guard let url = URL(string: link) else { return }
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
    
    func checkLoginStatus(link: String, completion: @escaping(Bool) -> Void) {
        guard let url = URL(string: link) else { return }
        
        var refresh_token = ""
        let cookies = HTTPCookieStorage.shared.cookies!
        for cookie in cookies {
            if let name = cookie.value(forKey: "name") {
                if name as! String == "refresh_token" {
                    refresh_token = cookie.value(forKey: "value") as! String
                }
            }
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        request.httpMethod = "POST"
        request.setValue("content-type", forHTTPHeaderField: "application/json")
        request.setValue("Accept-Language", forHTTPHeaderField: "en")
        request.setValue("Cookie", forHTTPHeaderField: "last_locale=en;refresh_token=\(refresh_token)")
        DispatchQueue.main.async {
            request.setValue("\(String(describing: WKWebView().value(forKey: "userAgent")))", forHTTPHeaderField: "User-Agent")
        }
        let dataString = """
        [{"operationName":"\(refresh_token)","variables":{},"extensions":{},"query":"mutation RefreshTokens {\n  refreshTokens {\n    expiry\n  }\n}"}]
        """
        let body = Data(dataString.utf8)
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