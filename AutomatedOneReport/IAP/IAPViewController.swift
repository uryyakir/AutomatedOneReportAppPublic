//
//  IAPViewController.swift
//  דוח 1 אוטומטי
//
//  Created by Uri Yakir on 13/12/2020.
//

import Foundation
import UIKit
import StoreKit
import GoogleMobileAds

class IAPViewController: UIViewController, GADBannerViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    var IAPTitle: UILabel = UILabel()

    override func viewDidLoad() {
        SKPaymentQueue.default().add(self)
        self.view.backgroundColor = ViewController.StoredProperties.originalSiteColor
        setupPage()

        super.viewDidLoad()
    }

    private func setupPage() {
        if !ViewController.StoredProperties.adsRemovalEligible {
            self.view.addSubview(StoredProperties.banner)
            ViewController.constrainBanner(banner: StoredProperties.banner, viewController: self)

        }
        let IAPTitle = SettingsViewController.StoredProperties.getSettingsTitle("נהנים מהאפליקציה?\nמוזמנים לתמוך בנו!", fontSize: 30, numberOfLines: 2)
        self.view.addSubview(IAPTitle)
        constrainIAPTitle(IAPTitle: IAPTitle)

        self.view.addSubview(StoredProperties.scrollView)
        constrainScrollView(scrollView: StoredProperties.scrollView)

        let iapStackView = IAPStackView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0), IAPController: self)
        StoredProperties.scrollView.addSubview(iapStackView)
        constrainIAPStackView(iapStackView: iapStackView)

        IAPViewController.visualizeAlreadyPurchased()
        addIAPRestoreButton()
    }

    private func constrainIAPTitle(IAPTitle: UILabel) {
        if ViewController.StoredProperties.adsRemovalEligible {
            IAPTitle.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 15).isActive = true
        }
        else {
            IAPTitle.topAnchor.constraint(equalTo: StoredProperties.banner.bottomAnchor, constant: 15).isActive = true
        }
        IAPTitle.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 5).isActive = true
        IAPTitle.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -5).isActive = true
        self.IAPTitle = IAPTitle
    }

    private func constrainScrollView(scrollView: UIScrollView) {
        StoredProperties.scrollView.topAnchor.constraint(equalTo: self.IAPTitle.bottomAnchor, constant: 15).isActive = true
        StoredProperties.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10).isActive = true
        StoredProperties.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 5).isActive = true
        StoredProperties.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -5).isActive = true
    }

    private func constrainIAPStackView(iapStackView: UIStackView) {
        iapStackView.leadingAnchor.constraint(equalTo: StoredProperties.scrollView.leadingAnchor, constant: 20).isActive = true
        iapStackView.trailingAnchor.constraint(equalTo: StoredProperties.scrollView.trailingAnchor, constant: -20).isActive = true
        iapStackView.topAnchor.constraint(equalTo: StoredProperties.scrollView.topAnchor, constant: 0).isActive = true
        iapStackView.bottomAnchor.constraint(equalTo: StoredProperties.scrollView.bottomAnchor, constant: iapStackView.frame.height - 15).isActive = true
    }

    private func addIAPRestoreButton() {
        let restoreButton = UIBarButtonItem(title: "שחזר רכישות קודמות", style: .plain, target: self, action: #selector(self.attemptIAPRestore))
        self.navigationItem.rightBarButtonItem = restoreButton
    }
}
