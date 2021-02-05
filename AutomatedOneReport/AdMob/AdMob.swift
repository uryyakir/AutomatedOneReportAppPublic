//
//  AdMob.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 17/11/2020.
//

import Foundation
import GoogleMobileAds

extension ViewController: GADInterstitialDelegate, GADBannerViewDelegate {
    static func createAndLoadInterstitial(viewController: GADInterstitialDelegate) {
        ViewController.StoredProperties.interstitial = GADInterstitial(adUnitID: "XXX")
        ViewController.StoredProperties.interstitial.delegate = viewController
        let request = GADRequest()
        ViewController.StoredProperties.interstitial.load(request)
    }

    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        ViewController.createAndLoadInterstitial(viewController: self)
    }

    static func createAndLoadBanner(viewController: GADBannerViewDelegate) -> GADBannerView {
        let banner = GADBannerView(adSize: kGADAdSizeBanner)
        banner.adUnitID = "XXX"
        banner.rootViewController = viewController as? UIViewController
        banner.delegate = viewController
        let request = GADRequest()
        banner.load(request)
        banner.isHidden = true
        banner.translatesAutoresizingMaskIntoConstraints = false

        return banner
    }

    @objc func presentInterstitial() {
        if StoredProperties.interstitial.isReady {
            StoredProperties.interstitial.present(fromRootViewController: self)
        }
    }

    @objc func removeAds() {
        // this will be called after an IAP was done, so user will stop seeing apps immediately without having to restart app
        ViewController.StoredProperties.adsRemovalEligible = true
        self.view.subviews.forEach({ $0.removeFromSuperview() })
        // reset reportInputStackView
        ViewController.StoredProperties.reportInputStackView = ReportInputStackView(frame: CGRect())
        // re-initiate view controllers to remove banners
        ViewController.StoredProperties.settingsViewController = SettingsViewController()
        ViewController.StoredProperties.iapViewController = IAPViewController()
        self.setupInputPage(showUIAlert: false)
    }
}
