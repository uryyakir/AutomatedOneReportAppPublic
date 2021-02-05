//
//  RemoteNotifications.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 16/11/2020.
//

import Foundation
import UserNotifications
import UIKit

extension AppDelegate {
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "registeredForRemoteNotifications"), object: nil, userInfo: nil)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // The token is not currently available.
        print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
        application.unregisterForRemoteNotifications()
        token = nil
    }
}

extension ViewController {
    @objc func sendTokenToServer() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "registeredForRemoteNotifications"), object: nil)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if appDelegate!.token != nil {
            ViewController.makeAPICommunication(self, route: "index-user-token", requestType: "POST", withCompletion: {_ in }, data: [
                "TOKEN": appDelegate!.token!,
                "VENDOR_UUID": StoredProperties.userTaz
            ])
        }
    }
}
