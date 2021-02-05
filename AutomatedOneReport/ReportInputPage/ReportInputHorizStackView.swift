//
//  SingleReportInputHorizStackView.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 16/11/2020.
//

import Foundation
import UIKit
import ActionSheetPicker_3_0

protocol UIObjects {}
extension UIButton: UIObjects { }
extension UILabel: UIObjects { }
extension UIImage: UIObjects { }
extension String: UIObjects { }

class SingleReportInputHorizStackView: UIStackView {
    let dateString: String

    let buttonRifleBG: UIImage
    let buttonRifleBGAlpha: CGFloat = 0.55
    let buttonRifleBGColored: UIImage
    let buttonRifleBGColoredAlpha: CGFloat = 1.0

    let outsideUnitIcon: UIImage
    let outsideUnitIconAlpha: CGFloat = 0.15
    let outsideUnitIconColoredAlpha: CGFloat = 1

    var singleReportObjects: [String: [String: UIObjects]]

    required init(frame: CGRect, dateString: String) {
        self.dateString = dateString
        self.buttonRifleBG = UIImage(named: "smaller-assault-rifle original")!.alpha(buttonRifleBGAlpha)
        self.buttonRifleBGColored = UIImage(named: "smaller-assault-rifle colored")!.alpha(buttonRifleBGColoredAlpha)
        self.outsideUnitIcon = UIImage(named: "smaller-house")!
        self.singleReportObjects = [:]
        super.init(frame: frame)

        setupSingleHorizInput()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSingleHorizInput() {
        initialSetup()
        let (dateOneLabel, inArmyButton, outsideUnit) = getLabels()

        self.addArrangedSubview(dateOneLabel)
        self.addArrangedSubview(inArmyButton)
        self.addArrangedSubview(outsideUnit)
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    private func initialSetup() {
        self.axis = NSLayoutConstraint.Axis.horizontal
        self.distribution = UIStackView.Distribution.fill
        self.alignment = UIStackView.Alignment.center
        // adding customized spacing for each possible width of ios devices
        let screenWidth = UIScreen.main.bounds.width
        switch screenWidth {
        case 320:
            // darn you, iPhone SE Gen1
            self.spacing = 5
            ViewController.StoredProperties.updateSmallScreenConstants()
        case 375:
            self.spacing = 10
        default:
            // calculating needed spacing by comparing screenWidth to minimum screenWidth and calculating the difference with percents
            self.spacing = 10 + (10 * (1 + (screenWidth - 375)/375))
        }
    }

    private func runTimedAnimation(sender: UIButton, transformationList: [UIImage]) {
        // This function is responsible for gun rotation for the inArmy button
        // It recieves a transformation-list, which is essentialy a sequence of images, each slightly more rotated that the previous
        // The rotation is done by sequentially presenting the images one after the other
        sender.isUserInteractionEnabled = false
        let outsideUnitButton = (self.singleReportObjects["outsideUnit"]!["object"] as? UIButton)!
        outsideUnitButton.isUserInteractionEnabled = false  // this function is only called for inArmy Button, but we don't want outsideUnitButton to recieve clicks while inArmy is rotating

        var i = 0
        Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true) { timer in
            if i == transformationList.count {
                // done rotating
                timer.invalidate()
                sender.isUserInteractionEnabled = true
                outsideUnitButton.isUserInteractionEnabled = true
            }
            else {
                if sender.tag == 1 {
                    sender.setBackgroundImage(transformationList[i].alpha(self.buttonRifleBGColoredAlpha), for: .normal)
                }
                else if sender.tag == 0 {
                    sender.setBackgroundImage(transformationList[i].alpha(self.buttonRifleBGAlpha), for: .normal)
                }
                i += 1
            }
        }
    }

    private func showOutsideUnitButtonPicker(whichButton: String, sender: UIButton) {
        let alert = ActionSheetMultipleStringPicker.init(
            title: "איפה את/ה?",
            rows: [Array(ViewController.outsideUnitMainOptions)],
            initialSelection: [0],
            doneBlock: { _, _, values in
                let value = (values as? [String])![0]
                self.getSecondaryAlert(mainCategory: value, whichButton: whichButton, sender: sender).show()
                return
            },
            cancel: { _ in
                self.handleButtons(sender: sender, whichButton: whichButton, type: "clicked") // recursively callling function as if the button was pressed while it's on
                return
            },
            origin: sender
        )!

        let attributedStringColor = [NSMutableAttributedString.Key.foregroundColor: UIColor.black]
        alert.titleTextAttributes = attributedStringColor
        alert.setTextColor(.black)
        alert.pickerBackgroundColor = ViewController.StoredProperties.originalSiteColor
        alert.toolbarBackgroundColor = ViewController.StoredProperties.originalSiteColor
        alert.show()
    }

    private func getSecondaryAlert(mainCategory: String, whichButton: String, sender: UIButton) -> ActionSheetMultipleStringPicker {
        let secondaryAlert = ActionSheetMultipleStringPicker.init(
            title: "איפה בדיוק?",
            rows: [ViewController.outsideUnitSecondaryOptions[mainCategory]!],
            initialSelection: [0],
            doneBlock: { _, _, values in
                let value = (values as? [String])![0]
                (self.singleReportObjects[whichButton]!["objectTitle"] as? UILabel)!.text = value
                // only displaying green border if user actually chose some value
                self.isEmptyDay()
                return
            },
            cancel: { _ in
                self.handleButtons(sender: sender, whichButton: whichButton, type: "clicked") // recursively callling function as if the button was pressed while it's on
                return
            },
            origin: sender
        )!

        let attributedStringColor = [NSMutableAttributedString.Key.foregroundColor: UIColor.black]
        secondaryAlert.titleTextAttributes = attributedStringColor
        secondaryAlert.setTextColor(.black)
        secondaryAlert.pickerBackgroundColor = ViewController.StoredProperties.originalSiteColor
        secondaryAlert.toolbarBackgroundColor = ViewController.StoredProperties.originalSiteColor
        return secondaryAlert
    }

    @objc func handleInArmyButtonClicked(sender: UIView) {
        if sender is UIButton {
            handleButtons(sender: (sender as? UIButton)!, whichButton: "inArmy", type: "clicked")
        }
        else if type(of: sender) == UITapGestureRecognizer.self {
            // will get here if the button's label was clicked (sender's type would be UITapGestureRecognizer)
            handleButtons(sender: (self.singleReportObjects["inArmy"]!["object"] as? UIButton)!, whichButton: "inArmy", type: "clicked")
        }
    }

    @objc private func handleOutsideUnitButtonClicked(sender: UIView) {
        if sender is UIButton {
            handleButtons(sender: (sender as? UIButton)!, whichButton: "outsideUnit", type: "clicked")
        }
        else if type(of: sender) == UITapGestureRecognizer.self {
            // will get here if the button's label was clicked (sender's type would be UITapGestureRecognizer)
            handleButtons(sender: (self.singleReportObjects["outsideUnit"]!["object"] as? UIButton)!, whichButton: "outsideUnit", type: "clicked")
        }
    }

    func isEmptyDay() {
        let dateLabel = (self.singleReportObjects["dateOne"]!["object"] as? UILabel)!
        if (self.singleReportObjects["inArmy"]!["object"] as? UIButton)!.tag == 0 && (self.singleReportObjects["outsideUnit"]!["object"] as? UIButton)!.tag == 0 {
            dateLabel.textColor = .lightGray
            dateLabel.alpha = 0.5
        }
        else {
            dateLabel.textColor = .black
            dateLabel.alpha = 1
        }
    }

    private func handleButtons(sender: UIButton, whichButton: String, type: String) {
        let otherButtonName = ["inArmy", "outsideUnit"].filter {$0 != whichButton}  // finding the name of the otherButton
        let otherButton = (self.singleReportObjects[otherButtonName[0]]!["object"] as? UIButton)!  // grabbing the other UIButton object
        let getButtonObject = self.singleReportObjects[whichButton]
        let getButtonOnImage = (getButtonObject!["onImage"] as? UIImage)!
        let getButtonOffImage = (getButtonObject!["offImage"] as? UIImage)!

        if type == "clicked" {
            if sender.tag == 0 {
                // button was turned on
                sender.tag = 1
                (getButtonObject!["objectTitle"] as? UILabel)!.text = (getButtonObject!["onText"] as? String)!
                // "turning off" other button by recursively calling handleButtons
                handleButtons(sender: otherButton, whichButton: otherButtonName[0], type: "assumed")

                if whichButton == "outsideUnit" {
                    sender.setBackgroundImage(getButtonOnImage.alpha(self.outsideUnitIconColoredAlpha), for: .normal)
                    showOutsideUnitButtonPicker(whichButton: whichButton, sender: sender)
                }

                else if whichButton == "inArmy" {
                    let transformList = getButtonOnImage.getRotationList(radians: .pi/2, splitCount: 80)
                    runTimedAnimation(sender: sender, transformationList: transformList)
                    isEmptyDay()
                }
            }

            else {
                // button was turned off
                sender.tag = 0
                // reset button text
                (getButtonObject!["objectTitle"] as? UILabel)!.text = (getButtonObject!["offText"] as? String)!

                if whichButton == "outsideUnit" {
                    sender.setBackgroundImage(sender.backgroundImage(for: .normal)!.alpha(self.outsideUnitIconAlpha), for: .normal)
                }

                else if whichButton == "inArmy" {
                    let transformList = getButtonOffImage.rotate(radians: .pi/2)!.getRotationList(radians: -.pi/2, splitCount: 80)
                    runTimedAnimation(sender: sender, transformationList: transformList)
                }
                isEmptyDay()
            }

            // updating singleReportObjects dictionary with current status sender
            self.singleReportObjects[whichButton]!["object"] = sender
        }

        else if type == "assumed" && sender.tag == 1 {
            // function will reach this condition for the OTHER button that needs resetting
            handleButtons(sender: sender, whichButton: whichButton, type: "clicked")
        }
    }

    private func getDateOneLabel() -> UILabel {
        let label = UILabel()
        label.text = self.dateString
        label.font = UIFont.systemFont(ofSize: ViewController.StoredProperties.dateLabelFontSize, weight: UIFont.Weight(200))
        label.textColor = .black
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        self.singleReportObjects["dateOne"] = ["object": label]
        return label
    }

    private func getInArmyStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        stackView.spacing = 0

        return stackView
    }

    private func getOutsideUnitStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        stackView.spacing = 7

        let widthContraints =  NSLayoutConstraint(item: stackView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 110)
        NSLayoutConstraint.activate([widthContraints])

        return stackView
    }

    private func getInArmyTitle() -> UILabel {
        let title = UILabel()
        title.textColor = UIColor.red
        title.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight(300))
        title.text = "בבסיס?"
        // adding tap functionality
        let inArmyTapGesture = UITapGestureRecognizer(target: self, action: #selector (self.handleInArmyButtonClicked))
        title.isUserInteractionEnabled = true
        title.addGestureRecognizer(inArmyTapGesture)

        return title
    }

    private func getInArmyButton(inArmyTitle: UILabel) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = ViewController.StoredProperties.originalSiteColor
        button.setBackgroundImage(self.buttonRifleBG.alpha(buttonRifleBGAlpha), for: .normal)

        button.addTarget(self, action: #selector(handleInArmyButtonClicked), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        let widthContraints =  NSLayoutConstraint(item: button, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: buttonRifleBG.size.width * buttonRifleBG.scale)
        let heightContraints = NSLayoutConstraint(item: button, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: buttonRifleBG.size.height * buttonRifleBG.scale)
        NSLayoutConstraint.activate([heightContraints, widthContraints])

        button.tag = 0  // this tag is used to determine wether the button is off or on

        self.singleReportObjects["inArmy"] = ["object": button, "objectTitle": inArmyTitle, "onImage": self.buttonRifleBGColored, "onText": "בבסיס!", "offImage": self.buttonRifleBG, "offText": "בבסיס?"]
        return button
    }

    private func getOutsideUnitTitle() -> UILabel {
        let title = UILabel()
        title.textColor = UIColor.blue
        title.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight(300))
        title.text = "מחוץ ליחידה?"
        title.lineBreakMode = .byWordWrapping
        title.numberOfLines = 0
        title.textAlignment = .center

        // adding tap functionality
        let outsideUnitTapGesture = UITapGestureRecognizer(target: self, action: #selector (self.handleOutsideUnitButtonClicked))
        title.isUserInteractionEnabled = true
        title.addGestureRecognizer(outsideUnitTapGesture)

        return title
    }

    private func getOutsideUnitButton(outsideUnitTitle: UILabel) -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        button.backgroundColor = ViewController.StoredProperties.originalSiteColor
        button.setBackgroundImage(self.outsideUnitIcon.alpha(outsideUnitIconAlpha), for: .normal)

        button.addTarget(self, action: #selector(handleOutsideUnitButtonClicked), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        button.tag = 0  // this tag is used to determine wether the button is off or on

        self.singleReportObjects["outsideUnit"] = ["object": button, "objectTitle": outsideUnitTitle, "onImage": self.outsideUnitIcon, "onText": "מחוץ ליחידה!", "offImage": self.outsideUnitIcon, "offText": "מחוץ ליחידה?"]
        return button
    }

    private func getLabels() -> (UILabel, UIStackView, UIStackView) {
        let dateOne = getDateOneLabel()
        let inArmyStackView = getInArmyStackView()
        let outsideUnitStackView = getOutsideUnitStackView()
        let inArmyTitle = getInArmyTitle()
        let inArmy = getInArmyButton(inArmyTitle: inArmyTitle)
        let outsideUnitTitle = getOutsideUnitTitle()
        let outsideUnit = getOutsideUnitButton(outsideUnitTitle: outsideUnitTitle)

        inArmyStackView.addArrangedSubview(inArmy)
        inArmyStackView.addArrangedSubview(inArmyTitle)
        outsideUnitStackView.addArrangedSubview(outsideUnit)
        outsideUnitStackView.addArrangedSubview(outsideUnitTitle)

        return (dateOne, inArmyStackView, outsideUnitStackView)
    }
}
