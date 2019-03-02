//
//  DateFormatter.swift
//  Eidetic
//
//  Created by user147964 on 12/28/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import Foundation
import UIKit
import Photos
import UserNotifications

//Convert UIImage for usernotification
extension UNNotificationAttachment {
    
    static func create(identifier: String, image: UIImage, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
        do {
            try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
            let imageFileIdentifier = identifier+".png"
            let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
            guard let imageData = image.pngData() else {
                return nil
            }
            try imageData.write(to: fileURL)
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL, options: options)
            return imageAttachment
        } catch {
            print("error " + error.localizedDescription)
        }
        return nil
    }
}

//String checks
extension String {
    var hasAlphanumeric: Bool {
        return !isEmpty && range(of: "[a-zA-Z0-9]+", options: .regularExpression) != nil
    }
}

//Date Formatters
extension DateFormatter {
    
    convenience init (format: String) {
        self.init()
        dateFormat = format
        locale = Locale.current
    }
}

extension String {
    
    func toDate (format: String) -> Date? {
        return DateFormatter(format: format).date(from: self)
    }
    
    func toDateString (inputFormat: String, outputFormat:String) -> String? {
        if let date = toDate(format: inputFormat) {
            return DateFormatter(format: outputFormat).string(from: date)
        }
        return nil
    }
}

extension DateComponents {
    
    func toDate() -> Date {
        let calendar = Calendar.current
        let dateComponents = DateComponents(calendar: calendar, year: self.year, month: self.month, day: self.day)
        return calendar.date(from: dateComponents) ?? Date()
    }
}

extension Date {
    
    func getMonth() -> String {
        let mdateFormatter = DateFormatter()
        mdateFormatter.dateFormat = "MMMM"
        return mdateFormatter.string(from: self)
    }
    
    func getDay() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self)
    }
    
    func getDate() -> String {
        let numberFormatter = DateFormatter()
        numberFormatter.dateFormat = "d"
        let date = numberFormatter.string(from: self)
        let dateSuffix = date.suffix(1)
        
        if dateSuffix == "1" && date != "11"{
            return date + "st"
        }else if dateSuffix == "2" {
            return date + "nd"
        }else if dateSuffix == "3"{
            return date + "rd"
        }else{
            return date + "th"
        }
    }
    
    func getFormattedDateString() -> String {
        return self.getDay() + ", " + self.getDate() + " " + self.getMonth().prefix(3)
    }
    
    func toString (format:String) -> String? {
        return DateFormatter(format: format).string(from: self)
    }
}

extension TimeInterval{
    
    func stringFromTimeInterval() -> String {
        
        let time = NSInteger(self)
        
//        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
//        let hours = (time / 3600)
        
//        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
        return String(format: "%0.2d:%0.2d",minutes,seconds)
        
    }
}

extension UIImage {
    
    func fixedOrientation() -> UIImage? {
        
        guard imageOrientation != UIImage.Orientation.up else {
            //This is default orientation, don't need to do anything
            return self.copy() as? UIImage
        }
        
        guard let cgImage = self.cgImage else {
            //CGImage is not available
            return nil
        }
        
        guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil //Not able to create CGContext
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
            break
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
            break
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
            break
        case .up, .upMirrored:
            break
        }
        
        //Flip image one more time if needed to, this is to prevent flipped image
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored, .rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        }
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        guard let newCGImage = ctx.makeImage() else { return nil }
        return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
    }
}
