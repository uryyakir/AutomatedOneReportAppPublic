//
//  ViewController.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 9/29/20.
//

import UIKit
import WebKit
import GoogleMobileAds

class ViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    static var codeMaps: [String: [String: String]] = [:]
    static var outsideUnitMainOptions: Dictionary<String, Any>.Keys = [:].keys
    static var outsideUnitSecondaryOptions: [String: [String]] = [:]

    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.sendTokenToServer), name: NSNotification.Name(rawValue: "registeredForRemoteNotifications"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.presentInterstitial), name: NSNotification.Name(rawValue: "presentInterstitial"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.removeAds), name: NSNotification.Name(rawValue: "removeBanner"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateBackgroundColor), name: NSNotification.Name(rawValue: "backgroundColorUpdated"), object: nil)

        DispatchQueue.main.async {
            // loading ads objects
            ViewController.createAndLoadInterstitial(viewController: self)
            ViewController.StoredProperties.banner = ViewController.createAndLoadBanner(viewController: self)
            SettingsViewController.StoredProperties.banner = ViewController.createAndLoadBanner(viewController: StoredProperties.settingsViewController)
            IAPViewController.StoredProperties.banner = ViewController.createAndLoadBanner(viewController: StoredProperties.iapViewController)
        }

        self.updateRequired()
        self.populateStaticValues(withCompletion: {
            // only building UI after constants have been determined
            self.checkCookieAvailability()
        })

        self.view.backgroundColor = StoredProperties.originalSiteColor
        self.navigationController?.navigationBar.barTintColor = StoredProperties.originalSiteColor

        super.viewDidLoad()
    }
}
