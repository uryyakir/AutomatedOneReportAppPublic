//
//  AlertControllersSetup.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 16/11/2020.
//

import Foundation
import UIKit

extension ViewController {
    func presentSuccessStatus(flag: Bool) {
        // Presenting Alerts to fit recieved flags
        if flag {
            dismiss(animated: true, completion: {
                ViewController.BuildUIAlert(self, title: "העדכון התבצע בהצלחה!", message: "הסטטוס העדכני שלך התעדכן בהצלחה", backgroundColor: ViewController.StoredProperties.greenAlertColor, appearanceTime: 2.0)
            })
        }
    }

    static func BuildUIAlert(_ viewController: UIViewController, title: String? = nil, message: String? = nil, backgroundColor: UIColor? = nil, appearanceTime: Double? = nil, withLoadingAnimation: Bool? = nil, presentCompletion completion: @escaping () -> Void = { }) {
        // Easily building UIAlertControllers
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

            if backgroundColor != nil {
                let FirstSubview = alert.view.subviews.first
                let AlertContentView = FirstSubview?.subviews.first
                for subview in (AlertContentView?.subviews)! {
                    subview.backgroundColor = backgroundColor
                }
            }
            if withLoadingAnimation == true {
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 5, width: 50, height: 50))
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.style = UIActivityIndicatorView.Style.gray
                loadingIndicator.startAnimating()

                alert.view.addSubview(loadingIndicator)
            }

            DispatchQueue.main.async {
                viewController.present(alert, animated: true, completion: {
                    completion()
                })
            }
            if appearanceTime != nil {
                // dismissing after given interval
                Timer.scheduledTimer(withTimeInterval: appearanceTime!, repeats: false, block: { _ in
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true, completion: {
                            if title == "אירעה שגיאה בתקשורת עם השרת!" {
                                ViewController.StoredProperties.APIFailureShown = false
                            }
                            else if title == "העדכון התבצע בהצלחה!" && !StoredProperties.adsRemovalEligible {
                                // presenting interstitial after updating user status
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "presentInterstitial"), object: nil, userInfo: nil)
                            }
                        })
                    }
                })
            }
        }
    }
}
