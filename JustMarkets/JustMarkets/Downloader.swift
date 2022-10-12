//
//  Downloader.swift
//  JustMarkets
//
//  Created by Dmitriy Pirko on 12.10.2022.
//

import Foundation

class Downloader {
    class func load(url: URL, to localUrl: URL) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession (configuration: sessionConfig)
        var request = URLRequest (url: url)
        request.httpMethod = "GET"
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode) ")
                }
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                } catch (let writeError) {
                    print("error writing file \(localUrl) : \(writeError)")
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        task.resume ( )
    }
}
