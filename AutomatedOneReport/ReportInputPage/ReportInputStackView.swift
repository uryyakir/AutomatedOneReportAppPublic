//
//  ReportInputStackView.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 10/5/20.
//

import UIKit

class ReportInputStackView: UIStackView {
    var singleInputList: [SingleReportInputHorizStackView] = []

    override required init(frame: CGRect) {
        super.init(frame: frame)
        setupInput()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupInput()
    }

    private func setupInput() {
        initialSetup()
        getSingleInputs()  // this gets self.singleInputList updated
        for horizStackView in self.singleInputList {
            // iterating over singleInputList (containing all Horizontal Stackviews) and adding them to vertical Stackview
            self.addArrangedSubview(horizStackView)
        }
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    private func initialSetup() {
        self.axis = NSLayoutConstraint.Axis.vertical
        self.distribution = UIStackView.Distribution.equalSpacing
        self.spacing = 10.0
    }

    static func getRelevantDates(with_day: Bool = false) -> [String] {
        // This function supports two return types:
        // 1) An array of dates WITH days (AKA ["יום שלישי 17/11/2020", ...])
        // 2) An array of dates WITHOUT days (AKA ["17/11/2020", "18/11/2020", ...]
        let dayNamesDict = [
            1: "יום ראשון",
            2: "יום שני",
            3: "יום שלישי",
            4: "יום רביעי",
            5: "יום חמישי"
        ]
        let currentDate =  Date()
        var tempDate = Date()
        var dateArray: [Date] = []
        var incrementDateComponent = DateComponents()

        for i in 0...(14-currentDate.getWeekDay) {
            incrementDateComponent.day = i
            tempDate = Calendar.current.date(byAdding: incrementDateComponent, to: currentDate)!
            if ![6, 7].contains(tempDate.getWeekDay) {
                dateArray.append(tempDate)
            }
        }
        if with_day {
            return dateArray.map {"\(dayNamesDict[$0.getWeekDay]!)\n\($0.string(format: "dd/MM/yyyy"))"}
        }
        else {
            return dateArray.map {"\($0.string(format: "dd/MM/yyyy"))"}
        }
    }

    private func getSingleInputs() {
        for dateStr in ReportInputStackView.getRelevantDates(with_day: true) {
            self.singleInputList.append(SingleReportInputHorizStackView(frame: CGRect(), dateString: dateStr))
        }
    }

    func visualizeCurrentData(data: [String: String]) {
        // This function updates the user's screen with his previous data, as reported by the /get-user-data API
        for singleInputObject in self.singleInputList {
            let singleInputDatePart = String(singleInputObject.dateString.split(separator: "\n")[1])  // only getting date part of dateString
            if data[singleInputDatePart] != nil {
                let currentValue = data[singleInputDatePart]
                if currentValue == "אני בבסיס" {
                    // simulating a click on the ArmyButton (invoking gun rotation)
                    DispatchQueue.main.async {
                        singleInputObject.handleInArmyButtonClicked(sender: (singleInputObject.singleReportObjects["inArmy"]!["object"] as? UIButton)!)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        let outsideUnitDictionary = singleInputObject.singleReportObjects["outsideUnit"]!
                        let outsideUnitObject = (outsideUnitDictionary["object"] as? UIButton)
                        (outsideUnitDictionary["objectTitle"] as? UILabel)!.text = currentValue
                        // replacing background image with outsideUnit colored house image
                        outsideUnitObject!.setBackgroundImage((outsideUnitDictionary["onImage"] as? UIImage)!.alpha(singleInputObject.outsideUnitIconColoredAlpha), for: .normal)
                        outsideUnitObject!.tag = 1
                    }
                }
            }
        }
    }
}
