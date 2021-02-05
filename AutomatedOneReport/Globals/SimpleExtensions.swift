//
//  simpleExtensions.swift
//  AutomatedOneReport
//
//  Created by Uri Yakir on 16/11/2020.
//

import Foundation
import SwiftyJSON
import CommonCrypto

// ServerAPICommunication.swift extensions
func += <K, V> (left: inout [K: V], right: [K: V]) {
    for (k, v) in right {
        left[k] = v
    }
}

// ViewControllerReportUserInput.swift
class Formatter {
    private static var internalJsonDateFormatter: DateFormatter?
    private static var internalJsonDateTimeFormatter: DateFormatter?

    static var jsonDateFormatter: DateFormatter {
        if internalJsonDateFormatter == nil {
            internalJsonDateFormatter = DateFormatter()
            internalJsonDateFormatter!.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        }
        return internalJsonDateFormatter!
    }
}

extension JSON {
    public var date: Date? {
        get {
            switch self.type {
            case Type.string:
                return Formatter.jsonDateFormatter.date(from: (self.rawValue as? String)!)
            default:
                return nil
            }
        }
    }
}

// reportInputStackView.swift extensions
extension UIImage {
    func alpha(_ value: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

    func getRotationList(radians: Float, splitCount: Int) -> [UIImage] {
        var rotationList: [UIImage] = []
        for i in 0...splitCount {
            rotationList.append(self.rotate(radians: radians * (Float(i)/Float(splitCount)))!)
        }
        return rotationList
    }

    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its centre
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

extension Date {
    func string(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    var getWeekDay: Int {
        return Calendar.current.component(.weekday, from: self)
    }

    var startOfWeek: Date? {
        let GregorianCal = Calendar(identifier: .gregorian)
        guard let sun = GregorianCal.date(from: GregorianCal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return GregorianCal.date(byAdding: .day, value: 1, to: sun)
    }
}

extension String {
    var sha256: String {
        let strData = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        strData.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash).map { String(format: "%02X", $0) }.joined()
    }
}

extension UIView {
    var setLayer: UIView {
        self.backgroundColor = ViewController.StoredProperties.originalSiteColor
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 2.0
        self.layer.cornerRadius = 10.0
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        self.layer.shadowRadius = 6.0
        self.layer.shadowOpacity = 0.7
        return self
    }
}
