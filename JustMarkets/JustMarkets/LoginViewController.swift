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
import AdSupport

class LoginViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, WKDownloadDelegate, UIScrollViewDelegate {

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
        self.webView.scrollView.delegate = self
        self.setupLanguage(language: "")
        self.webView.isHidden = true
        self.errorLabel.isHidden = true
        self.loginButton.isHidden = true
        self.registerButton.isHidden = true
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
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    func getBaseURL() {
        setupRemoteConfigDefaults()
        fetchRemoteConfigDefaults()
    }
    
    private func setupRemoteConfigDefaults() {
        let defaultsValues = [
            "base_urls" : "[{\"DEV\":[\"https://ios.jmarkets.net/\"]" as NSObject,
            "forExternalOpens": "[{\"justmarkets.com\",\"justmarkets.biz\",\"justmarkets.asia\",\"justmarkets-idn.com\"}]" as NSObject
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
//                            DispatchQueue.main.async {
//                                let alert = UIAlertController(title: "Status Code", message: "\(checkWebsiteIsAvailableAnswer ?? 0)", preferredStyle: UIAlertController.Style.alert)
//                                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
//                                self.present(alert, animated: true, completion: nil)
//                            }
                            //
//                            if firebaseRemoteConfig == "DEV" && isTokenDebug {
//                                let cookies = HTTPCookieStorage.shared.cookies!
//                                for cookie in cookies {
//                                    if cookie.name == "refresh_token" || cookie.name == "_fx_frontend_session" {
//                                        DispatchQueue.main.async {
//                                            let alert = UIAlertController(title: "\(cookie.name)", message: "\(cookie.domain) : \(cookie.value)", preferredStyle: UIAlertController.Style.alert)
//                                            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
//                                            self.present(alert, animated: true, completion: nil)
//                                        }
//                                    }
//                                }
//                            }
                            //
                            if result {
                                DispatchQueue.main.async {
                                    self.openWebView(endPoint: self.networkManager.languageEndpoint+self.networkManager.alreadyLoggedInEndpoint)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.logoAnimation()
                                }
                            }
                        })
                    }
                }
            }
    }
    
    private func fetchRemoteConfigDefaultsLoggedIn(openType: String) {
        if monitor.currentPath.status == .satisfied {
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
                        DispatchQueue.main.async {
                            if openType == "login" {
                                if self.isWebViewError {
                                    self.errorLabel.isHidden = false
                                } else {
                                    self.openWebView(endPoint: self.networkManager.languageEndpoint+self.networkManager.loginEndpoint)
                                    self.errorLabel.isHidden = true
                                }
                                
                            } else {
                                if self.isWebViewError {
                                    self.errorLabel.isHidden = false
                                } else {
                                    self.openWebView(endPoint: self.networkManager.languageEndpoint+self.networkManager.registrationEndpoint)
                                    self.errorLabel.isHidden = true
                                }
                            }
                        }
                    }
                }
            }
        } else {
            self.errorLabel.text = "No internet connection. Connect and try again"
            self.isWebViewError = true
            self.errorLabel.isHidden = false
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
                                self.currentOpenLink = 0
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
                                self.currentOpenLink = 0
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
                            if var links = i["PROD"] as? Array<Any> {
                                links.reverse()
                                self.currentOpenLink = 0
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
    
//    func addCustomCookiesToCookieStorage() {
//        var cookies: [HTTPCookie] = []
//
//
//        for i in cookies{
//            HTTPCookieStorage.shared.cookies?.append(i)//.append(i)
//        }
//    }
    
    private func openWebView(endPoint: String) {
        if let url = URL(string: baseURL + endPoint) {
            print(url)
            self.webView.isHidden = false
            self.webView.navigationDelegate = self
            self.webView.uiDelegate = self
            self.webView.allowsBackForwardNavigationGestures = true
            var cookies = HTTPCookieStorage.shared.cookies ?? []
            
            let AppsFlyerUid = HTTPCookie(properties: [
                .domain: "\(self.baseURL)",
                .path: "/",
                .name: "AppsFlyerUid",
                .value: "\(AppsFlyerLib.shared().getAppsFlyerUID())",
                .secure: "TRUE",
                .expires: NSDate(timeIntervalSinceNow: 31556926)
            ])!
            cookies.append(AppsFlyerUid)
            let AdvertisingId = HTTPCookie(properties: [
                .domain: "\(self.baseURL)",
                .path: "/",
                .name: "AdvertisingId",
                .value: "\(ASIdentifierManager.shared().advertisingIdentifier.uuidString)",
                .secure: "TRUE",
                .expires: NSDate(timeIntervalSinceNow: 31556926)
            ])!
            cookies.append(AdvertisingId)
            let OS = HTTPCookie(properties: [
                .domain: "\(self.baseURL)",
                .path: "/",
                .name: "OS",
                .value: "iOS",
                .secure: "TRUE",
                .expires: NSDate(timeIntervalSinceNow: 31556926)
            ])!
            
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
            let cookieJar = HTTPCookieStorage.shared
            for cookie in cookieJar.cookies! {
                cookieJar.deleteCookie(cookie)
            }
            self.logoAnimation()
        } else if command == "changeLang" {
            guard let value = body["value"] as? String else { return }
            UserDefaults.standard.set(value, forKey: "language")
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
        var locale = UserDefaults.standard.string(forKey: "language") ?? String(Locale.preferredLanguages[0].prefix(2))
        if language != "" {
            locale = language
        }
        switch locale {
        case "en":
            self.registerButton.setTitle("Registration",for: .normal)
            self.loginButton.setTitle("Log in",for: .normal)
        case "ar":
            self.registerButton.setTitle("?????????? ????????????????",for: .normal)
            self.loginButton.setTitle("?????????? ????????????",for: .normal)
            networkManager.languageEndpoint = "ar/"
        case "bn":
            self.registerButton.setTitle("??????????????????????????????",for: .normal)
            self.loginButton.setTitle("?????? ??????",for: .normal)
            networkManager.languageEndpoint = "bn/"
        case "cn":
            self.registerButton.setTitle("??????",for: .normal)
            self.loginButton.setTitle("??????",for: .normal)
            networkManager.languageEndpoint = "cn/"
        case "es":
            self.registerButton.setTitle("Registro",for: .normal)
            self.loginButton.setTitle("Iniciar sesi??n",for: .normal)
            networkManager.languageEndpoint = "es/"
        case "fa":
            self.registerButton.setTitle("?????? ??????",for: .normal)
            self.loginButton.setTitle("????????",for: .normal)
            networkManager.languageEndpoint = "fa/"
        case "fr":
            self.registerButton.setTitle("Inscription",for: .normal)
            self.loginButton.setTitle("Connexion",for: .normal)
            networkManager.languageEndpoint = "fr/"
        case "hi":
            self.registerButton.setTitle("?????????????????????",for: .normal)
            self.loginButton.setTitle("?????????-?????? ????????????",for: .normal)
            networkManager.languageEndpoint = "hi/"
        case "id":
            self.registerButton.setTitle("Pendaftaran",for: .normal)
            self.loginButton.setTitle("Masuk",for: .normal)
            networkManager.languageEndpoint = "id/"
        case "jp":
            self.registerButton.setTitle("??????",for: .normal)
            self.loginButton.setTitle("????????????",for: .normal)
            networkManager.languageEndpoint = "jp/"
        case "ko":
            self.registerButton.setTitle("??????",for: .normal)
            self.loginButton.setTitle("?????????",for: .normal)
            networkManager.languageEndpoint = "ko/"
        case "ms":
            self.registerButton.setTitle("Pendaftaran",for: .normal)
            self.loginButton.setTitle("Log masuk",for: .normal)
            networkManager.languageEndpoint = "ms/"
        case "pk":
            self.registerButton.setTitle("????????????????",for: .normal)
            self.loginButton.setTitle("Log in",for: .normal)
            networkManager.languageEndpoint = "pk/"
        case "pt":
            self.registerButton.setTitle("Cadastro",for: .normal)
            self.loginButton.setTitle("Entrar",for: .normal)
            networkManager.languageEndpoint = "pt/"
        case "th":
            self.registerButton.setTitle("????????????????????????",for: .normal)
            self.loginButton.setTitle("???????????????????????????????????????",for: .normal)
            networkManager.languageEndpoint = "th/"
        case "tr":
            self.registerButton.setTitle("Kay??t",for: .normal)
            self.loginButton.setTitle("Giri?? Yap",for: .normal)
            networkManager.languageEndpoint = "tr/"
        case "vi":
            self.registerButton.setTitle("????ng k??",for: .normal)
            self.loginButton.setTitle("????ng nh???p",for: .normal)
            networkManager.languageEndpoint = "vi/"
        case "zh":
            self.registerButton.setTitle("??????",for: .normal)
            self.loginButton.setTitle("??????",for: .normal)
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
        self.loginButton.isHidden = false
        self.registerButton.isHidden = false
        //move items to end positions
        UIView.animate(withDuration: 2.0) {
            self.logoImageView.transform = CGAffineTransform(translationX: 0, y: -100)
            self.registerButton.transform = CGAffineTransform(translationX: 0, y: 0)
            self.loginButton.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }

    // OPEN EXTERNAL URSL IN BROWSER
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let externals = RemoteConfig.remoteConfig().configValue(forKey: "forExternalOpens").jsonValue as? [String] {
            for i in externals {
                if #available(iOS 16.0, *) {
                    if let domain = webView.url?.host() {
                        if domain == i {
                            UIApplication.shared.open(webView.url!)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                                if self.webView.canGoBack {
//                                    self.webView.goBack()
//                                } else {
                                    if let prevURL = self.webView.backForwardList.backItem {
                                        self.webView.go(to: prevURL)
                                    }
                                //}
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
//                                if self.webView.canGoBack {
//                                    self.webView.goBack()
//                                } else {
                                    if let prevURL = self.webView.backForwardList.backItem {
                                        self.webView.go(to: prevURL)
                                    }
                                //}
                            }
                            break
                        }
                    }
                }
            }
        }
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
            //print("webView:\(webView) decidePolicyForNavigationAction:\(navigationAction) decisionHandler:\(decisionHandler)")

        let app = UIApplication.shared
        let url = navigationAction.request.url
            let myScheme: NSString = "https"
            //if (url!.scheme == myScheme) && app.canOpenURL(url!) {
                print("redirect detected..")
                // intercepting redirect, do whatever you want
                app.openURL(url!) // open the original url
                decisionHandler(.cancel)
                return
            //}

        decisionHandler(.allow)
        }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let baseURL = URL(string: baseURL)
        if webView.url?.host == baseURL?.host {
            self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                var cookieDict = [String : AnyObject]()
                for cookie in cookies {
                    if cookie.name == "refresh_token" || cookie.name == "_fx_frontend_session" {
                        if cookie.value.count >= 9 {
                            cookieDict[cookie.name] = cookie.properties as AnyObject?
//                            if firebaseRemoteConfig == "DEV" && isTokenDebug {
//                                DispatchQueue.main.async {
//                                    let alert = UIAlertController(title: "\(cookie.name)", message: "\(cookie.domain) : \(cookie.value)", preferredStyle: UIAlertController.Style.alert)
//                                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
//                                    self.present(alert, animated: true, completion: nil)
//                                }
//                            }
                        }
                    } else {
                        cookieDict[cookie.name] = cookie.properties as AnyObject?
                    }
                }
                UserDefaults.standard.set(cookieDict, forKey: "cookies")
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
        var dataPath = documentDirectory?.appendingPathComponent(suggestedFilename)
        
        if #available(iOS 16.0, *) {
            let fileExists = FileManager().fileExists(atPath: dataPath!.path())
        } else {
            let fileExists = FileManager().fileExists(atPath: dataPath!.path)
            // Fallback on earlier versions
        }
        
        
        let destination = dataPath?.appendingPathExtension("/" + suggestedFilename)
        
        try? FileManager.default.removeItem(at: destination!)
        
        Downloader.load(url: response.url!, to: destination!)
        completionHandler(dataPath)
    }

    func downloadDidFinish(_ download: WKDownload) {
        print("downloaded")
        downloadedLabel = UILabel(frame: CGRect(x: (UIScreen.main.bounds.width/2) - 100, y: UIScreen.main.bounds.height / 1.2, width: 200, height: 35))
        //downloadedLabel.center = self.webView.center
        downloadedLabel.text = "download success"
        downloadedLabel.textColor = .white
        downloadedLabel.backgroundColor = .darkGray
        downloadedLabel.textAlignment = .center
        downloadedLabel.layer.masksToBounds = true
        downloadedLabel.layer.cornerRadius = 5
        self.webView.addSubview(downloadedLabel)
        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
            self.downloadedLabel.removeFromSuperview()
        }
    }


    @IBAction func registerButtonAction(_ sender: Any) {
        fetchRemoteConfigDefaultsLoggedIn(openType: "register")
    }
    
    @IBAction func loginButtonACtion(_ sender: Any) {
        fetchRemoteConfigDefaultsLoggedIn(openType: "login")
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
