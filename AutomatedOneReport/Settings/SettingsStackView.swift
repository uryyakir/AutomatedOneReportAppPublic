//
//  SettingsStackView.swift
//  דוח 1 אוטומטי
//
//  Created by Uri Yakir on 05/12/2020.
//

import Foundation
import UIKit
import ActionSheetPicker_3_0
import FlexColorPicker

extension SettingsViewController {
    class SettingsStackView: UIStackView {
        let settingsController: UIViewController

        required init(frame: CGRect, settingsController: UIViewController) {
            self.settingsController = settingsController

            super.init(frame: frame)

            initialSetup()
            addSettings()
            addReportTimeLabel()
            addColorPickerSample()
        }

        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func initialSetup() {
            self.axis = NSLayoutConstraint.Axis.vertical
            self.distribution = UIStackView.Distribution.equalSpacing
            self.spacing = 40.0

            self.translatesAutoresizingMaskIntoConstraints = false

            let settingsTitle = SettingsViewController.StoredProperties.getSettingsTitle()
            self.addArrangedSubview(settingsTitle)
        }

        private func addSettings() {
            // iterating over setting labels and adding them to stackView
            for settingLabel in SettingsViewController.StoredProperties.settingsLabels {
                let label = SettingsViewController.StoredProperties.getSettingsLabel(labelText: settingLabel)  // build UILabel from given string
                let horizSettingsStackView = HorizSettingsStackView()
                horizSettingsStackView.semanticContentAttribute = .forceRightToLeft
                horizSettingsStackView.addArrangedSubview(label)
                self.addArrangedSubview(horizSettingsStackView)

                StoredProperties.settingsList[settingLabel] = horizSettingsStackView  // storing every horizSettingsStackView into a dictionary that will allow accessing it later
            }
        }

        private func buildDate(timeString: String) -> Date {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.date(from: timeString)!
        }

        @objc private func datePicked(_ date: Date) {
            let datePicked = date.string(format: "HH:mm")
            ViewController.makeAPICommunication(self.settingsController, route: "index-user-settings", requestType: "POST", withCompletion: {response in
                if response["success"].bool! {
                    // we don't want the setting time to update visually if API call wasn't successful
                    DispatchQueue.main.async {
                        (StoredProperties.settingsList["שעת שליחת הדו\"ח"]?.arrangedSubviews[1].subviews[0] as? UILabel)!.text = datePicked
                    }
                }
            }, data: ["VENDOR_UUID": ViewController.StoredProperties.userTaz, "API_REPORT_TIME": datePicked])
        }

        private func showHelperAlertAndDatePicker(_ datePicker: ActionSheetDatePicker?) {
            ViewController.BuildUIAlert(self.settingsController, title: "מילוי הדו\"ח מוגבל בשעות", message: "ניתן לבחור רק ערכים בין \(ViewController.StoredProperties.minimumPossibleReportTime) ל-\(ViewController.StoredProperties.maximumPossibleReportTime)", backgroundColor: ViewController.StoredProperties.grayAlertColor)

            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { _ in
                self.settingsController.dismiss(animated: true, completion: {
                    datePicker?.show()
                })
            })
        }

        @objc private func timePicker() {
            let datePicker = ActionSheetDatePicker(
                title: SettingsViewController.StoredProperties.datePickerTitle,
                datePickerMode: UIDatePicker.Mode.time,
                selectedDate: buildDate(timeString: (StoredProperties.settingsList["שעת שליחת הדו\"ח"]?.arrangedSubviews[1].subviews[0] as? UILabel)!.text!),  // initially selected date will be the custom date previously selected by the user
                target: self,
                action: #selector(datePicked(_:)),
                origin: StoredProperties.settingsList["שעת שליחת הדו\"ח"]
            )!
            datePicker.minuteInterval = 15
            if #available(iOS 13.4, *) {
                datePicker.datePickerStyle = .automatic
            }
            // using minimum and maximum possible report times provided from API to limit datePicker possible times
            datePicker.minimumDate = buildDate(timeString: ViewController.StoredProperties.minimumPossibleReportTime)
            datePicker.maximumDate = buildDate(timeString: ViewController.StoredProperties.maximumPossibleReportTime)

            showHelperAlertAndDatePicker(datePicker)
        }

        @objc private func showColorPicker() {
            let colorPickerController = DefaultColorPickerViewController()
            colorPickerController.selectedColor = ViewController.StoredProperties.originalSiteColor
            colorPickerController.delegate = self.settingsController as? ColorPickerDelegate
            let backButton = UIBarButtonItem()
            backButton.title = "בחר וחזור"
            settingsController.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
            settingsController.navigationController?.pushViewController(colorPickerController, animated: true)
        }

        private func addReportTimeLabel() {
            // This is relevant only to the report-time setting
            // We need to add a tapable label with current report time to the horizontal stackView
            let timeLabel = SettingsViewController.StoredProperties.sendHourLabel
            let timeLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector (self.timePicker))
            DispatchQueue.main.async {
                timeLabel.addGestureRecognizer(timeLabelTapGesture)
                StoredProperties.settingsList["שעת שליחת הדו\"ח"]?.addArrangedSubview(timeLabel)
            }
        }

        private func addColorPickerSample() {
            // This is relevant only to the set-background-color setting
            // We need to add a tapable imageView with current background color to the horizontal stackView
            let colorPickerdSample = SettingsViewController.StoredProperties.colorPickerSample
            let colorPickerTapGesture = UITapGestureRecognizer(target: self, action: #selector (self.showColorPicker))
            DispatchQueue.main.async {
                colorPickerdSample.addGestureRecognizer(colorPickerTapGesture)
                StoredProperties.settingsList["צבע הרקע"]?.addArrangedSubview(colorPickerdSample)
            }
        }
    }

    class HorizSettingsStackView: UIStackView {
        override required init(frame: CGRect) {
            super.init(frame: frame)
            initialSetup()
        }

        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func initialSetup() {
            self.axis = NSLayoutConstraint.Axis.horizontal
            self.distribution = UIStackView.Distribution.fillProportionally
            self.spacing = 40.0

            self.translatesAutoresizingMaskIntoConstraints = false
        }
    }
}
