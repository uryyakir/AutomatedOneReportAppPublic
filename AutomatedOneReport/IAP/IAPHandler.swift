//
//  IAPHandler.swift
//  דוח 1 אוטומטי
//
//  Created by Uri Yakir on 13/12/2020.
//

import Foundation
import StoreKit

extension IAPViewController {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let buttonObject = (StoredProperties.IAPObjects[StoredProperties.IAPPairs[transaction.payment.productIdentifier]!]!["buttonObject"] as? UIButton)!
            let loadingIndicatorView = buttonObject.viewWithTag(1)

            switch transaction.transactionState {
            case .purchasing:
                break

            case .purchased, .restored:
                notifyServerAboutBuyer(productID: transaction.payment.productIdentifier)
                IAPStackView.toggleUserInteraction(true)
                DispatchQueue.main.async {
                    loadingIndicatorView?.removeFromSuperview()
                }
                IAPViewController.representAlreadyPurchased(buttonObject: buttonObject)
                // adding product to list of purchased IAPs
                // when rebuilding IAPViewController (to remove the banner) - this will allow the ViewController to present the IAP product as already purchased
                ViewController.StoredProperties.iapPurchased.append(transaction.payment.productIdentifier)
                // Notifying ViewController that banner should be removed
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "removeBanner"), object: nil, userInfo: nil)

                SKPaymentQueue.default().finishTransaction(transaction)
                SKPaymentQueue.default().remove(self)

            default:
                IAPStackView.toggleUserInteraction(true)
                DispatchQueue.main.async {
                    loadingIndicatorView?.removeFromSuperview()
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                SKPaymentQueue.default().remove(self)
            }
        }
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if let product = response.products.first {
            StoredProperties.IAPProduct = product
            // only calling actual make transaction handler after setting IAPProduct
            _makeTransaction()
        }
    }

    func fetchProducts(productID: String) {
        let request = SKProductsRequest(productIdentifiers: [productID])
        request.delegate = self
        request.start()
    }

    func makeTransaction(sender: UIButton, productID: String) {
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 15, width: 50, height: 50))
        loadingIndicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.whiteLarge
        loadingIndicator.startAnimating()
        loadingIndicator.tag = 1
        sender.addSubview(loadingIndicator)

        fetchProducts(productID: productID)
    }

    private func _makeTransaction() {
        guard let IAPProduct = StoredProperties.IAPProduct else { return }
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: IAPProduct)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
        }
    }

    private func notifyServerAboutBuyer(productID: String) {
        ViewController.makeAPICommunication(self, route: "index-iap-buyer", requestType: "POST", withCompletion: { _ in }, data: [
            "VENDOR_UUID": ViewController.StoredProperties.userTaz,
            "PRODUCT_ID": productID
        ])
    }

    static func representAlreadyPurchased(buttonObject: UIButton) {
        DispatchQueue.main.async {
            // we wanna avoid doing this multiple times for the same button - it causes visual and software bugs
            if buttonObject.isUserInteractionEnabled {
                buttonObject.isUserInteractionEnabled = false
                buttonObject.setImage(UIImage(named: "check-mark"), for: .normal)
                buttonObject.setBackgroundImage(buttonObject.backgroundImage(for: .normal)!.alpha(0.2), for: .normal)
                buttonObject.superview?.backgroundColor = StoredProperties.boughtBackgroundGreen
                buttonObject.backgroundColor = StoredProperties.backgroundCyan
            }
        }
    }

    static func visualizeAlreadyPurchased() {
        // visualizing already bought IAP on app-start
        for productId in ViewController.StoredProperties.iapPurchased {
            let buttonObject = (StoredProperties.IAPObjects[StoredProperties.IAPPairs[productId]!]!["buttonObject"] as? UIButton)!
            IAPViewController.representAlreadyPurchased(buttonObject: buttonObject)
        }
    }

    @objc func attemptIAPRestore() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}
