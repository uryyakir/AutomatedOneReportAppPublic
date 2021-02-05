//
//  SettingsViewController.swift
//  דוח 1 אוטומטי
//
//  Created by Uri Yakir on 04/12/2020.
//

import Foundation
import UIKit
import GoogleMobileAds
import FlexColorPicker

class SettingsViewController: UIViewController, GADBannerViewDelegate, ColorPickerDelegate {
    override func viewDidLoad() {
        self.view.backgroundColor = ViewController.StoredProperties.originalSiteColor

        if !ViewController.StoredProperties.adsRemovalEligible {
            self.view.addSubview(StoredProperties.banner)
            ViewController.constrainBanner(banner: StoredProperties.banner, viewController: self)
        }

        let settingsStackView = SettingsStackView(frame: CGRect(), settingsController: self)
        self.view.addSubview(settingsStackView)
        SettingsViewController.constrainSettingsStackView(settingsStackView, viewController: self)

        super.viewDidLoad()
    }

    static func constrainSettingsStackView(_ settingsStackView: UIView, viewController: UIViewController) {
        if ViewController.StoredProperties.adsRemovalEligible {
            settingsStackView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 15).isActive = true
        }
        else {
            settingsStackView.topAnchor.constraint(equalTo: StoredProperties.banner.bottomAnchor, constant: 15).isActive = true
        }
        settingsStackView.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor, constant: 25).isActive = true
        settingsStackView.trailingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.trailingAnchor, constant: -15).isActive = true
    }

    func colorPicker(_ colorPicker: ColorPickerController, confirmedColor: UIColor, usingControl: ColorControl) {
        self.changeViewControllerColors(confirmedColor)
    }

    func colorPicker(_ colorPicker: ColorPickerController, selectedColor: UIColor, usingControl: ColorControl) {
        self.changeViewControllerColors(selectedColor)
    }

    private func changeViewControllerColors(_ color: UIColor) {
        // changing navbar accordingly as a preview for the user
        self.navigationController?.navigationBar.barTintColor = color
        self.view.backgroundColor = color
        // changing background color for objects in SettingsStackView
        StoredProperties.colorPickerSample.backgroundColor = color
        StoredProperties.settingsList["שעת שליחת הדו\"ח"]?.arrangedSubviews[1].backgroundColor = color
        // override ViewController's originalSiteColor variable
        ViewController.StoredProperties.originalSiteColor = color
        // override IAP page background color
        ViewController.StoredProperties.iapViewController.view.backgroundColor = color
        // saving rgba to user defaults
        saveColorToUserDefaults(color)
        // making sure main ViewController also changes its background color
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "backgroundColorUpdated"), object: nil, userInfo: nil)
    }

    private func saveColorToUserDefaults(_ color: UIColor) {
        let defaults = UserDefaults.standard
        let rgba = color.cgColor.components!
        let red = rgba[0]; let green = rgba[1]; let blue = rgba[2]; let alpha = rgba[3]
        defaults.set(red, forKey: "backgroundRed")
        defaults.set(green, forKey: "backgroundGreen")
        defaults.set(blue, forKey: "backgroundBlue")
        defaults.set(alpha, forKey: "backgroundAlpha")
    }
}
