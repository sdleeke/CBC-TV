//
//  extensions.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

extension UIColor
{
    // MARK: UIColor extension
    
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
    
    static func controlBlue() -> UIColor
    {
        return UIColor(red: 14, green: 122, blue: 254)
    }
}

extension UIBarButtonItem {
    func setTitleTextAttributes(_ attributes:[NSAttributedStringKey:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControlState.normal)
        setTitleTextAttributes(attributes, for: UIControlState.disabled)
        setTitleTextAttributes(attributes, for: UIControlState.selected)
        setTitleTextAttributes(attributes, for: UIControlState.highlighted)
        setTitleTextAttributes(attributes, for: UIControlState.focused)
    }
}

extension UISegmentedControl {
    func setTitleTextAttributes(_ attributes:[String:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControlState.normal)
        setTitleTextAttributes(attributes, for: UIControlState.disabled)
        setTitleTextAttributes(attributes, for: UIControlState.selected)
        setTitleTextAttributes(attributes, for: UIControlState.highlighted)
        setTitleTextAttributes(attributes, for: UIControlState.focused)
    }
}

extension UIButton {
    func setTitle(_ string:String?)
    {
        setTitle(string, for: UIControlState.normal)
        setTitle(string, for: UIControlState.disabled)
        setTitle(string, for: UIControlState.selected)
        setTitle(string, for: UIControlState.highlighted)
        setTitle(string, for: UIControlState.focused)
    }
    
    func setAttributedTitle(_ string:NSAttributedString?)
    {
        setAttributedTitle(string, for: UIControlState.normal)
        setAttributedTitle(string, for: UIControlState.disabled)
        setAttributedTitle(string, for: UIControlState.selected)
        setAttributedTitle(string, for: UIControlState.highlighted)
        setAttributedTitle(string, for: UIControlState.focused)
    }
}

extension Thread {
    static func onMainThread(block:(()->(Void))?)
    {
        if Thread.isMainThread {
            block?()
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                block?()
            })
        }
    }
}

extension String
{
    var url : URL?
    {
        get {
            return URL(string: self)
        }
    }
    
    var fileSystemURL : URL?
    {
        get {
            return url?.fileSystemURL
        }
    }
}

extension String
{
    func highlighted(_ searchText:String?) -> NSAttributedString
    {
        guard let searchText = searchText else {
            return NSAttributedString(string: self, attributes: Constants.Fonts.Attributes.body)
        }
        
        guard let range = self.lowercased().range(of: searchText.lowercased()) else {
            return NSAttributedString(string: self, attributes: Constants.Fonts.Attributes.body)
        }
        
        let highlightedString = NSMutableAttributedString()
        
        let before = String(self[..<range.lowerBound])
        let string = String(self[range])
        let after = String(self[range.upperBound...])

        highlightedString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.body))
        highlightedString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.bodyHighlighted))
        highlightedString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.body))

        return highlightedString
    }
}

fileprivate var queue = DispatchQueue(label: UUID().uuidString)

extension URL
{
    var fileSystemURL : URL?
    {
        return cachesURL()?.appendingPathComponent(self.lastPathComponent)
    }
    
    var downloaded : Bool
    {
        get {
            if let fileSystemURL = fileSystemURL {
                return FileManager.default.fileExists(atPath: fileSystemURL.path)
            } else {
                return false
            }
        }
    }

    var data : Data?
    {
        get {
            return try? Data(contentsOf: self)
        }
    }
    
    func delete()
    {
        guard let fileSystemURL = fileSystemURL else {
            return
        }
        
        // Check if file exists and if so, delete it.
        if (FileManager.default.fileExists(atPath: fileSystemURL.path)){
            do {
                try FileManager.default.removeItem(at: fileSystemURL)
            } catch let error as NSError {
                print("failed to delete download: \(error.localizedDescription)")
            }
        }
    }
    
    func image(block:((UIImage)->()))
    {
        if let image = image {
            block(image)
        }
    }
    
    var image : UIImage?
    {
        get {
            guard let imageURL = fileSystemURL else {
                return nil
            }
            
            if Globals.shared.cacheDownloads, imageURL.downloaded, let image = UIImage(contentsOfFile: imageURL.path) {
                return image
            } else {
                guard let data = try? Data(contentsOf: self) else {
                    return nil
                }
                
                guard let image = UIImage(data: data) else {
                    return nil
                }
                
                if Globals.shared.cacheDownloads {
                    DispatchQueue.global(qos: .background).async {
                        queue.sync {
                            guard !imageURL.downloaded else {
                                return
                            }
                            
                            do {
                                try UIImageJPEGRepresentation(image, 1.0)?.write(to: imageURL, options: [.atomic])
                                print("Image \(self.lastPathComponent) saved to file system")
                            } catch let error as NSError {
                                NSLog(error.localizedDescription)
                                print("Image \(self.lastPathComponent) not saved to file system")
                            }
                        }
                    }
                }
                
                return image
            }
        }
    }
}

extension Data
{
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self, options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf16.rawValue], documentAttributes: nil)
        } catch {
            print("error:", error)
            return  nil
        }
    }
    var html2String: String? {
        return html2AttributedString?.string
    }
}

extension Date
{
    //MARK: Date extension
    
    init(dateString:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let d = dateStringFormatter.date(from: dateString) {
            self = Date(timeInterval:0, since:d)
        } else {
            self = Date()
        }
    }
    
    var ymd : String {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "yyyy-MM-dd"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    var mdyhm : String {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            dateStringFormatter.amSymbol = "AM"
            dateStringFormatter.pmSymbol = "PM"
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    var mdy : String {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM d, yyyy"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    var year : String {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "yyyy"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    var month : String {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    var day : String {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "dd"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    func isNewerThan(_ dateToCompare : Date) -> Bool
    {
        return (self.compare(dateToCompare) == ComparisonResult.orderedDescending) && (self.compare(dateToCompare) != ComparisonResult.orderedSame)
    }
    
    
    func isOlderThan(_ dateToCompare : Date) -> Bool
    {
        return (self.compare(dateToCompare) == ComparisonResult.orderedAscending) && (self.compare(dateToCompare) != ComparisonResult.orderedSame)
    }
    
    
    func isEqualTo(_ dateToCompare : Date) -> Bool
    {
        return self.compare(dateToCompare) == ComparisonResult.orderedSame
    }
    
    func addDays(_ daysToAdd : Int) -> Date
    {
        let secondsInDays : TimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded : Date = self.addingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    func addHours(_ hoursToAdd : Int) -> Date
    {
        let secondsInHours : TimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded : Date = self.addingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}
