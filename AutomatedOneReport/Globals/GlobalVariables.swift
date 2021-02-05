//
//  globalVariables.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 16/11/2020.
//

import Foundation
import UIKit
import GoogleMobileAds

extension ViewController {
    struct StoredProperties {
        // web constants
        static let apiEndpoint = "XXX"
        static let onePratLoginEndpint = "XXX"
        static var APIFailureShown = false
        // visual constants
        static var originalSiteColor: UIColor! // default value would be the original site's color, but may be overwritten by settings color picker
        static let greenAlertColor = UIColor(red: 92/255, green: 184/255, blue: 92/255, alpha: 0.8)
        static let redAlertColor = UIColor(red: 217/255, green: 83/255, blue: 79/255, alpha: 0.8)
        static let grayAlertColor = UIColor(red: 169/255, green: 169/255, blue: 169/255, alpha: 1)
        static var reportInputStackView: ReportInputStackView = ReportInputStackView(frame: CGRect())
        static var dateLabelFontSize: CGFloat = 18
        // settings constants
        static var settingsViewController = SettingsViewController()
        static var apiReportTime: String = ""
        static var minimumPossibleReportTime: String = ""
        static var maximumPossibleReportTime: String = ""
        // IAP constants
        static var iapViewController = IAPViewController()
        static var adsRemovalEligible = false
        static var iapPurchased: [String] = []
        // identification constants
        static var userTaz: String = ""
        // Ads constant
        static var banner: GADBannerView!
        static var interstitial: GADInterstitial!

        static let helpLabel: UILabel = {
            let label = UILabel()
            label.text = "איפה את/ה\nבשבוע הקרוב?"
            label.numberOfLines = 2
            label.font = UIFont.systemFont(ofSize: 30, weight: UIFont.Weight(200))
            label.textColor = .black
            label.textAlignment = NSTextAlignment.center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        static let sendReport: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("שמור דיווח", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: UIFont.Weight(200))
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(sendReportToServer), for: .touchUpInside)
            return button
        }()

        static let scrollView: UIScrollView = {
            let scrollView = UIScrollView()
            scrollView.layer.cornerRadius = 8.0
            scrollView.layer.masksToBounds = true
            // v.layer.borderWidth = 1.0
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            return scrollView
        }()

        static func updateSmallScreenConstants() {
            ViewController.StoredProperties.dateLabelFontSize = 15
            SettingsViewController.StoredProperties.settingsLabelFontSize = 20.0
            SettingsViewController.StoredProperties.sendHourLabelFontSize = 15.0
            SettingsViewController.StoredProperties.datePickerTitle = "בחר שעה רצויה:"
            IAPViewController.StoredProperties.IAPLabelFontSize = 15.0
            IAPViewController.StoredProperties.IAPStackViewFontSize = 50
        }
    }

    func calculateSettingsAPIConstants() {
        // Populating constants required by Settings page
        ViewController.makeAPICommunication(self, route: "get-user-settings", requestType: "POST", withCompletion: { response in
            ViewController.StoredProperties.apiReportTime = response["data"]["API_REPORT_TIME"].string!
            ViewController.StoredProperties.minimumPossibleReportTime = response["data"]["MINIMUM_POSSIBLE_REPORT_TIME"].string!
            ViewController.StoredProperties.maximumPossibleReportTime = response["data"]["MAXIMUM_POSSIBLE_REPORT_TIME"].string!

            if response["data"]["NEEDS_INDEXING"].bool! {
                // on initial app run - user has no record in settings index
                // therefore - we need to index a custom record for that user so he can customize it later
                ViewController.makeAPICommunication(self, route: "index-user-settings", requestType: "POST", withCompletion: {_ in }, data: ["VENDOR_UUID": ViewController.StoredProperties.userTaz, "API_REPORT_TIME": ViewController.StoredProperties.apiReportTime])
            }
        }, data: ["VENDOR_UUID": StoredProperties.userTaz])
    }
}
