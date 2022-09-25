//
//  ViewController.swift
//  JustMarkets
//
//  Created by Dmitriy Pirko on 13.09.2022.
//

import UIKit
import Firebase
import WebKit
import SystemConfiguration
import Network
import FirebaseAnalytics
import AppsFlyerLib

class LoginViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var errorLabel: UILabel!
    
    private let monitor = NWPathMonitor()
    private let networkManager = NetworkManager()
    private var currentOpenLink = 0
    private var isWebViewError = false
    private var baseURL = ""
    private var campList = String()
    private var analyticsData: [AnyHashable: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppsFlyerLib.shared().delegate = self
        self.webView.configuration.userContentController.add(self, name: "firebase")
        self.monitor.start(queue: .global())
        self.webView.isHidden = true
        self.errorLabel.isHidden = true
        self.logoAnimation()
        self.setupLanguage(language: "")
        self.getBaseURL()
    }
    
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
                if RemoteConfig.remoteConfig().configValue(forKey: "base_urls").stringValue! == "" {
                    self.setupRemoteConfigDefaults()
                }
                self.checkBaseURL {
                        print(HTTPCookieStorage.shared.cookies)
                    self.networkManager.checkLoginStatus(link: self.baseURL+self.networkManager.checkLoginStatusEndpoint, completion: { result in
                            if result {
                                DispatchQueue.main.async {
                                    self.openWebView(endPoint: self.networkManager.languageEndpoint+self.networkManager.loginEndpoint)
                                }
                            }
                        })
                }
            }
        }
    }
    
    func checkBaseURL(completion: @escaping () -> Void) {
        if monitor.currentPath.status == .satisfied {
            // Internet Connected
            let registerLinkString = RemoteConfig.remoteConfig().configValue(forKey: "base_urls").stringValue!
            let data = registerLinkString.data(using: .utf8)!
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [Dictionary<String,Any>] {
                    switch firebaseRemoteConfig {
                    case "DEV":
                        for i in jsonArray {
                            if var links = i["DEV"] as? Array<Any> {
                                links.reverse()
                                for link in links {
                                    if links.count > currentOpenLink {
                                        let group = DispatchGroup()
                                        group.enter()
                                        networkManager.checkWebsiteIsAvailable(link: link as! String) { result in
                                            if result {
                                                self.baseURL = link as! String
                                            } else {
                                                self.currentOpenLink += 1
                                            }
                                            group.leave()
                                        }
                                        group.wait()
                                    } else {
                                        self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                        self.isWebViewError = true
                                    }
                                }
                                if self.baseURL == "" {
                                    DispatchQueue.main.async {
                                        self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                        self.isWebViewError = true
                                    }
                                }
                            }
                        }
                    case "STABLE":
                        for i in jsonArray {
                            if var links = i["STABLE"] as? Array<Any> {
                                links.reverse()
                                for link in links {
                                    if links.count > currentOpenLink {
                                        let group = DispatchGroup()
                                        group.enter()
                                        networkManager.checkWebsiteIsAvailable(link: link as! String) { result in
                                            if result {
                                                self.baseURL = link as! String
                                            } else {
                                                self.currentOpenLink += 1
                                            }
                                            group.leave()
                                        }
                                        group.wait()
                                    } else {
                                        self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                        self.isWebViewError = true
                                    }
                                }
                                if self.baseURL == "" {
                                    DispatchQueue.main.async {
                                        self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                        self.isWebViewError = true
                                    }
                                }
                            }
                        }
                    case "PROD":
                        for i in jsonArray {
                            print(jsonArray)
                            if var links = i["PROD"] as? Array<Any> {
                                //links.reverse()
                                for var link in links {
                                    if links.count > currentOpenLink {
                                        let group = DispatchGroup()
                                        group.enter()
                                        networkManager.checkWebsiteIsAvailable(link: link as! String) { result in
                                            if result {
                                                self.baseURL = link as! String
                                            } else {
                                                self.currentOpenLink += 1
                                            }
                                            group.leave()
                                        }
                                        group.wait()
                                    } else {
                                        self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                        self.isWebViewError = true
                                    }
                                }
                                if self.baseURL == "" {
                                    DispatchQueue.main.async {
                                        self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                        self.isWebViewError = true
                                    }
                                }
                            }
                        }
                    default:
                        self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                        self.isWebViewError = true
                        
                    }
                } else {
                    print("bad json")
                    self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                    self.isWebViewError = true
                    self.webView.isHidden = true
                }
            } catch let error as NSError {
                print(error)
                self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                self.isWebViewError = true
                self.webView.isHidden = true
            }
        } else {
            self.errorLabel.text = "No internet connection. Connect and try again"
            self.isWebViewError = true
        }
        completion()
    }
    
    private func openWebView(endPoint: String) {
        if let url = URL(string: baseURL + endPoint) {
            print(url)
            self.webView.isHidden = false
            self.webView.navigationDelegate = self
            self.webView.uiDelegate = self
            self.webView.allowsBackForwardNavigationGestures = true
            let cookies = HTTPCookieStorage.shared.cookies ?? []
            for cookie in cookies {
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
            self.webView.load(URLRequest(url: url))
            self.errorLabel.isHidden = true
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController,
                             didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        guard let command = body["command"] as? String else { return }

        if command == "logout" {
            self.webView.isHidden = true
        } else if command == "changeLang" {
            guard let value = body["value"] as? String else { return }
            setupLanguage(language: value)
        } else if command == "copyToClipboard" {
            guard let value = body["value"] as? String else { return }
            UIPasteboard.general.string = value
        } else if command == "RegistrationSuccess" {
            guard let value = body["value"] as? String else { return }
            AppsFlyerLib.shared().logEvent(name: "RegistrationSuccess", values: ["USER_CODE": value], completionHandler: { (response: [String : Any]?, error: Error?) in
                         if let response = response {
                           print("In app event callback Success: ", response)
                         }
                         if let error = error {
                           print("In app event callback ERROR:", error)
                         }
                       })
        } else if command == "AuthSuccess" {
            guard let value = body["value"] as? String else { return }
            AppsFlyerLib.shared().logEvent(name: "AuthSuccess", values: ["USER_CODE": value], completionHandler: { (response: [String : Any]?, error: Error?) in
                         if let response = response {
                           print("In app event callback Success: ", response)
                         }
                         if let error = error {
                           print("In app event callback ERROR:", error)
                         }
                       })
        }
    }
    
    private func setupLanguage(language: String) {
        var locale = Locale.current.languageCode
        if language != "" {
            locale = language
        }
        switch locale {
        case "en":
            self.registerButton.titleLabel?.text = "Registration"
            self.loginButton.titleLabel?.text = "Log in"
        case "ar":
            self.registerButton.titleLabel?.text = "تسجيل الاشتراك"
            self.loginButton.titleLabel?.text = "تسجيل الدخول"
            networkManager.languageEndpoint = "ar/"
        case "bn":
            self.registerButton.titleLabel?.text = "নিবন্ধীকরণ"
            self.loginButton.titleLabel?.text = "লগ ইন"
            networkManager.languageEndpoint = "bn/"
        case "cn":
            self.registerButton.titleLabel?.text = "注册"
            self.loginButton.titleLabel?.text = "登录"
            networkManager.languageEndpoint = "cn/"
        case "es":
            self.registerButton.titleLabel?.text = "Registro"
            self.loginButton.titleLabel?.text = "Iniciar sesión"
            networkManager.languageEndpoint = "es/"
        case "fa":
            self.registerButton.titleLabel?.text = "ثبت نام"
            self.loginButton.titleLabel?.text = "ورود"
            networkManager.languageEndpoint = "fa/"
        case "fr":
            self.registerButton.titleLabel?.text = "Inscription"
            self.loginButton.titleLabel?.text = "Connexion"
            networkManager.languageEndpoint = "fr/"
        case "hi":
            self.registerButton.titleLabel?.text = "पंजीकरण"
            self.loginButton.titleLabel?.text = "लॉग-इन करें"
            networkManager.languageEndpoint = "hi/"
        case "id":
            self.registerButton.titleLabel?.text = "Pendaftaran"
            self.loginButton.titleLabel?.text = "Masuk"
            networkManager.languageEndpoint = "id/"
        case "jp":
            self.registerButton.titleLabel?.text = "登録"
            self.loginButton.titleLabel?.text = "ログイン"
            networkManager.languageEndpoint = "jp/"
        case "ko":
            self.registerButton.titleLabel?.text = "등록"
            self.loginButton.titleLabel?.text = "로그인"
            networkManager.languageEndpoint = "ko/"
        case "ms":
            self.registerButton.titleLabel?.text = "Pendaftaran"
            self.loginButton.titleLabel?.text = "Log masuk"
            networkManager.languageEndpoint = "ms/"
        case "pk":
            self.registerButton.titleLabel?.text = "رجسٹریشن"
            self.loginButton.titleLabel?.text = "لاگ ان"
            networkManager.languageEndpoint = "pk/"
        case "pt":
            self.registerButton.titleLabel?.text = "Cadastro"
            self.loginButton.titleLabel?.text = "Entrar"
            networkManager.languageEndpoint = "pt/"
        case "th":
            self.registerButton.titleLabel?.text = "การสมัคร"
            self.loginButton.titleLabel?.text = "ลงชื่อเข้าใช้"
            networkManager.languageEndpoint = "th/"
        case "tr":
            self.registerButton.titleLabel?.text = "Kayıt"
            self.loginButton.titleLabel?.text = "Giriş Yap"
            networkManager.languageEndpoint = "tr/"
        case "vi":
            self.registerButton.titleLabel?.text = "Đăng ký"
            self.loginButton.titleLabel?.text = "Đăng nhập"
            networkManager.languageEndpoint = "vi/"
        case "zh":
            self.registerButton.titleLabel?.text = "註冊"
            self.loginButton.titleLabel?.text = "登錄"
            networkManager.languageEndpoint = "zh/"
        case .none:
            self.registerButton.titleLabel?.text = "Registration"
            self.loginButton.titleLabel?.text = "Log in"
        case .some(_):
            self.registerButton.titleLabel?.text = "Registration"
            self.loginButton.titleLabel?.text = "Log in"
        }
    }

    private func logoAnimation() {
        //set items start positions
        self.logoImageView.transform = CGAffineTransform(translationX: 0, y: 600)
        self.registerButton.transform = CGAffineTransform(translationX: 0, y: 300)
        self.loginButton.transform = CGAffineTransform(translationX: 0, y: 200)
        //move items to end positions
        UIView.animate(withDuration: 2.0) {
            self.logoImageView.transform = CGAffineTransform(translationX: 0, y: 0)
            self.registerButton.transform = CGAffineTransform(translationX: 0, y: 0)
            self.loginButton.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    // OPEN EXTERNAL URSL IN BROWSER
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if let externals = RemoteConfig.remoteConfig().configValue(forKey: "forExternalOpens").jsonValue as? [String] {
                for i in externals {
                    if (webView.url!.absoluteString.contains(i)) {
                        UIApplication.shared.open(webView.url!)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.webView.isHidden = true
                        }
                        break
                    }
                }
            }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                    if webView.url!.absoluteString.contains("accounts") {
                        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
                        self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
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
                            }
                        }
                    }
        
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Show error view
        print(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Show error view
        print(error)
    }

    @IBAction func registerButtonAction(_ sender: Any) {
        if isWebViewError {
            errorLabel.isHidden = false
        } else {
            openWebView(endPoint: networkManager.languageEndpoint+networkManager.registrationEndpoint)
        }
    }
    
    @IBAction func loginButtonACtion(_ sender: Any) {
        if isWebViewError {
            errorLabel.isHidden = false
        } else {
            openWebView(endPoint: networkManager.languageEndpoint+networkManager.loginEndpoint)
        }
    }
    
}

extension LoginViewController: AppsFlyerLibDelegate {
    // Handle Organic/Non-organic installation
    func onConversionDataSuccess(_ installData: [AnyHashable: Any]) {
        
        if let status = installData["af_status"] as? String {
            if (status == "Non-organic") {
                if let sourceID = installData["media_source"],
                   let campaign = installData["campaign"] {
                    print("This is a Non-Organic install. Media source: \(sourceID)  Campaign: \(campaign)")
                    self.campList = "\(campaign)"
                }
            } else {
                print("This is an organic install.")
            }
            if let is_first_launch = installData["is_first_launch"] as? Bool,
               is_first_launch {
                print("First Launch")
            } else {
                print("Not First Launch")
            }
        }
        self.analyticsData = installData
        
        
    }
    func onConversionDataFail(_ error: Error) {
        
        print(error)
    }
    //Handle Deep Link
    func onAppOpenAttribution(_ attributionData: [AnyHashable : Any]) {
        //Handle Deep Link Data
        print("onAppOpenAttribution data:")
        for (key, value) in attributionData {
            
            print(key, ":",value)
        }
    }
    func onAppOpenAttributionFailure(_ error: Error) {
        
        print(error)
    }
    
}
