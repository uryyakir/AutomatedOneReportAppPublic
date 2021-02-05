//
//  ServerAPICommunication.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 02/11/2020.
//

import Foundation
import UIKit
import SwiftyJSON

extension ViewController {
    @objc func sendReportToServer() {
        ViewController.BuildUIAlert(self, message: "מעדכן פרטים, אנא המתן...", withLoadingAnimation: true, presentCompletion: {
            self._sendReportToServer()
        })
    }

    private func _sendReportToServer() {
        // This function grabs the data from the app's report form and attempts to send it to storage API
        let datesArray = ReportInputStackView.getRelevantDates()
        let horizInputsList = StoredProperties.reportInputStackView.singleInputList
        let group = DispatchGroup()
        var successFlag = true  // assuming all went well (if an API call failed, successFlag will change accordingly)
        var foundValues = 0

        for i in 0..<horizInputsList.count {
            group.enter()
            let getKey = (horizInputsList[i].singleReportObjects["inArmy"]!["object"] as? UIButton)!.tag == 1 ? "בבסיס!": (horizInputsList[i].singleReportObjects["outsideUnit"]!["objectTitle"] as? UILabel)!.text!

            var dataJSON = [
                "VENDOR_UUID": StoredProperties.userTaz,
                "DATE": datesArray[i]
            ]
            guard let codeMapVals = ViewController.codeMaps[getKey] else {
                // sending VENDOR_UUID  & DATE to index-user-data API to delete status if one exists.
                // If a status exists for that date, it means that the user has unset that status.
                sendToServer(data: dataJSON, withCompletion: { response in
                    if !response["success"].bool! {
                        // some API call failed (couldn't index properly within the elastic index)
                        successFlag = false  // grabbing status code
                    }
                })
                group.leave()
                continue
            }
            foundValues = 1
            dataJSON += codeMapVals  // appending codeMap Key-Val sets to dataJSON (via definition of += operand for dictionaries)

            sendToServer(data: dataJSON, withCompletion: { response in
                if !response["success"].bool! {
                    // some API call failed (couldn't index properly within the elastic index)
                    successFlag = false  // grabbing status code
                }
                group.leave()
            })
        }
        group.notify(queue: DispatchQueue.main) {
            if foundValues == 1 {
                self.presentSuccessStatus(flag: successFlag)
            }
            else {
                self.dismiss(animated: true, completion: {
                    ViewController.BuildUIAlert(self, message: "אנא הכנס מידע כלשהו!", appearanceTime: 3.0)
                })
            }
        }
    }

    static func makeAPICommunication(_ viewController: UIViewController, route: String, requestType: String, failureValue: Any = false, withCompletion completion: @escaping (_ json: JSON) -> Void, data: [String: String] = [:]) {
        if ViewController.StoredProperties.userTaz == "".sha256 { ViewController.APIFailure(viewController); return }  // if, for some reason, userTaz was not updated - we don't want to allow any API calls
        let url: String = "\(ViewController.StoredProperties.apiEndpoint)\(route)"
        guard let serviceUrl = URL(string: url) else {
            ViewController.APIFailure(viewController)
            completion(JSON(["success": failureValue, "url": url]))
            return
        }
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = requestType
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if request.httpMethod == "POST" {
            guard let httpBody = try? JSONSerialization.data(withJSONObject: data, options: []) else {
                ViewController.APIFailure(viewController)
                completion(JSON(["success": failureValue, "url": url]))
                return
            }
            request.httpBody = httpBody
        }
        request.timeoutInterval = 10
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            // if we actually NEED the data from the API request
            if let response = (response as? HTTPURLResponse) {
                if response.statusCode != 200 {
                    ViewController.APIFailure(viewController)
                    completion(JSON(["success": failureValue, "url": url]))
                    return
                }
            }
            if let data = data {
                // checking if there was actual data returned by API
                if String(data: data, encoding: .utf8)! != "200" {
                    do {
                        try completion(JSON(["success": true, "data": JSON(data: data)]))
                        return
                    }
                    catch _ {
                        ViewController.APIFailure(viewController)
                        completion(JSON(["success": failureValue, "url": url]))
                        return
                    }
                }

                // the data returned was simply the "200" status code
                else {
                    completion(JSON(["success": true]))
                    return
                }
            }
            if error != nil {
                ViewController.APIFailure(viewController)
                completion(JSON(["success": failureValue, "url": url]))
                return
            }
        }
        task.resume()
    }

    func sendToServer(data: [String: String], withCompletion completion: @escaping (_ json: JSON) -> Void) {
        // sending an HTTP POST request to transfer each day's data to API
        ViewController.makeAPICommunication(self, route: "index-user-data", requestType: "POST", withCompletion: { response in
            completion(response)
            return
        }, data: data)
    }

    func getUserReport(withCompletion completion: @escaping (_ json: JSON) -> Void) {
        // when a user re-enters the app, we would like to show him his current report status
        // to do that, we use a POST HTTP request (containing the VENDOR_UUID) and sending that to the API
        let parameters: [String: String] = ["VENDOR_UUID": StoredProperties.userTaz]
        ViewController.makeAPICommunication(self, route: "get-user-data", requestType: "POST", withCompletion: { response in
            completion(response)
            return
        }, data: parameters)
    }

    func userCookieAvailability(withCompletion completion: @escaping (_ json: JSON) -> Void) {
        let parameters: [String: String] = ["VENDOR_UUID": StoredProperties.userTaz]
        ViewController.makeAPICommunication(self, route: "get-user-cookie-availability", requestType: "POST", withCompletion: { response in
            completion(response)
            return
        }, data: parameters)
    }

    func indexUserCookie(cookieDict: [String: String]?, withCompletion completion: @escaping (_ json: JSON) -> Void) {
        guard cookieDict != nil else { return }
        var parameters: [String: String] = ["VENDOR_UUID": StoredProperties.userTaz]
        parameters += cookieDict!
        ViewController.makeAPICommunication(self, route: "index-user-cookie", requestType: "POST", withCompletion: { response in
            completion(response)
            return
        }, data: parameters)
    }

    func getScheduledSubmissionHour(withCompletion completion: @escaping (_ hour: JSON) -> Void) {
        ViewController.makeAPICommunication(self, route: "scheduled-submission-hour", requestType: "GET", withCompletion: { response in
            completion(response)
            return
        })
    }

    func getCodeMaps(withCompletion completion: @escaping (_ json: JSON) -> Void) {
        ViewController.makeAPICommunication(self, route: "get-code-maps", requestType: "GET", withCompletion: { response in
            completion(response)
            return
        })
    }

    func getOutsideUnitOptions(withCompletion completion: @escaping (_ json: JSON) -> Void) {
        ViewController.makeAPICommunication(self, route: "get-outside-unit-options", requestType: "GET", withCompletion: { response in
            completion(response)
            return
        })
    }

    func isIAPBuyer(withCompletion completion: @escaping (_ json: JSON) -> Void) {
        ViewController.makeAPICommunication(self, route: "is-iap-buyer", requestType: "POST", withCompletion: { response in
            completion(response)
            return
        }, data: ["VENDOR_UUID": StoredProperties.userTaz])
    }

    func getLatestVersion(withCompletion completion: @escaping (_ json: JSON) -> Void) {
        ViewController.makeAPICommunication(self, route: "get-latest-version", requestType: "GET", withCompletion: { response in
            completion(response)
            return
        })
    }

    func checkCookieAvailability() {
        userCookieAvailability(withCompletion: { response in
            guard let cookieExistsBool = response["data"]["exists"].bool else {
                ViewController.BuildUIAlert(self, title: "אירעה שגיאה בתקשורת עם השרת!", message: "אנא וודא שאתה מחובר לאינטרנט ופתח מחדש את האפליקציה", backgroundColor: ViewController.StoredProperties.redAlertColor, appearanceTime: 6.0)
                return
            }

            if !cookieExistsBool {
                NotificationCenter.default.addObserver(self, selector: #selector(self.webViewClosed), name: NSNotification.Name(rawValue: "webViewClosed"), object: nil)
                DispatchQueue.main.async {
                    self.view.addSubview(self.setupWebController())  // adding the webView as a subview
                }
            }
            else {
                DispatchQueue.main.async {
                    self.calculateSettingsAPIConstants()
                    self.setupInputPage()
                }
            }
        })
    }

    func updateRequired() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        self.getLatestVersion(withCompletion: { response in
            if response["data"]["should_notify"].bool != nil {
                // this can happen if user has no internet connection
                if response["data"]["should_notify"].bool! {
                    if response["data"]["latest_version"].string! > appVersion! && response["data"]["breaking_changes"].bool! {
                        ViewController.BuildUIAlert(self, title: "עדכון חדש זמין לאפליקציה!", message: "על מנת להמשיך להשתמש באפליקציה, יש לעדכן אותה! מתנצלים על אי-הנוחות", backgroundColor: ViewController.StoredProperties.grayAlertColor, appearanceTime: 300.0, withLoadingAnimation: false)
                        sleep(300)
                    }

                    else if response["data"]["latest_version"].string! > appVersion! {
                        ViewController.BuildUIAlert(self, title: "עדכון חדש זמין לאפליקציה!", message: "מומלץ בחום לעדכן. העדכונים מכילים לרוב תיקוני באגים, שיפורי ביצועים ופיצ׳רים נוספים!", backgroundColor: ViewController.StoredProperties.grayAlertColor, appearanceTime: 3.0, withLoadingAnimation: false)
                        sleep(3)
                    }
                }

                else if !response["success"].bool! {
                    // since this is the first API call done in the application, we need to freeze execution
                    sleep(300)
                }
            }
            else {
                // since this is the first API call done in the application, we need to freeze execution
                sleep(300)
            }
        })
    }

    func populateStaticValues(withCompletion completion: @escaping () -> Void) {
        self.getCodeMaps(withCompletion: { result in
            ViewController.codeMaps = (result["data"].dictionaryObject! as? [String: [String: String]])!
        })

        self.getOutsideUnitOptions(withCompletion: { result in
            ViewController.outsideUnitMainOptions = result["data"].dictionaryObject!.keys
            ViewController.outsideUnitSecondaryOptions = (result["data"].dictionaryObject! as? [String: [String]])!
        })

        self.isIAPBuyer(withCompletion: { result in
            ViewController.StoredProperties.adsRemovalEligible = result["data"]["eligible"].bool!
            ViewController.StoredProperties.iapPurchased = (result["data"]["iap_purchased"].arrayObject! as? [String])!
            completion()
            return
        })
    }

    static func APIFailure(_ viewController: UIViewController) {
        if !ViewController.StoredProperties.APIFailureShown {
            ViewController.StoredProperties.APIFailureShown = true
            DispatchQueue.main.async {
                if let alertView = (viewController.presentedViewController as? UIAlertController) {
                    // if some other alertController is already showing
                    alertView.dismiss(animated: true, completion: {
                        // dismiss and present failure
                        self.BuildUIAlert(viewController, title: "אירעה שגיאה בתקשורת עם השרת!", message: "אנא וודא שאתה מחובר לאינטרנט ופתח מחדש את האפליקציה", backgroundColor: ViewController.StoredProperties.redAlertColor, appearanceTime: 6.0)
                    })
                }
                else {
                    self.BuildUIAlert(viewController, title: "אירעה שגיאה בתקשורת עם השרת!", message: "אנא וודא שאתה מחובר לאינטרנט ופתח מחדש את האפליקציה", backgroundColor: ViewController.StoredProperties.redAlertColor, appearanceTime: 6.0)
                }
            }
        }
    }
}
