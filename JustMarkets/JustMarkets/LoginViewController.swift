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

class LoginViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, WKDownloadDelegate {

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var errorLabel: UILabel!
    
    private let monitor = NWPathMonitor()
    var queue = DispatchQueue(label: "Monitor")
    private let networkManager = NetworkManager()
    private var currentOpenLink = 0
    private var isWebViewError = false
    private var baseURL = ""
    private var campList = String()
    private var analyticsData: [AnyHashable: Any]?
    private var userAgent: String!
    private var downloadedLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        userAgent = webView.value(forKey: "userAgent") as! String
        AppsFlyerLib.shared().delegate = self
        self.webView.configuration.userContentController.add(self, name: "firebase")
        self.setupLanguage(language: "")
        self.webView.isHidden = true
        self.errorLabel.isHidden = true
        self.logoAnimation()
        self.getBaseURL()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.isWebViewError = false
            } else {
                self.isWebViewError = true
                DispatchQueue.main.async {
                    self.errorLabel.text = "No internet connection. Connect and try again"
                }
            }
        }
        self.monitor.start(queue: queue)
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
                    self.networkManager.checkLoginStatus(link: self.baseURL+self.networkManager.checkLoginStatusEndpoint, userAgent: self.userAgent, completion: { result in
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
                            }
                        }
                        if self.baseURL == "" {
                            DispatchQueue.main.async {
                                self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                self.isWebViewError = true
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
                            }
                        }
                        if self.baseURL == "" {
                            DispatchQueue.main.async {
                                self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                self.isWebViewError = true
                            }
                        }
                    case "PROD":
                        for i in jsonArray {
                            print(jsonArray)
                            if let links = i["PROD"] as? Array<Any> {
                                //links.reverse()
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
                            }
                        }
                        if self.baseURL == "" {
                            DispatchQueue.main.async {
                                self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                self.isWebViewError = true
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
        var locale = String(Locale.preferredLanguages[0].prefix(2))
        if language != "" {
            locale = language
        }
        switch locale {
        case "en":
            self.registerButton.setTitle("Registration",for: .normal)
            self.loginButton.setTitle("Log in",for: .normal)
        case "ar":
            self.registerButton.setTitle("تسجيل الاشتراك",for: .normal)
            self.loginButton.setTitle("تسجيل الدخول",for: .normal)
            networkManager.languageEndpoint = "ar/"
        case "bn":
            self.registerButton.setTitle("নিবন্ধীকরণ",for: .normal)
            self.loginButton.setTitle("লগ ইন",for: .normal)
            networkManager.languageEndpoint = "bn/"
        case "cn":
            self.registerButton.setTitle("注册",for: .normal)
            self.loginButton.setTitle("登录",for: .normal)
            networkManager.languageEndpoint = "cn/"
        case "es":
            self.registerButton.setTitle("Registro",for: .normal)
            self.loginButton.setTitle("Iniciar sesión",for: .normal)
            networkManager.languageEndpoint = "es/"
        case "fa":
            self.registerButton.setTitle("ثبت نام",for: .normal)
            self.loginButton.setTitle("ورود",for: .normal)
            networkManager.languageEndpoint = "fa/"
        case "fr":
            self.registerButton.setTitle("Inscription",for: .normal)
            self.loginButton.setTitle("Connexion",for: .normal)
            networkManager.languageEndpoint = "fr/"
        case "hi":
            self.registerButton.setTitle("पंजीकरण",for: .normal)
            self.loginButton.setTitle("लॉग-इन करें",for: .normal)
            networkManager.languageEndpoint = "hi/"
        case "id":
            self.registerButton.setTitle("Pendaftaran",for: .normal)
            self.loginButton.setTitle("Masuk",for: .normal)
            networkManager.languageEndpoint = "id/"
        case "jp":
            self.registerButton.setTitle("登録",for: .normal)
            self.loginButton.setTitle("ログイン",for: .normal)
            networkManager.languageEndpoint = "jp/"
        case "ko":
            self.registerButton.setTitle("등록",for: .normal)
            self.loginButton.setTitle("로그인",for: .normal)
            networkManager.languageEndpoint = "ko/"
        case "ms":
            self.registerButton.setTitle("Pendaftaran",for: .normal)
            self.loginButton.setTitle("Log masuk",for: .normal)
            networkManager.languageEndpoint = "ms/"
        case "pk":
            self.registerButton.setTitle("رجسٹریشن",for: .normal)
            self.loginButton.setTitle("Log in",for: .normal)
            networkManager.languageEndpoint = "pk/"
        case "pt":
            self.registerButton.setTitle("Cadastro",for: .normal)
            self.loginButton.setTitle("Entrar",for: .normal)
            networkManager.languageEndpoint = "pt/"
        case "th":
            self.registerButton.setTitle("การสมัคร",for: .normal)
            self.loginButton.setTitle("ลงชื่อเข้าใช้",for: .normal)
            networkManager.languageEndpoint = "th/"
        case "tr":
            self.registerButton.setTitle("Kayıt",for: .normal)
            self.loginButton.setTitle("Giriş Yap",for: .normal)
            networkManager.languageEndpoint = "tr/"
        case "vi":
            self.registerButton.setTitle("Đăng ký",for: .normal)
            self.loginButton.setTitle("Đăng nhập",for: .normal)
            networkManager.languageEndpoint = "vi/"
        case "zh":
            self.registerButton.setTitle("註冊",for: .normal)
            self.loginButton.setTitle("登錄",for: .normal)
            networkManager.languageEndpoint = "zh/"
        default:
            self.registerButton.titleLabel?.text = "Registration"
            self.loginButton.titleLabel?.text = "Log in"
        }
    }

    private func logoAnimation() {
        //set items start positions
        self.logoImageView.transform = CGAffineTransform(translationX: 0, y: 0)
        self.registerButton.transform = CGAffineTransform(translationX: 0, y: 300)
        self.loginButton.transform = CGAffineTransform(translationX: 0, y: 200)
        //move items to end positions
        UIView.animate(withDuration: 2.0) {
            self.logoImageView.transform = CGAffineTransform(translationX: 0, y: -100)
            self.registerButton.transform = CGAffineTransform(translationX: 0, y: 0)
            self.loginButton.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    // OPEN EXTERNAL URSL IN BROWSER
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if let externals = RemoteConfig.remoteConfig().configValue(forKey: "forExternalOpens").jsonValue as? [String] {
                for i in externals {
                    if #available(iOS 16.0, *) {
                        if let domain = webView.url?.host() {
                            if domain == i {
                                UIApplication.shared.open(webView.url!)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    self.webView.goBack()
                                }
                                break
                            }
                        }
                    } else {
                        // Fallback on earlier versions
                        if let domain = webView.url?.host  {
                            if domain == i {
                                UIApplication.shared.open(webView.url!)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    self.webView.goBack()
                                }
                                break
                            }
                        }
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
//
//    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
//        let documentDirectory = FileManager.default.urls(for: .documentDirectory,
//                                                        in: .userDomainMask)[0]
//        let fileName = documentDirectory.appendingPathComponent(suggestedFilename)
//
//        if let urlString = response.url?.absoluteString {
//            if let fileUrl = URL(string: urlString) {
//                URLSession.shared.downloadTask(with: fileUrl) { (tempFileUrl, response, error) in
//                    if let imageTempFileUrl = tempFileUrl {
//                        do {
//                            // Write to file
//                            let fileData = try Data(contentsOf: imageTempFileUrl)
//                            try fileData.write(to: fileName)
//                        } catch {
//                            print("Error")
//                        }
//                    }
//                }.resume()
//            }
//        }
////        if let url = response.url {
////            FileDownloader.loadFileAsync(url: url) { (path, error) in
////                print("PDF File downloaded to : \(path!)")
////                completionHandler(url)
////            }
////        }
//    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download, preferences)
        } else {
            decisionHandler(.allow, preferences)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }
    
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self// your `WKDownloadDelegate`
    }
        
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self// your `WKDownloadDelegate`
    }
    
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory,
                                                         in: .userDomainMask).first
        let dataPath = documentDirectory?.appendingPathComponent(suggestedFilename)
        
        if #available(iOS 16.0, *) {
            let fileExists = FileManager().fileExists(atPath: dataPath!.path())
        } else {
            let fileExists = FileManager().fileExists(atPath: dataPath!.path)
            // Fallback on earlier versions
        }
        
        let destination = dataPath?.appendingPathExtension("/" + suggestedFilename)
        Downloader.load(url: response.url!, to: destination!)
        completionHandler(dataPath)
    }


    func downloadDidFinish(_ download: WKDownload) {
        print("downloaded")
        downloadedLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        downloadedLabel.center = self.webView.center
        downloadedLabel.text = "Downloaded to app folder"
        downloadedLabel.textColor = .red
        downloadedLabel.textAlignment = .center
        self.webView.addSubview(downloadedLabel)
        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
            self.downloadedLabel.removeFromSuperview()
        }
    }


    @IBAction func registerButtonAction(_ sender: Any) {
        if isWebViewError {
            errorLabel.isHidden = false
        } else {
            openWebView(endPoint: networkManager.languageEndpoint+networkManager.registrationEndpoint)
            errorLabel.isHidden = true
        }
    }
    
    @IBAction func loginButtonACtion(_ sender: Any) {
        if isWebViewError {
            errorLabel.isHidden = false
        } else {
            openWebView(endPoint: networkManager.languageEndpoint+networkManager.loginEndpoint)
            errorLabel.isHidden = true
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
