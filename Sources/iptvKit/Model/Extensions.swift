//
//  Extensions.swift
//  IPTVee
//
//  Created by Todd Bruss on 10/3/21.
//

import Foundation
import SwiftUI

extension RangeReplaceableCollection where Self: StringProtocol {
    var digits: Self { filter(\.isWholeNumber) }
}

public extension DispatchQueue {
    
     static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
}

public extension String {
    var base64Decoded: String? {
         String(data: Data(base64Encoded: self) ?? Data(), encoding: .utf8)
    }
}

public extension String {
    func removingLeadingSpaces() -> String {
        guard let index = firstIndex(where: { !CharacterSet(charactersIn: String($0)).isSubset(of: .whitespaces) }) else {
            return self
        }
        return String(self[index...])
    }
}

public extension Date {
    func userTimeZone( initTimeZone: TimeZone = TimeZone(identifier: iptvKit.LoginObservable.shared.config?.serverInfo.timezone ?? "America/New_York") ?? TimeZone(abbreviation: "EST") ?? .autoupdatingCurrent , timeZone: TimeZone = .autoupdatingCurrent) -> Date {
        let delta = TimeInterval(timeZone.secondsFromGMT(for: self) - initTimeZone.secondsFromGMT(for: self))
        return addingTimeInterval(delta)
    }
}

// Reports if our device have a notch
public extension UIDevice {
    var hasNotch: Bool {
        let bottom = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
}


extension UIImage {

    func squareMe() -> UIImage {

        var squareImage = self
        let maxSize = max(self.size.height, self.size.width)
        let squareSize = CGSize(width: maxSize, height: maxSize)

        let dx = CGFloat((maxSize - self.size.width) / 2)
        let dy = CGFloat((maxSize - self.size.height) / 2)

        UIGraphicsBeginImageContext(squareSize)
        var rect = CGRect(x: 0, y: 0, width: maxSize, height: maxSize)

        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(UIColor.systemGray6.cgColor)
            context.fill(rect)

            rect = rect.insetBy(dx: dx, dy: dy)
            self.draw(in: rect, blendMode: .normal, alpha: 1.0)

            if let img = UIGraphicsGetImageFromCurrentImageContext() {
                squareImage = img
            }
            UIGraphicsEndImageContext()

        }

        return squareImage
    }
}


public extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}

public extension Array where Element == UInt8 {
    var data: Data {
        return Data(self)
    }
}

public extension String {

    func toDate(withFormat format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)
        return date
    }
}

public extension Date {
    func toString(withFormat format: String = "h:mm a") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let str = dateFormatter.string(from: self)
        return str
    }
}
