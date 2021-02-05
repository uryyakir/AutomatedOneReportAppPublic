//
//  ViewControllerWebView.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 10/4/20.
//

import Foundation
import WebKit
import SwiftyJSON

extension ViewController {
    func setupWebController() -> WKWebView {
        webView = WKWebView()
        webView.frame = self.view.bounds
        webView.navigationDelegate = self

        if let url = URL(string: ViewController.StoredProperties.onePratLoginEndpint) {
            webView.load(URLRequest(url: url))
        }
        return webView
   }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        extractLoginCredentials(withCompletion: { result in
            if result["taz"].string != nil && result["taz"].string! != "" {  // when navigating from register to login page, we don't want the hashed taz to be set immediately on page load
                // save the data in UserDefaults to uniquely identify users
                let hashedTaz = result["taz"].string!.sha256
                UserDefaults().set(["ID": hashedTaz], forKey: "ID")
                StoredProperties.userTaz = hashedTaz
            }

            // if taz & password are the ones provided to Apple's tester - close the webView and index some dummy cookie
            if result["taz"].string == "XXXX" && result["password"].string == "YYYY" {
                return self.setupAppleTesterCreds()
            }
        })

        guard let url = webView.url?.absoluteString else {
            decisionHandler(.allow)
            return
        }

        if url.contains("/hp") || url.contains("/finish") {
            // login (& relevant cookies set) was successful
            self.calculateSettingsAPIConstants()
            decisionHandler(.cancel)
            stopLoading()
            return
        }

        else {
            decisionHandler(.allow)
        }
    }

    private func setupAppleTesterCreds() {
        self.indexUserCookie(cookieDict: [XXX], withCompletion: {_ in})
        self.calculateSettingsAPIConstants()
        self.stopLoading()
        return
    }

    func stopLoading() {
        self.webView.removeFromSuperview()
        if !UIApplication.shared.isRegisteredForRemoteNotifications {
            // calling registerForPushNotifications() sends the UUID-Token pair to the server
            // at this point - userTaz is already correctly set
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.registerForPushNotifications()
        }
        // Notifying ViewController that webView was closed
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "webViewClosed"), object: nil, userInfo: nil)
    }

    func getWebViewCookies(withCompletion completion: @escaping (_ cookie: [String: String]?) -> Void) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies where cookie.name == "AppCookie" {
                completion(["COOKIE_STRING": cookie.value, "COOKIE_EXPIRY_DATE": cookie.expiresDate!.string(format: "dd/MM/yyyy")])
                return
            }
            completion(nil)
            return
        }
    }

    func extractLoginCredentials(withCompletion completion: @escaping (_ json: JSON) -> Void) {
        // Extracting Taz & password from login web page
        // Those credentials allows determining whether the user is an apple tester, and also store a unique ID for every user (hash of Taz)
        let tazQuery = "document.getElementsByName('tz')[0].value"
        let passwordQuery = "document.getElementsByName('password')[0].value"

        webView.evaluateJavaScript(tazQuery) { (result, _) -> Void in
            if result != nil {
                let taz = result! as? String

                self.webView.evaluateJavaScript(passwordQuery) { (result, _) -> Void in
                    if result != nil {
                        let password = result! as? String
                        completion(JSON(["taz": taz, "password": password]))
                        return
                    }
                }
            }
            completion(JSON(["taz": nil, "password": nil]))
            return
        }
    }

    @objc func webViewClosed() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "webViewClosed"), object: nil)
        // attempting to extract cookie after a 3 second delay
        // without the delay, sometimes the attempt is done before the cookie is actually created
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            self.getWebViewCookies(withCompletion: { cookieDict in
                self.indexUserCookie(cookieDict: cookieDict, withCompletion: {_ in})
            })
        }
        setupInputPage()  // building report input page
    }
}
