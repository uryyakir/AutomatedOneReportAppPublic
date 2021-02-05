//
//  AppDelegate.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 9/29/20.
//

import UIKit
import UserNotifications
import GoogleMobileAds

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var token: String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        appLaunchBackgroundColor()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        // attempt to get stored userTaz and populate StoredProperties
        if let retrievedDict = UserDefaults().dictionary(forKey: "ID") {
            if let taz = retrievedDict["ID"] as? String {
                ViewController.StoredProperties.userTaz = taz
                if taz != "".sha256 {
                    // this allows token indexing even if user initially doesn't allow notifications & then later approves it manually through settings
                    // while also preventing indexing the hash of the empty string when initally running the app
                    if !UIApplication.shared.isRegisteredForRemoteNotifications {
                        // calling registerForPushNotifications() sends the UUID-Token pair to the server
                        registerForPushNotifications()
                    }
                }
            }
        }

        if #available(iOS 13, *) {
            return true
            // do only pure app launch stuff, not interface stuff
        }
        else {
            self.window = UIWindow()
            let vc = ViewController()
            self.window!.rootViewController = vc
            self.window!.makeKeyAndVisible()
        }
        return true
    }

    private func appLaunchBackgroundColor() {
        // if originalSiteColor wasn't overriden by color picker in settings, use default color
        let defaults = UserDefaults.standard
        let backgroundColors = [defaults.float(forKey: "backgroundRed"), defaults.float(forKey: "backgroundGreen"), defaults.float(forKey: "backgroundBlue"), defaults.float(forKey: "backgroundAlpha")]
        // default values are 0.0 for floats in UserDefaults
        // to avoid using those values, we check that sum of backgroundColors array isn't zero
        if backgroundColors.reduce(0, +) != 0 {
            // custom background color was chosen by user
            ViewController.StoredProperties.originalSiteColor = UIColor(red: CGFloat(backgroundColors[0]), green: CGFloat(backgroundColors[1]), blue: CGFloat(backgroundColors[2]), alpha: CGFloat(backgroundColors[3]))
        }
        else {
            // use default
            ViewController.StoredProperties.originalSiteColor = UIColor(red: 246/255, green: 228/255, blue: 102/255, alpha: 1)
        }
    }
}
