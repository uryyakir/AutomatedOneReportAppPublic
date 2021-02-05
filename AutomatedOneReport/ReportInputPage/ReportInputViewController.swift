//
//  ReportUserInput.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 17/10/2020.
//

import Foundation
import UIKit
import GoogleMobileAds

extension ViewController {
    static func constrainBanner(banner: GADBannerView, viewController: UIViewController) {
        banner.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 5.0).isActive = true
        banner.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 5.0).isActive = true
        banner.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -5.0).isActive = true
        banner.isHidden = false
    }

    private func constrainHelpLabel(helpLabel: UILabel) {
        helpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50.0).isActive = true
        helpLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50.0).isActive = true
        if StoredProperties.adsRemovalEligible {
            // constraining topAnchor to view instead of banner
            helpLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15).isActive = true
        }
        else {
            // constraining topAnchor to banner's buttomAnchor
            helpLabel.topAnchor.constraint(equalTo: StoredProperties.banner.bottomAnchor, constant: 15).isActive = true
        }
    }

    private func constrainSendReport(sendReport: UIButton) {
        sendReport.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50.0).isActive = true
        sendReport.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50.0).isActive = true
        sendReport.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }

    private func constrainScrollView(scrollView: UIScrollView) {
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        scrollView.topAnchor.constraint(equalTo: StoredProperties.helpLabel.bottomAnchor, constant: 8.0).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: StoredProperties.sendReport.topAnchor, constant: -8.0).isActive = true
    }

    private func constrainReportInputStackView(reportInputStackView: ReportInputStackView) {
        reportInputStackView.leadingAnchor.constraint(equalTo: StoredProperties.scrollView.leadingAnchor, constant: 5).isActive = true
        reportInputStackView.trailingAnchor.constraint(equalTo: StoredProperties.scrollView.trailingAnchor, constant: -5).isActive = true
        reportInputStackView.topAnchor.constraint(equalTo: StoredProperties.scrollView.topAnchor, constant: 20).isActive = true
        // calculating needed height for scrollView using a singleInputList.bounds.height (which is a horizontal scrollView)
        // multiplied by number of such objects
        // adding 20 pixels since that is the top distance from scrollView.topAnchor
        reportInputStackView.bottomAnchor.constraint(equalTo: StoredProperties.scrollView.bottomAnchor, constant: -CGFloat(20 + reportInputStackView.singleInputList.last!.bounds.height*CGFloat(reportInputStackView.singleInputList.count))).isActive = true
    }

    @objc func openSettings() {
        show(ViewController.StoredProperties.settingsViewController, sender: nil)
        if StoredProperties.interstitial.isReady && !ViewController.StoredProperties.adsRemovalEligible {
             StoredProperties.interstitial.present(fromRootViewController: StoredProperties.settingsViewController)
         }
    }

    @objc func updateBackgroundColor() {
        // we need to recreate entire page in order for the change to take place across all objects
        self.view.backgroundColor = StoredProperties.originalSiteColor
        StoredProperties.reportInputStackView.singleInputList.forEach({
            ($0.singleReportObjects["outsideUnit"]!["object"] as? UIButton)!.backgroundColor = StoredProperties.originalSiteColor
            ($0.singleReportObjects["inArmy"]!["object"] as? UIButton)!.backgroundColor = StoredProperties.originalSiteColor
        })
    }

    @objc func openIAP() {
        show(ViewController.StoredProperties.iapViewController, sender: nil)
    }

    func setupInputPage(showUIAlert: Bool = true) {
        // add banner to self.view
        if !StoredProperties.adsRemovalEligible {
            self.view.addSubview(StoredProperties.banner)
            ViewController.constrainBanner(banner: StoredProperties.banner, viewController: self)
        }

        // add the help label to self.view
        self.view.addSubview(StoredProperties.helpLabel)
        constrainHelpLabel(helpLabel: StoredProperties.helpLabel)

        // add send report button to self.view
        self.view.addSubview(StoredProperties.sendReport)
        constrainSendReport(sendReport: StoredProperties.sendReport)

        // add scrollView, constrained vertically by help label and report button
        self.view.addSubview(StoredProperties.scrollView)
        constrainScrollView(scrollView: StoredProperties.scrollView)

        if showUIAlert { ViewController.BuildUIAlert(self, message: "מעדכן סטטוס דיווח אחרון... ", withLoadingAnimation: true) }
        self.getScheduledSubmissionHour(withCompletion: { hour in
            // After calculating stackView and presenting it - checking if current day has already been passed.
            // This is done by calling /scheduled_submission_hour API and recieving the "deadline" hour for submission.
            // If deadline hour has passed - removing current day (which is the FIRST subview of the reportInputStackView object) from Superview.
            // If API call failed, we avoid removing from Superview.
            if ![6, 7].contains(Date().getWeekDay) && Calendar.current.component(.hour, from: Date()) > hour["data"]["scheduled_submission_hour"].int! && hour["data"]["scheduled_submission_hour"].int != -1 {
                // remove first date (=today) from stackView
                DispatchQueue.main.async {
                    StoredProperties.reportInputStackView.subviews[0].removeFromSuperview()  // removing object visually
                    StoredProperties.reportInputStackView.singleInputList.removeFirst() // removing from stored array
                }
            }
            // updating page with current user report data
            self.getUserReport(withCompletion: { report in
                var currentInput: [String: String] = [:]
                if report["success"].bool! {
                    for dataset in report["data"].arrayValue {
                        // parsing user data from API response into currentInput dictionary
                        currentInput[dataset["_source"]["DATE"].date!.string(format: "dd/MM/yyyy")] = dataset["_source"]["SECONDARY_TEXT"].string
                    }
                    DispatchQueue.main.async {
                        StoredProperties.reportInputStackView.visualizeCurrentData(data: currentInput)
                        StoredProperties.scrollView.addSubview(StoredProperties.reportInputStackView)
                        self.constrainReportInputStackView(reportInputStackView: StoredProperties.reportInputStackView)
                        // dismiss alert regarding fetch of user data
                        self.dismiss(animated: true, completion: {
                            // add navigation to settings & IAP page button in navbar
                            let settingsNavigation = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(self.openSettings))
                            settingsNavigation.setBackgroundImage(UIImage(named: "settings"), for: .normal, barMetrics: .default)
                            let IAPNavigation = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(self.openIAP))
                            IAPNavigation.setBackgroundImage(UIImage(named: "shopping-cart"), for: .normal, barMetrics: .default)
                            self.navigationItem.rightBarButtonItem = settingsNavigation
                            self.navigationItem.leftBarButtonItem = IAPNavigation
                            // after finishing all visualizations - converting empty days' labels gray
                            for horizStackView in StoredProperties.reportInputStackView.singleInputList {
                                horizStackView.isEmptyDay()
                            }
                        })
                    }
                }
            })
        })
    }
}
