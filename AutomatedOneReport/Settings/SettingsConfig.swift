//
//  SettingsConfig.swift
//  דוח 1 אוטומטי
//
//  Created by Uri Yakir on 04/12/2020.
//

import Foundation
import UIKit
import GoogleMobileAds

extension SettingsViewController {
    struct StoredProperties {
        static let settingsLabels: [String] = [
            "שעת שליחת הדו\"ח",
            "צבע הרקע"
        ]
        static var settingsLabelFontSize: CGFloat = 25
        static var sendHourLabelFontSize: CGFloat = 20
        static var datePickerTitle: String = "באיזה שעה תרצה שהדו\"ח יישלח?"
        static var settingsList: [String: HorizSettingsStackView] = [:]
        // Ads constant
        static var banner: GADBannerView!

        static func getSettingsTitle(_ titleText: String = "הגדרות", fontSize: CGFloat = 40, numberOfLines: Int = 1) -> UILabel {
            let title = UILabel()
            title.textColor = UIColor.darkGray
            title.text = titleText
            title.font = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight(300))
            title.textAlignment = .center
            title.numberOfLines = numberOfLines
            title.translatesAutoresizingMaskIntoConstraints = false

            return title
        }

        static func getSettingsLabel(labelText: String) -> UILabel {
            let title = UILabel()
            title.textColor = UIColor.black
            title.font = UIFont.systemFont(ofSize: settingsLabelFontSize, weight: UIFont.Weight(300))
            title.text = labelText
            title.textAlignment = .right
            title.translatesAutoresizingMaskIntoConstraints = false

            return title
        }

        static var sendHourLabel: UIView {
            var hourLabelView = UIView()
            hourLabelView = hourLabelView.setLayer

            let label = PaddedLabel()
            label.textColor = UIColor(red: 0, green: 102/255, blue: 204/255, alpha: 1)
            label.font = UIFont.systemFont(ofSize: sendHourLabelFontSize, weight: UIFont.Weight(300))
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false

            hourLabelView.addSubview(label)
            label.centerXAnchor.constraint(equalTo: hourLabelView.centerXAnchor, constant: 0).isActive = true
            label.centerYAnchor.constraint(equalTo: hourLabelView.centerYAnchor, constant: 0).isActive = true
            label.leadingAnchor.constraint(equalTo: hourLabelView.leadingAnchor, constant: 0).isActive = true
            label.trailingAnchor.constraint(equalTo: hourLabelView.trailingAnchor, constant: 0).isActive = true

            DispatchQueue.main.async {
                label.text = ViewController.StoredProperties.apiReportTime
            }

            return hourLabelView
        }

        static var colorPickerSample: UIView = {
            var sampleView = UIView()
            sampleView = sampleView.setLayer

            let label = PaddedLabel()
            label.text = "בחר"
            label.textColor = UIColor(red: 0, green: 102/255, blue: 204/255, alpha: 1)
            label.font = UIFont.systemFont(ofSize: sendHourLabelFontSize, weight: UIFont.Weight(300))
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false

            sampleView.addSubview(label)
            label.centerXAnchor.constraint(equalTo: sampleView.centerXAnchor, constant: 0).isActive = true
            label.centerYAnchor.constraint(equalTo: sampleView.centerYAnchor, constant: 0).isActive = true
            label.leadingAnchor.constraint(equalTo: sampleView.leadingAnchor, constant: 0).isActive = true
            label.trailingAnchor.constraint(equalTo: sampleView.trailingAnchor, constant: 0).isActive = true

            return sampleView
        }()
    }
}

class PaddedLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        super.drawText(in: rect.inset(by: insets))
    }
}
