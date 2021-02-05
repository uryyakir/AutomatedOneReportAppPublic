//
//  IAPStackView.swift
//  דוח 1 אוטומטי
//
//  Created by Uri Yakir on 13/12/2020.
//

import Foundation
import UIKit

extension IAPViewController {
    class IAPStackView: UIStackView {
        let IAPController: UIViewController
        var cardView: CardView!

        required init(frame: CGRect, IAPController: UIViewController) {
            self.IAPController = IAPController
            super.init(frame: frame)

            initialSetup()
            buildIAPS()
        }

        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func initialSetup() {
            self.axis = NSLayoutConstraint.Axis.vertical
            self.distribution = UIStackView.Distribution.equalSpacing
            self.alignment = .center
            self.spacing = 10
            self.translatesAutoresizingMaskIntoConstraints = false
        }

        private func buildIAPS() {
            for sortedKey in Array(IAPViewController.StoredProperties.IAPPairs.keys).sorted(by: { $0 > $1 }) {
                // iterating over IAP IDs in order (tier 3 first)
                for (IAPKey, IAPValue) in IAPViewController.StoredProperties.IAPObjects where (sortedKey == (IAPValue["productId"]! as? String)!) {
                    // fetching IAP data object
                    self.cardView = CardView(frame: CGRect())
                    // create IAP labels and button
                    let (iapTitleLabel, iapSecondaryTitleLabel, iapButton) = createIAPObjects(IAPKey: IAPKey, IAPValue: IAPValue)
                    // cardView click should be equvilant to button click
                    let cardViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCardViewPress))
                    self.cardView.addGestureRecognizer(cardViewTapGesture)
                    // adding to cardView
                    self.cardView.addSubview(iapTitleLabel)
                    self.cardView.addSubview(iapSecondaryTitleLabel)
                    self.cardView.addSubview(iapButton)
                    self.addArrangedSubview(self.cardView)
                    // constraining objects
                    constrainCardView()
                    constrainIAPTitleLabel(iapTitleLabel: iapTitleLabel, iapSecondaryTitleLabel: iapSecondaryTitleLabel)
                    constrainIAPButton(iapButton: iapButton)
                }
            }
        }

        private func constrainCardView() {
            // constraining cardView
            self.cardView.heightAnchor.constraint(equalToConstant: 185).isActive = true
            self.cardView.widthAnchor.constraint(equalToConstant: self.frame.width-60).isActive = true
        }

        private func constrainIAPTitleLabel(iapTitleLabel: UILabel, iapSecondaryTitleLabel: UILabel) {
            // constraining title labels
            iapTitleLabel.topAnchor.constraint(equalTo: self.cardView.topAnchor, constant: 15).isActive = true
            iapTitleLabel.widthAnchor.constraint(equalTo: self.cardView.widthAnchor, constant: 0).isActive = true
            iapSecondaryTitleLabel.topAnchor.constraint(equalTo: iapTitleLabel.bottomAnchor, constant: 15).isActive = true
            iapSecondaryTitleLabel.widthAnchor.constraint(equalTo: cardView.widthAnchor, constant: 0).isActive = true
        }

        private func constrainIAPButton(iapButton: UIButton) {
            // constraining button
            iapButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor).isActive = true
            iapButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -30).isActive = true
        }

        private func getIAPButton(imageName: String) -> UIButton {
            let button = UIButton(type: .custom)
            button.setBackgroundImage(UIImage(named: imageName), for: .normal)
            button.addTarget(self, action: #selector(handleIAPButton), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false

            button.layer.cornerRadius = 5
            button.backgroundColor = StoredProperties.backgroundCyan
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.black.cgColor

            return button
        }

        private func createIAPObjects(IAPKey: String, IAPValue: [String: UIObjects]) -> (UILabel, UILabel, UIButton) {
            // creating labels
            let iapTitleLabel = SettingsViewController.StoredProperties.getSettingsTitle((IAPValue["title"]! as? String)!, fontSize: StoredProperties.IAPLabelFontSize + 5)
            let iapSecondaryTitleLabel = SettingsViewController.StoredProperties.getSettingsTitle((IAPValue["secondaryTitle"]! as? String)!, fontSize: StoredProperties.IAPLabelFontSize)
            // creating button
            let iapButton = getIAPButton(imageName: (IAPValue["image"]! as? String)!)
            IAPViewController.StoredProperties.IAPObjects[IAPKey]!["buttonObject"] = iapButton  // storing for later reference
            // minor label adjustments
            iapTitleLabel.textColor = .white
            iapSecondaryTitleLabel.textColor = .white

            return (iapTitleLabel, iapSecondaryTitleLabel, iapButton)
        }

        func reMatches(for regex: String, in text: String) -> [String] {
            do {
                let regex = try NSRegularExpression(pattern: regex)
                let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                return results.map { String(text[Range($0.range, in: text)!]) }
            }
            catch let error {
                print("invalid regex: \(error.localizedDescription)")
                return []
            }
        }

        static func toggleUserInteraction(_ bool: Bool) {
            // toggeling enableUserInteraction on and off
            for button in StoredProperties.IAPObjects.values where !ViewController.StoredProperties.iapPurchased.contains((button["productId"] as? String)!) {
                // only toggeling where toggle should actually be done (AKA - IAP that weren't already purchased)
                (button["buttonObject"] as? UIButton)!.isUserInteractionEnabled = bool
            }
        }

        @objc func handleIAPButton(sender: UIButton) {
            // preventing additional clicks
            IAPStackView.toggleUserInteraction(false)
            let buttonRepr = sender.backgroundImage(for: .normal)!.description
            let tier = reMatches(for: "(gold|silver|bronze)", in: buttonRepr)[0]
            (self.IAPController as? IAPViewController)?.makeTransaction(sender: sender, productID: (IAPViewController.StoredProperties.IAPObjects[tier]!["productId"]! as? String)!)
        }

        @objc func handleCardViewPress(_ sender: UITapGestureRecognizer) {
            for case let iapButton as UIButton in sender.view!.subviews {
                if iapButton.isUserInteractionEnabled { iapButton.sendActions(for: .touchUpInside) }
                break
            }
        }
    }

    class CardView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupView()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setupView()
        }

        private func setupView() {
            self.backgroundColor = .lightGray
            self.layer.cornerRadius = 10.0
            self.layer.shadowColor = UIColor.gray.cgColor
            self.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
            self.layer.shadowRadius = 6.0
            self.layer.shadowOpacity = 0.7
            self.translatesAutoresizingMaskIntoConstraints = false
        }
    }
}
