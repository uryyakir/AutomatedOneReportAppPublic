//
//  IAPConfig.swift
//  דוח 1 אוטומטי
//
//  Created by Uri Yakir on 13/12/2020.
//

import Foundation
import UIKit
import StoreKit
import GoogleMobileAds

extension IAPViewController {
    struct StoredProperties {
        static var IAPLabelFontSize: CGFloat = 20
        static var IAPStackViewFontSize: CGFloat = 100.0
        static let backgroundCyan: UIColor = UIColor(red: 173/256, green: 216/256, blue: 230/256, alpha: 0.7)
        static let boughtBackgroundCyan: UIColor = UIColor(red: 173/256, green: 216/256, blue: 230/256, alpha: 0.15)
        static let boughtBackgroundGreen: UIColor = UIColor(red: 144/256, green: 238/256, blue: 144/256, alpha: 0.8)
        // Ads constant
        static var banner: GADBannerView!

        static var IAPObjects: [String: [String: UIObjects]] = [
            "bronze": [
                "productId": "XXX",
                "title": "תמיכה באפליקציה (1$)",
                "secondaryTitle": "+ הסרת פרסומות",
                "image": "bronze-medal"
            ],
            "silver": [
                "productId": "XXX",
                "title": "תמיכה באפליקציה (2$)",
                "secondaryTitle": "+ הסרת פרסומות",
                "image": "silver-medal"
            ],
            "gold": [
                "productId": "XXX",
                "title": "תמיכה באפליקציה (3$)",
                "secondaryTitle": "+ הסרת פרסומות",
                "image": "gold-medal"
            ]
        ]

        static let scrollView: UIScrollView = {
            let scrollView = UIScrollView()
            scrollView.layer.cornerRadius = 8.0
            scrollView.layer.masksToBounds = true
            // v.layer.borderWidth = 1.0
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            return scrollView
        }()

        static var IAPPairs: [String: String] = {
            var IAPDict: [String: String] = [:]
            for (IAPKey, IAPValue) in IAPObjects {
                IAPDict[(IAPValue["productId"]! as? String)!] = IAPKey
            }
            return IAPDict
        }()

        static var IAPProduct: SKProduct?
    }
}
