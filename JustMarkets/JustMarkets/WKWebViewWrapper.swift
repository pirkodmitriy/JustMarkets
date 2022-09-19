//
//  WKWebViewWrapper.swift
//  JustMarkets
//
//  Created by Dmitriy Pirko on 18.09.2022.
//

import Foundation
import WebKit

class WKWebViewWrapper: NSObject, WKScriptMessageHandler {
    
    var wkWebView : WKWebView
    
    let events = ["AndroidAnalytics.logout()", "AndroidAnalytics.changeLang(`lang`)"]
    
    var eventFunctions : Dictionary<String, (String)->Void> = Dictionary<String, (String)->Void>()

    init(forWebView webView : WKWebView){
        wkWebView = webView
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("fd")
    }
    
    func setUpPlayerAndEventDelegation(){
        let controller = WKUserContentController()
        wkWebView.configuration.userContentController = controller

        for eventname in events {
            controller.add(self, name: eventname)
            eventFunctions[eventname] = { _ in }
            wkWebView.evaluateJavaScript("$(#tyler_durden_image).on('imagechanged', function(event, isSuccess) { window.webkit.messageHandlers.\(eventname).postMessage(JSON.stringify(isSuccess)) }", completionHandler: nil)
        }
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
            if let contentBody = message.body as? String{
                if let eventFunction = eventFunctions[message.name]{
                    eventFunction(contentBody)
                }
            }
        }
    
}
