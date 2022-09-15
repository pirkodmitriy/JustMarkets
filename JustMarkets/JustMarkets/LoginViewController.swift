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

class LoginViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var errorLabel: UILabel!
    
    private let monitor = NWPathMonitor()
    private let networkManager = NetworkManager()
    private let http = "http://"
    private var currentOpenLink = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        monitor.start(queue: .global())
        self.webView.isHidden = true
        self.errorLabel.isHidden = true
        logoAnimation()
        setupLanguage()
        networkManager.getBaseURL()
        // Do any additional setup after loading the view.
    }
    
    private func setupLanguage() {
        let locale = Locale.current.languageCode
        switch locale {
        case "en":
            self.registerButton.titleLabel?.text = "Registration"
            self.loginButton.titleLabel?.text = "Log in"
        case "ar":
            self.registerButton.titleLabel?.text = "تسجيل الاشتراك"
            self.loginButton.titleLabel?.text = "تسجيل الدخول"
        case "bn":
            self.registerButton.titleLabel?.text = "নিবন্ধীকরণ"
            self.loginButton.titleLabel?.text = "লগ ইন"
        case "cn":
            self.registerButton.titleLabel?.text = "注册"
            self.loginButton.titleLabel?.text = "登录"
        case "es":
            self.registerButton.titleLabel?.text = "Registro"
            self.loginButton.titleLabel?.text = "Iniciar sesión"
        case "fa":
            self.registerButton.titleLabel?.text = "ثبت نام"
            self.loginButton.titleLabel?.text = "ورود"
        case "fr":
            self.registerButton.titleLabel?.text = "Inscription"
            self.loginButton.titleLabel?.text = "Connexion"
        case "hi":
            self.registerButton.titleLabel?.text = "पंजीकरण"
            self.loginButton.titleLabel?.text = "लॉग-इन करें"
        case "id":
            self.registerButton.titleLabel?.text = "Pendaftaran"
            self.loginButton.titleLabel?.text = "Masuk"
        case "jp":
            self.registerButton.titleLabel?.text = "登録"
            self.loginButton.titleLabel?.text = "ログイン"
        case "ko":
            self.registerButton.titleLabel?.text = "등록"
            self.loginButton.titleLabel?.text = "로그인"
        case "ms":
            self.registerButton.titleLabel?.text = "Pendaftaran"
            self.loginButton.titleLabel?.text = "Log masuk"
        case "pk":
            self.registerButton.titleLabel?.text = "رجسٹریشن"
            self.loginButton.titleLabel?.text = "لاگ ان"
        case "pt":
            self.registerButton.titleLabel?.text = "Cadastro"
            self.loginButton.titleLabel?.text = "Entrar"
        case "th":
            self.registerButton.titleLabel?.text = "การสมัคร"
            self.loginButton.titleLabel?.text = "ลงชื่อเข้าใช้"
        case "tr":
            self.registerButton.titleLabel?.text = "Kayıt"
            self.loginButton.titleLabel?.text = "Giriş Yap"
        case "vi":
            self.registerButton.titleLabel?.text = "Đăng ký"
            self.loginButton.titleLabel?.text = "Đăng nhập"
        case "zh":
            self.registerButton.titleLabel?.text = "註冊"
            self.loginButton.titleLabel?.text = "登錄"
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
    
    private func setupWebView(link: String) {
        if let url = URL(string: link) {
            self.webView.isHidden = false
            self.webView.navigationDelegate = self
            self.webView.uiDelegate = self
            self.webView.allowsBackForwardNavigationGestures = true
            self.webView.load(URLRequest(url: url))
            self.errorLabel.isHidden = true
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
        currentOpenLink += 1
        registerButtonAction(self)
    }

    @IBAction func registerButtonAction(_ sender: Any) {
        if monitor.currentPath.status == .satisfied {
            // Internet Connected
            let registerLinkString = RemoteConfig.remoteConfig().configValue(forKey: "base_urls").stringValue!
            let data = registerLinkString.data(using: .utf8)!
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [Dictionary<String,Any>]
                {
                    print(jsonArray) // use the json here
                    switch firebaseRemoteConfig {
                    case "DEV":
                        for i in jsonArray {
                            if let links = i["DEV"] as? Array<Any> {
                                if links.count > currentOpenLink {
                                    setupWebView(link: links[currentOpenLink] as! String + "\(Locale.current.languageCode!)/registration/trader")
                                } else {
                                    self.webView.isHidden = true
                                    // SHOW ERROR LABEL
                                    self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                    self.errorLabel.isHidden = false
                                }
                            }
                        }
                    case "STABLE":
                        for i in jsonArray {
                            if let links = i["STABLE"] as? Array<Any> {
                                if links.count > currentOpenLink {
                                    setupWebView(link: links[currentOpenLink] as! String + "\(Locale.current.languageCode!)/registration/trader")
                                } else {
                                    self.webView.isHidden = true
                                    // SHOW ERROR LABEL
                                    self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                    self.errorLabel.isHidden = false
                                }
                            }
                        }
                    case "PROD":
                        for i in jsonArray {
                            if let links = i["PROD"] as? Array<Any> {
                                if links.count > currentOpenLink {
                                    setupWebView(link: links[currentOpenLink] as! String + "\(Locale.current.languageCode!)/registration/trader")
                                } else {
                                    self.webView.isHidden = true
                                    // SHOW ERROR LABEL
                                    self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                                    self.errorLabel.isHidden = false
                                }
                            }
                        }
                    default:
                        self.webView.isHidden = true
                        // SHOW ERROR LABEL
                        self.errorLabel.text = "Sorry, maintenance work in progress. Try again later."
                        self.errorLabel.isHidden = false
                    }
                } else {
                    print("bad json")
                }
            } catch let error as NSError {
                print(error)
            }
        } else {
            // No Internet connection
            self.webView.isHidden = true
            // SHOW ERROR LABEL
            self.errorLabel.text = "No internet connection. Connect and try again"
            self.errorLabel.isHidden = false
        }
        
        
    }
    
    @IBAction func loginButtonACtion(_ sender: Any) {
        
    }
    
}
