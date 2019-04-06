//
//  extensions.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

extension Set
{
    var array: [Element]
    {
        return Array(self)
    }
}

extension Array where Element : Hashable
{
    var set: Set<Element>
    {
        return Set(self)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

extension UIApplication
{
    func open(scheme: String?,cannotOpen:(()->(Void))?)
    {
        guard let scheme = scheme else {
            return
        }
        
        guard let url = URL(string: scheme) else {
            return
        }
        
        guard self.canOpenURL(url) else { // Reachability.isConnectedToNetwork() &&
            cannotOpen?()
            return
        }
        
        if #available(iOS 10, *) {
            self.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]),
                      completionHandler: {
                        (success) in
                        print("Open \(scheme): \(success)")
            })
        } else {
            let success = UIApplication.shared.openURL(url)
            print("Open \(scheme): \(success)")
        }
    }
}

extension FileManager
{
    var documentsURL : URL?
    {
        get {
            return self.urls(for: .documentDirectory, in: .userDomainMask).first
        }
    }
    
    var cachesURL : URL?
    {
        get {
            return self.urls(for: .cachesDirectory, in: .userDomainMask).first
        }
    }
}

extension UITableView
{
    func isValid(_ indexPath:IndexPath) -> Bool
    {
        guard indexPath.section >= 0 else {
            return false
        }
        
        guard indexPath.section < self.numberOfSections else {
            return false
        }
        
        guard indexPath.row >= 0 else {
            return false
        }
        
        guard indexPath.row < self.numberOfRows(inSection: indexPath.section) else {
            return false
        }
        
        return true
    }
}

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
    func setTitleTextAttributes(_ attributes:[NSAttributedString.Key:UIFont])
    {
        setTitleTextAttributes(attributes, for: UIControl.State.normal)
        setTitleTextAttributes(attributes, for: UIControl.State.disabled)
        setTitleTextAttributes(attributes, for: UIControl.State.selected)
        setTitleTextAttributes(attributes, for: UIControl.State.highlighted)
        setTitleTextAttributes(attributes, for: UIControl.State.focused)
    }
}

extension UISegmentedControl {
    func setTitleTextAttributes(_ attributes:[NSAttributedString.Key:Any])
    {
        setTitleTextAttributes(attributes, for: UIControl.State.normal)
        setTitleTextAttributes(attributes, for: UIControl.State.disabled)
        setTitleTextAttributes(attributes, for: UIControl.State.selected)
        setTitleTextAttributes(attributes, for: UIControl.State.highlighted)
        setTitleTextAttributes(attributes, for: UIControl.State.focused)
    }
}

extension UIButton {
    func setTitle(_ string:String?)
    {
        setTitle(string, for: UIControl.State.normal)
        setTitle(string, for: UIControl.State.disabled)
        setTitle(string, for: UIControl.State.selected)
        setTitle(string, for: UIControl.State.highlighted)
        setTitle(string, for: UIControl.State.focused)
    }
    
    func setAttributedTitle(_ string:NSAttributedString?)
    {
        setAttributedTitle(string, for: UIControl.State.normal)
        setAttributedTitle(string, for: UIControl.State.disabled)
        setAttributedTitle(string, for: UIControl.State.selected)
        setAttributedTitle(string, for: UIControl.State.highlighted)
        setAttributedTitle(string, for: UIControl.State.focused)
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

extension Double {
    var secondsToHMS : String?
    {
        get {
            let hours = max(Int(self / (60*60)),0)
            let mins = max(Int((self - (Double(hours) * 60*60)) / 60),0)
            let sec = max(Int(self.truncatingRemainder(dividingBy: 60)),0)
            
            var string:String
            
            if (hours > 0) {
                string = "\(String(format: "%d",hours)):"
            } else {
                string = Constants.EMPTY_STRING
            }
            
            string += "\(String(format: "%02d",mins)):\(String(format: "%02d",sec))"
            
            return string
        }
    }
}

extension String
{
    var withoutPrefixes : String
    {
        get {
            if let range = self.range(of: "A is "), range.lowerBound == "a".startIndex {
                return self
            }
            
            let sourceString = self.replacingOccurrences(of: Constants.DOUBLE_QUOTE, with: Constants.EMPTY_STRING).replacingOccurrences(of: "...", with: Constants.EMPTY_STRING)
            
            let prefixes = ["A ","An ","The "] // "And ",
            
            var sortString = sourceString
            
            for prefix in prefixes {
                if (sourceString.endIndex >= prefix.endIndex) && (String(sourceString[..<prefix.endIndex]).lowercased() == prefix.lowercased()) {
                    sortString = String(sourceString[prefix.endIndex...])
                    break
                }
            }
            
            return sortString
        }
    }
    
    var hmsToSeconds : Double?
    {
        get {
            guard self.range(of: ":") != nil else {
                return nil
            }
            
            var str = self.replacingOccurrences(of: ",", with: ".")
            
            var numbers = [Double]()
            
            repeat {
                if let index = str.range(of: ":") {
                    let numberString = String(str[..<index.lowerBound])
                    
                    if let number = Double(numberString) {
                        numbers.append(number)
                    }
                    
                    str = String(str[index.upperBound...])
                }
            } while str.range(of: ":") != nil
            
            if !str.isEmpty {
                if let number = Double(str) {
                    numbers.append(number)
                }
            }
            
            var seconds = 0.0
            var counter = 0.0
            
            for number in numbers.reversed() {
                seconds = seconds + (counter != 0 ? number * pow(60.0,counter) : number)
                counter += 1
            }
            
            return seconds
        }
    }
    
    var secondsToHMS : String?
    {
        get {
            guard let timeNow = Double(self) else {
                return nil
            }
            
            let hours = max(Int(timeNow / (60*60)),0)
            let mins = max(Int((timeNow - (Double(hours) * 60*60)) / 60),0)
            let sec = max(Int(timeNow.truncatingRemainder(dividingBy: 60)),0)
            let fraction = timeNow - Double(Int(timeNow))
            
            var hms:String
            
            if (hours > 0) {
                hms = "\(String(format: "%02d",hours)):"
            } else {
                hms = "00:"
            }
            
            hms = hms + "\(String(format: "%02d",mins)):\(String(format: "%02d",sec)).\(String(format: "%03d",Int(fraction * 1000)))"
            
            return hms
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
            guard !self.isEmpty else {
                return nil
                
            }
            
            guard url != nil else {
                if let lastPathComponent = self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) {
                    return FileManager.default.cachesURL?.appendingPathComponent(lastPathComponent)
                } else {
                    return nil
                }
            }
            
            guard self != url?.lastPathComponent else {
                if let lastPathComponent = self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) {
                    return FileManager.default.cachesURL?.appendingPathComponent(lastPathComponent)
                } else {
                    return nil
                }
            }
            
            return url?.fileSystemURL
        }
    }
}

extension URL
{
    var fileSystemURL : URL?
    {
        return self.lastPathComponent.fileSystemURL
    }
    
    var exists : Bool
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
            do {
                let data = try Data(contentsOf: self)
                print("Data read from \(self.absoluteString)")
                return data
            } catch let error {
                NSLog(error.localizedDescription)
                print("Data not read from \(self.absoluteString)")
                return nil
            }
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
            guard let data = data else {
                return nil
            }
            
            return UIImage(data: data)
        }
    }

    func files(startingWith filename:String? = nil,ofType fileType:String? = nil,notOfType notFileType:String? = nil) -> [String]?
    {
        ////////////////////////////////////////////////////////////////////
        // THIS CAN BE A HUGE MEMORY LEAK IF NOT USED IN AN AUTORELEASEPOOL
        ////////////////////////////////////////////////////////////////////
        
        guard (filename != nil) || (fileType != nil) else {
            return nil
        }
        
        guard let isDirectory = try? FileWrapper(url: self, options: []).isDirectory, isDirectory else {
            return nil
        }
        
        var files = [String]()
        
        do {
            let array = try FileManager.default.contentsOfDirectory(atPath: path)
            
            for string in array {
                var fileNameCandidate : String?
                var fileTypeCandidate : String?
                var notFileTypeCandidate : String?
                
                if let filename = filename {
                    if let range = string.range(of: filename) {
                        if filename == String(string[..<range.upperBound]) {
                            fileNameCandidate = string
                        }
                    }
                }
                
                if let fileType = fileType {
                    if let range = string.range(of: "." + fileType.trimmingCharacters(in: CharacterSet(charactersIn: "."))) {
                        if fileType == String(string[range.lowerBound...]) {
                            fileTypeCandidate = string
                        }
                    }
                }
                
                if let notFileType = notFileType {
                    if let range = string.range(of: "." + notFileType.trimmingCharacters(in: CharacterSet(charactersIn: "."))) {
                        if notFileType == String(string[range.lowerBound...]) {
                            notFileTypeCandidate = string
                        }
                    }
                }
                
                if let fileNameCandidate = fileNameCandidate {
                    if let fileTypeCandidate = fileTypeCandidate {
                        if fileNameCandidate == fileTypeCandidate {
                            if notFileTypeCandidate == nil {
                                files.append(string)
                            }
                        }
                    } else {
                        if notFileTypeCandidate == nil {
                            files.append(string)
                        }
                    }
                } else {
                    if fileTypeCandidate != nil {
                        if notFileTypeCandidate == nil {
                            files.append(string)
                        }
                    }
                }
            }
        } catch let error {
            print("failed to get files in directory \(self.path): \(error.localizedDescription)") // remove
        }
        
        return files.count > 0 ? files : nil
    }
}

extension UIImage
{
    func save(to url: URL?) -> UIImage?
    {
        guard let url = url else {
            return nil
        }
        
        do {
            try self.jpegData(compressionQuality: 1.0)?.write(to: url, options: [.atomic])
//            try UIImageJPEGRepresentation(self, 1.0)?.write(to: url, options: [.atomic])
            print("Image saved to \(url.absoluteString)")
        } catch let error {
            NSLog(error.localizedDescription)
            print("Image not saved to \(url.absoluteString)")
        }
        
        return self
    }
}

extension Data
{
    func save(to url: URL?)
    {
        guard let url = url else {
            return
        }
        
        do {
            try self.write(to: url)
        } catch let error {
            NSLog("Data write error: \(url.absoluteString)",error.localizedDescription)
        }
    }
    
    var json : Any?
    {
        get {
            do {
                let json = try JSONSerialization.jsonObject(with: self, options: [])
                return json
            } catch let error {
                NSLog("JSONSerialization error", error.localizedDescription)
                return nil
            }
        }
    }
    
    var html2AttributedString: NSAttributedString?
    {
        do {
            return try NSAttributedString(data: self, options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf16.rawValue], documentAttributes: nil)
        } catch {
            print("error:", error)
            return  nil
        }
    }
    
    var html2String: String?
    {
        get {
            return html2AttributedString?.string
        }
    }
    
    var image : UIImage?
    {
        get {
            return UIImage(data: self)
        }
    }
}

extension Date
{
    //MARK: Date extension
    
    init(dateString:String)
    {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let d = dateStringFormatter.date(from: dateString) {
            self = Date(timeInterval:0, since:d)
        } else {
            self = Date()
        }
    }
    
    var ymd : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "yyyy-MM-dd"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    var mdyhm : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            dateStringFormatter.amSymbol = "AM"
            dateStringFormatter.pmSymbol = "PM"
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    var mdy : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM d, yyyy"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    var year : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "yyyy"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    var month : String
    {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMM"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            return dateStringFormatter.string(from: self)
        }
    }
    
    var day : String
    {
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

extension Array where Element == MediaItem
{
    func sections(sorting:String?,grouping:String?) -> [String]?
    {
        guard let sorting = sorting, let grouping = grouping else {
            return nil
        }
        
        var strings:[String]?
        
        switch grouping {
        case GROUPING.YEAR:
            strings = self.years(sorting: sorting)?.map() { (year) in
                return "\(year)"
            }
            break
            
        case GROUPING.TITLE:
            strings = self.seriesSections(withTitles: true)
            break
            
        case GROUPING.BOOK:
            strings = self.bookSections
            break
            
        case GROUPING.SPEAKER:
            strings = self.speakerSections
            break
            
        case GROUPING.CLASS:
            strings = self.classSections
            break
            
        default:
            strings = nil
            break
        }
        
        return strings
    }
    
    
    func years(sorting: String?) -> [Int]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        guard let sorting = sorting else {
            return nil
        }
        
        return self.filter({ (mediaItem:MediaItem) -> Bool in
                    // We're assuming this gets ALL mediaItems.
                    return mediaItem.fullDate != nil
                }).map({ (mediaItem:MediaItem) -> Int in
                    let calendar = Calendar.current
                    if let fullDate = mediaItem.fullDate {
                        let components = (calendar as NSCalendar).components(.year, from: fullDate)
                        if let year = components.year {
                            return year
                        }
                    }
                    
                    return -1
                }).set.array.sorted(by: { (first:Int, second:Int) -> Bool in
                switch sorting {
                case SORTING.CHRONOLOGICAL:
                    return first < second
                    
                case SORTING.REVERSE_CHRONOLOGICAL:
                    return first > second
                    
                default:
                    break
                }
                
                return false
            })
    }

    func inBook(_ book:String?) -> [MediaItem]?
    {
        guard let book = book else {
            return nil
        }
        
        return self.filter({ (mediaItem:MediaItem) -> Bool in
            if let books = mediaItem.books {
                return books.contains(book)
            } else {
                return false
            }
        }).sorted(by: { (first:MediaItem, second:MediaItem) -> Bool in
            if let firstDate = first.fullDate, let secondDate = second.fullDate {
                if (firstDate.isEqualTo(secondDate)) {
                    return first.service < second.service
                } else {
                    return firstDate.isOlderThan(secondDate)
                }
            } else {
                return false
            }
        })
    }
    
    var books : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        var bookSet = Set<String>()
        
        for mediaItem in self {
            if let books = mediaItem.books {
                for book in books {
                    bookSet.insert(book)
                }
            }
        }
        
//        return Array(bookSet).sorted(by: { (first:String, second:String) -> Bool in
        return bookSet.array.sorted(by: { (first:String, second:String) -> Bool in
            var result = false
            
            if (first.bookNumberInBible != nil) && (second.bookNumberInBible != nil) {
                if first.bookNumberInBible == second.bookNumberInBible {
                    result = first < second
                } else {
                    result = first.bookNumberInBible < second.bookNumberInBible
                }
            } else
                if (first.bookNumberInBible != nil) && (second.bookNumberInBible == nil) {
                    result = true
                } else
                    if (first.bookNumberInBible == nil) && (second.bookNumberInBible != nil) {
                        result = false
                    } else
                        if (first.bookNumberInBible == nil) && (second.bookNumberInBible == nil) {
                            result = first < second
            }
            
            return result
        })
    }
    
    var bookSections : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        var bookSectionSet = Set<String>()
        
        for mediaItem in self {
            for bookSection in mediaItem.bookSections {
                bookSectionSet.insert(bookSection)
            }
        }
        
//        return Array(bookSectionSet).sorted(by: { (first:String, second:String) -> Bool in
        return bookSectionSet.array.sorted(by: { (first:String, second:String) -> Bool in
            var result = false
            if (first.bookNumberInBible != nil) && (second.bookNumberInBible != nil) {
                if first.bookNumberInBible == second.bookNumberInBible {
                    result = first < second
                } else {
                    result = first.bookNumberInBible < second.bookNumberInBible
                }
            } else
                if (first.bookNumberInBible != nil) && (second.bookNumberInBible == nil) {
                    result = true
                } else
                    if (first.bookNumberInBible == nil) && (second.bookNumberInBible != nil) {
                        result = false
                    } else
                        if (first.bookNumberInBible == nil) && (second.bookNumberInBible == nil) {
                            result = first < second
            }
            return result
        })
    }
    
    var series : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        let mediaItems = Set(self.filter({ (mediaItem:MediaItem) -> Bool in
            return mediaItem.hasMultipleParts
        }).map({ (mediaItem:MediaItem) -> String in
            return mediaItem.multiPartName ?? Constants.Strings.None
        }))
        
        return mediaItems.sorted(by: { (first:String, second:String) -> Bool in
            return first.withoutPrefixes < second.withoutPrefixes
        })
        
//        return Array(
//            Set(
//                mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
//                    return mediaItem.hasMultipleParts
//                }).map({ (mediaItem:MediaItem) -> String in
//                    return mediaItem.multiPartName!
//                })
//            )
//            ).sorted(by: { (first:String, second:String) -> Bool in
//                return first.withoutPrefixes < second.withoutPrefixes
//            })
    }
    
    var seriesSections : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        let mediaItems = Set(self.map({ (mediaItem:MediaItem) -> String in
            if let multiPartSection = mediaItem.multiPartSection {
                return multiPartSection
            } else {
                return "ERROR"
            }
        }))
        
        return mediaItems.sorted(by: { (first:String, second:String) -> Bool in
            return first.withoutPrefixes < second.withoutPrefixes
        })

//        return Array(
//            Set(
//                mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
//                    return mediaItem.hasMultipleParts
//                }).map({ (mediaItem:MediaItem) -> String in
//                    return mediaItem.multiPartSection!
//                })
//            )
//            ).sorted(by: { (first:String, second:String) -> Bool in
//                return first.withoutPrefixes < second.withoutPrefixes
//            })
    }
    
    func seriesSections(withTitles:Bool) -> [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }

        let mediaItems = Set(self.map({ (mediaItem:MediaItem) -> String in
            if mediaItem.hasMultipleParts {
                return mediaItem.multiPartName!
            } else {
                return withTitles ? (mediaItem.title ?? "No Title") : Constants.Individual_Media
            }
        }))
        
        return mediaItems.sorted(by: { (first:String, second:String) -> Bool in
            return first.withoutPrefixes < second.withoutPrefixes
        })

//        return Array(
//            Set(
//                mediaItems.map({ (mediaItem:MediaItem) -> String in
//                    if (mediaItem.hasMultipleParts) {
//                        return mediaItem.multiPartName!
//                    } else {
//                        return withTitles ? mediaItem.title ?? "TITLE" : Constants.Individual_Media
//                    }
//                })
//            )
//            ).sorted(by: { (first:String, second:String) -> Bool in
//                return first.withoutPrefixes < second.withoutPrefixes
//            })
    }

    var classSections : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        return self.map({ (mediaItem:MediaItem) -> String in
                return mediaItem.classSection ?? "CLASS SECTION"
            }).set.array.sorted()
    }
    
    var speakerSections : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        return self.map({ (mediaItem:MediaItem) -> String in
                return mediaItem.speakerSection ?? "SPEAKER SECTION"
            }).set.array.sorted(by: { (first:String, second:String) -> Bool in
                return first.lastName < second.lastName
            })
    }
    
    var speakers : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        return self.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.hasSpeaker
            }).map({ (mediaItem:MediaItem) -> String in
                return mediaItem.speaker ?? "SPEAKER"
            }).set.array.sorted(by: { (first:String, second:String) -> Bool in
                return first.lastName < second.lastName
            })
    }
    
    var sortChronologically : [MediaItem]?
    {
        return self.sorted() {
            if let firstDate = $0.fullDate, let secondDate = $1.fullDate {
                if (firstDate.isEqualTo(secondDate)) {
                    if ($0.service == $1.service) {
                        return $0.id < $1.id
                    } else {
                        return $0.service < $1.service
                    }
                } else {
                    return firstDate.isOlderThan(secondDate)
                }
            } else {
                return false
            }
        }
    }
    
    var sortReverseChronologically : [MediaItem]?
    {
        return self.sorted() {
            if let firstDate = $0.fullDate, let secondDate = $1.fullDate {
                if (firstDate.isEqualTo(secondDate)) {
                    if ($0.service == $1.service) {
                        return $0.id > $1.id
                    } else {
                        return $0.service > $1.service
                    }
                } else {
                    return firstDate.isNewerThan(secondDate)
                }
            } else {
                return false
            }
        }
    }
    
    func sortByYear(sorting:String?) -> [MediaItem]?
    {
        guard let sorting = sorting else {
            return nil
        }
        
        var sortedMediaItems:[MediaItem]?
        
        switch sorting {
        case SORTING.CHRONOLOGICAL:
            sortedMediaItems = self.sortChronologically
            break
            
        case SORTING.REVERSE_CHRONOLOGICAL:
            sortedMediaItems = self.sortReverseChronologically
            break
            
        default:
            break
        }
        
        return sortedMediaItems
    }

    func sortByMultiPart(sorting:String?) -> [MediaItem]?
    {
        return self.sorted() {
            var result = false
            
            let first = $0
            let second = $1
            
            if (first.multiPartSectionSort != second.multiPartSectionSort) {
                result = first.multiPartSectionSort < second.multiPartSectionSort
            } else {
                result = compareMediaItemDates(first: first,second: second, sorting: sorting)
            }
            
            return result
        }
    }
    
    func sortByClass(sorting: String?) -> [MediaItem]?
    {
        return self.sorted() {
            var result = false
            
            let first = $0
            let second = $1
            
            if (first.classSectionSort != second.classSectionSort) {
                result = first.classSectionSort < second.classSectionSort
            } else {
                result = compareMediaItemDates(first: first,second: second, sorting: sorting)
            }
            
            return result
        }
    }
    
    func sortBySpeaker(sorting: String?) -> [MediaItem]?
    {
        return self.sorted() {
            var result = false
            
            let first = $0
            let second = $1
            
            if (first.speakerSectionSort != second.speakerSectionSort) {
                result = first.speakerSectionSort < second.speakerSectionSort
            } else {
                result = compareMediaItemDates(first: first,second: second, sorting: sorting)
            }
            
            return result
        }
    }

    func withTag(_ tag:String?) -> [MediaItem]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        guard let tag = tag else {
            return nil
        }
        
        return self.filter({ (mediaItem:MediaItem) -> Bool in
            if let tagSet = mediaItem.tagsSet {
                return tagSet.contains(tag)
            } else {
                return false
            }
        })
    }
    
    var tags : [String]?
    {
//        guard let mediaItems = mediaItems else {
//            return nil
//        }
        
        var tagsSet = Set<String>()
        
        for mediaItem in self {
            if let tags = mediaItem.tagsSet {
                tagsSet.formUnion(tags)
            }
        }
        
        var tagsArray = tagsSet.array.sorted(by: { $0.withoutPrefixes < $1.withoutPrefixes })
        
        tagsArray.append(Constants.All)
        
        return tagsArray.count > 0 ? tagsArray : nil
    }
}

extension Array where Element == String
{
    var tagsString : String?
    {
//        guard let tagsArray = tagsArray else {
//            return nil
//        }
        
        var tagString:String?
        
        for tag in self {
            tagString = (tagString != nil ? tagString! + Constants.TAGS_SEPARATOR : "") + tag
        }
        
        return tagString
    }
    
}

extension String
{
    var tokenCounts : [(String,Int)]?
    {
//        guard string != nil else {
//            return nil
//        }
        
        var tokenCounts = [(String,Int)]()
        
        if let tokens = self.tokens {
            for token in tokens {
                var count = 0
//                guard var string = string else {
//                    continue
//                }
                
                var string = self
                
                while let range = string.range(of: token, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
                    count += 1
                    string = String(string[range.upperBound...])
                }
                
                tokenCounts.append((token,count))
            }
        }
        
        return tokenCounts.count > 0 ? tokenCounts : nil
    }
    
    var tokens : [String]?
    {
//        guard let string = string else {
//            return nil
//        }
        
        var tokens = Set<String>()
        
        var str = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if let range = str.range(of: Constants.PART_INDICATOR_SINGULAR) {
            // .substring(to:
            str = String(str[..<range.lowerBound])
        }
        
        var token = Constants.EMPTY_STRING
        let trimChars = Constants.UNBREAKABLE_SPACE + Constants.QUOTES + " '" // ‘”
        let breakChars = "\" :-!;,.()?&/<>[]" + Constants.UNBREAKABLE_SPACE + Constants.DOUBLE_QUOTES // ‘“
        
        func processToken()
        {
            if (token.endIndex > "XX".endIndex) {
                // "Q", "A", "I", "at", "or", "to", "of", "in", "on",  "be", "is", "vs", "us", "An"
                for word in ["are", "can", "And", "The", "for"] {
                    if token.lowercased() == word.lowercased() {
                        token = Constants.EMPTY_STRING
                        break
                    }
                }
                
                if let range = token.lowercased().range(of: "i'"), range.lowerBound == token.startIndex {
                    token = Constants.EMPTY_STRING
                }
                
                if token.lowercased() != "it's" {
                    if let range = token.lowercased().range(of: "'s") {
                        // .substring(to:
                        token = String(token[..<range.lowerBound])
                    }
                }
                
                if token != token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars)) {
                    token = token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars))
                }
                
                if token != Constants.EMPTY_STRING {
                    tokens.insert(token.uppercased())
                    token = Constants.EMPTY_STRING
                }
            } else {
                token = Constants.EMPTY_STRING
            }
        }
        
        for char in str {
            if UnicodeScalar(String(char)) != nil {
                if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: breakChars).contains(unicodeScalar) {
                    processToken()
                } else {
                    if let unicodeScalar = UnicodeScalar(String(char)), !CharacterSet(charactersIn: "$0123456789").contains(unicodeScalar) {
                        if !CharacterSet(charactersIn: trimChars).contains(unicodeScalar) || (token != Constants.EMPTY_STRING) {
                            // DO NOT WANT LEADING CHARS IN SET
                            token.append(char)
                        }
                    }
                }
            }
        }
        
        if !token.isEmpty {
            processToken()
        }
        
        return Array(tokens).sorted() {
            $0.lowercased() < $1.lowercased()
        }
    }
    
    var tokensAndCounts : [String:Int]?
    {
//        guard let string = string else {
//            return nil
//        }
        
        var tokens = [String:Int]()
        
        var str = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // TOKENIZING A TITLE RATHER THAN THE BODY, THIS MAY CAUSE PROBLEMS FOR BODY TEXT.
        if let range = str.range(of: Constants.PART_INDICATOR_SINGULAR) {
            // .substring(to:
            str = String(str[..<range.lowerBound])
        }
        
        var token = Constants.EMPTY_STRING
        let trimChars = Constants.UNBREAKABLE_SPACE + Constants.QUOTES + " '" // ‘”
        let breakChars = "\" :-!;,.()?&/<>[]" + Constants.UNBREAKABLE_SPACE + Constants.DOUBLE_QUOTES // ‘“
        
        func processToken()
        {
            if (token.endIndex > "XX".endIndex) {
                // "Q", "A", "I", "at", "or", "to", "of", "in", "on",  "be", "is", "vs", "us", "An"
                for word in ["are", "can", "And", "The", "for"] {
                    if token.lowercased() == word.lowercased() {
                        token = Constants.EMPTY_STRING
                        break
                    }
                }
                
                if let range = token.lowercased().range(of: "i'"), range.lowerBound == token.startIndex {
                    token = Constants.EMPTY_STRING
                }
                
                if token.lowercased() != "it's" {
                    if let range = token.lowercased().range(of: "'s") {
                        // .substring(to:
                        token = String(token[..<range.lowerBound])
                    }
                }
                
                if token != token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars)) {
                    token = token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars))
                }
                
                if token != Constants.EMPTY_STRING {
                    if let count = tokens[token.uppercased()] {
                        tokens[token.uppercased()] = count + 1
                    } else {
                        tokens[token.uppercased()] = 1
                    }
                    token = Constants.EMPTY_STRING
                }
            } else {
                token = Constants.EMPTY_STRING
            }
        }
        
        for char in str {
            if UnicodeScalar(String(char)) != nil {
                if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: breakChars).contains(unicodeScalar) {
                    processToken()
                } else {
                    if let unicodeScalar = UnicodeScalar(String(char)), !CharacterSet(charactersIn: "$0123456789").contains(unicodeScalar) {
                        if !CharacterSet(charactersIn: trimChars).contains(unicodeScalar) || (token != Constants.EMPTY_STRING) {
                            // DO NOT WANT LEADING CHARS IN SET
                            token.append(char)
                        }
                    }
                }
            }
        }
        
        if !token.isEmpty {
            processToken()
        }
        
        return tokens.count > 0 ? tokens : nil
    }
    
    var lastName : String?
    {
//        guard let name = name else {
//            return nil
//        }
        
        let name = self
        
        if let firstName = name.firstName, let range = name.range(of: firstName) {
            return String(name[range.upperBound...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } else {
            return name
        }
    }
    
    var firstName : String?
    {
//        guard let name = name else {
//            return nil
//        }
        
        let name = self
        
        var firstName:String?
        
        var string:String
        
        if let title = name.title {
            string = String(name[title.endIndex...])
        } else {
            string = name
        }
        
        string = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        var newString = Constants.EMPTY_STRING
        
        for char in string {
            if String(char) == Constants.SINGLE_SPACE {
                firstName = newString
                break
            }
            newString.append(char)
        }
        
        return firstName
    }
    
    var title : String?
    {
//        guard let name = name else {
//            return nil
//        }
        
        let name = self
        
        var title = Constants.EMPTY_STRING
        
        if name.range(of: ". ") != nil {
            for char in name {
                title.append(char)
                if String(char) == "." {
                    break
                }
            }
        }
        
        return title != Constants.EMPTY_STRING ? title : nil
    }

}

extension String
{
    var translateTestament : String
    {
        var translation = Constants.EMPTY_STRING
        
        switch self {
        case Constants.OT:
            translation = Constants.Old_Testament
            break
            
        case Constants.NT:
            translation = Constants.New_Testament
            break
            
        default:
            break
        }
        
        return translation
    }
    
    var translate : String?
    {
//        guard let string = string else {
//            return nil
//        }
        
        switch self {
        case SORTING.CHRONOLOGICAL:
            return Sorting.Oldest_to_Newest
            
        case SORTING.REVERSE_CHRONOLOGICAL:
            return Sorting.Newest_to_Oldest
            
        case GROUPING.YEAR:
            return Grouping.Year
            
        case GROUPING.TITLE:
            return Grouping.Title
            
        case GROUPING.BOOK:
            return Grouping.Book
            
        case GROUPING.SPEAKER:
            return Grouping.Speaker
            
        case GROUPING.CLASS:
            return Grouping.Class
            
        default:
            return nil
        }
    }

    var bookNumberInBible : Int?
    {
//        guard let book = book else {
//            return nil
//        }
        
        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: self) {
            return index
        }
        
        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: self) {
            return Constants.OLD_TESTAMENT_BOOKS.count + index
        }
        
        return Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE // Not in the Bible.  E.g. Selected Scriptures
    }
    
    var testament : String
    {
        if (Constants.OLD_TESTAMENT_BOOKS.contains(self)) {
            return Constants.Old_Testament
        } else
            if (Constants.NEW_TESTAMENT_BOOKS.contains(self)) {
                return Constants.New_Testament
        }
        
        return Constants.EMPTY_STRING
    }
    
    var verses: [Int]?
    {
//        guard let scripture = scripture else {
//            return nil
//        }
        
        var verses = [Int]()
        
        var string = self.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
        
        if string.isEmpty {
            return []
        }
        
        //Is not correct for books with only one chapter
        // e.g. ["Philemon","Jude","2 John","3 John"]
        guard let colon = string.range(of: ":") else {
            return []
        }
        
        string = String(string[colon.upperBound...])
        
        var chars = Constants.EMPTY_STRING
        
        var seenHyphen = false
        var seenComma = false
        
        var startVerse = 0
        var endVerse = 0
        
        var breakOut = false
        
        for character in string {
            if breakOut {
                break
            }
            switch character {
            case "–":
                fallthrough
            case "-":
                seenHyphen = true
                if (startVerse == 0) {
                    if let num = Int(chars) {
                        startVerse = num
                    }
                }
                chars = Constants.EMPTY_STRING
                break
                
            case "(":
                breakOut = true
                break
                
            case ",":
                seenComma = true
                if let num = Int(chars) {
                    verses.append(num)
                }
                chars = Constants.EMPTY_STRING
                break
                
            default:
                chars.append(character)
                //                print(chars)
                break
            }
        }
        if !seenHyphen {
            if let num = Int(chars) {
                startVerse = num
            }
        }
        if (startVerse != 0) {
            if (endVerse == 0) {
                if let num = Int(chars) {
                    endVerse = num
                }
                chars = Constants.EMPTY_STRING
            }
            if (endVerse != 0) {
                for verse in startVerse...endVerse {
                    verses.append(verse)
                }
            } else {
                verses.append(startVerse)
            }
        }
        if seenComma {
            if let num = Int(chars) {
                verses.append(num)
            }
        }
        return verses.count > 0 ? verses : nil
    }

    var chaptersAndVerses : [Int:[Int]]?
    {
//        guard let book = book else {
//            return nil
//        }
        
        let book = self
        
        var chaptersAndVerses = [Int:[Int]]()
        
        var startChapter = 0
        var endChapter = 0
        var startVerse = 0
        var endVerse = 0
        
        startChapter = 1
        
        switch self.testament {
        case Constants.Old_Testament:
            if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
                endChapter = Constants.OLD_TESTAMENT_CHAPTERS[index]
            }
            break
            
        case Constants.New_Testament:
            if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
                endChapter = Constants.NEW_TESTAMENT_CHAPTERS[index]
            }
            break
            
        default:
            break
        }
        
        for chapter in startChapter...endChapter {
            startVerse = 1
            
            switch book.testament {
            case Constants.Old_Testament:
                if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                }
                break
                
            case Constants.New_Testament:
                if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
                    endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
                }
                break
                
            default:
                break
            }
            
            for verse in startVerse...endVerse {
                if chaptersAndVerses[chapter] == nil {
                    chaptersAndVerses[chapter] = [verse]
                } else {
                    chaptersAndVerses[chapter]?.append(verse)
                }
            }
        }
        
        return chaptersAndVerses
    }
    
    func versesForChapter(_ chapter:Int) -> [Int]?
    {
//        guard let book = book else {
//            return nil
//        }
        
        let book = self
        
        var verses = [Int]()
        
        let startVerse = 1
        var endVerse = 0
        
        switch self.testament {
        case Constants.Old_Testament:
            if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                index < Constants.OLD_TESTAMENT_VERSES.count,
                chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
            }
            break
        case Constants.New_Testament:
            if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
                index < Constants.NEW_TESTAMENT_VERSES.count,
                chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
            }
            break
        default:
            break
        }
        
        if startVerse == endVerse {
            verses.append(startVerse)
        } else {
            if endVerse >= startVerse {
                for verse in startVerse...endVerse {
                    verses.append(verse)
                }
            }
        }
        
        return verses.count > 0 ? verses : nil
    }
    
    func chaptersAndVerses(book:String?) -> [Int:[Int]]?
    {
        // This can only comprehend a range of chapters or a range of verses from a single book.
        
        guard let book = book else {
            return nil
        }
        
        guard (self.range(of: ".") == nil) else {
            return nil
        }
        
        guard (self.range(of: "&") == nil) else {
            return nil
        }
        
        let string = self.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
        
        guard !string.isEmpty else {
            // Now we have a book w/ no chapter or verse references
            // FILL in all chapters and all verses and return
            
            return book.chaptersAndVerses
        }
        
        var chaptersAndVerses = [Int:[Int]]()
        
        var tokens = [String]()
        
        var currentChapter = 0
        var startChapter = 0
        var endChapter = 0
        var startVerse = 0
        var endVerse = 0
        
        var token = Constants.EMPTY_STRING
        
        for char in string {
            if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: ":,-").contains(unicodeScalar) {
                tokens.append(token)
                token = Constants.EMPTY_STRING
                
                tokens.append(String(char))
            } else {
                if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: "0123456789").contains(unicodeScalar) {
                    token.append(char)
                }
            }
        }
        
        if token != Constants.EMPTY_STRING {
            tokens.append(token)
        }
        
        debug("Done w/ parsing and creating tokens")
        
        if tokens.count > 0 {
            var startVerses = Constants.NO_CHAPTER_BOOKS.contains(book)
            
            if let first = tokens.first, let number = Int(first) {
                tokens.remove(at: 0)
                if Constants.NO_CHAPTER_BOOKS.contains(book) {
                    currentChapter = 1
                    startVerse = number
                } else {
                    currentChapter = number
                    startChapter = number
                }
            } else {
                return book.chaptersAndVerses
            }
            
            repeat {
                if let first = tokens.first {
                    tokens.remove(at: 0)
                    
                    switch first {
                    case ":":
                        debug(": Verses follow")
                        
                        startVerses = true
                        //                        startChapter = 0
                        break
                        
                    case ",":
                        if !startVerses {
                            debug(", Look for chapters")
                            
                            if let first = tokens.first, let number = Int(first) {
                                tokens.remove(at: 0)
                                
                                if tokens.first == ":" {
                                    tokens.remove(at: 0)
                                    startChapter = number
                                    currentChapter = number
                                } else {
                                    currentChapter = number
                                    chaptersAndVerses[currentChapter] = book.versesForChapter(currentChapter)
                                    
                                    if chaptersAndVerses[currentChapter] == nil {
                                        print(book as Any,self as Any)
                                    }
                                }
                            }
                        } else {
                            debug(", Look for verses")
                            
                            if startVerse > 0 {
                                if chaptersAndVerses[currentChapter] == nil {
                                    chaptersAndVerses[currentChapter] = [Int]()
                                }
                                chaptersAndVerses[currentChapter]?.append(startVerse)
                                
                                startVerse = 0
                            }
                            
                            if let first = tokens.first, let number = Int(first) {
                                tokens.remove(at: 0)
                                
                                if let first = tokens.first {
                                    switch first {
                                    case ":":
                                        tokens.remove(at: 0)
                                        startVerses = true
                                        
                                        startChapter = number
                                        currentChapter = number
                                        break
                                        
                                    case "-":
                                        tokens.remove(at: 0)
                                        if endVerse > 0, number < endVerse {
                                            // This is a chapter!
                                            startVerse = 0
                                            endVerse = 0
                                            
                                            startChapter = number
                                            
                                            if let first = tokens.first, let number = Int(first) {
                                                tokens.remove(at: 0)
                                                endChapter = number
                                                
                                                for chapter in startChapter...endChapter {
                                                    startVerse = 1
                                                    
                                                    switch book.testament {
                                                    case Constants.Old_Testament:
                                                        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                                            index < Constants.OLD_TESTAMENT_VERSES.count,
                                                            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                                        }
                                                        break
                                                    case Constants.New_Testament:
                                                        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
                                                            index < Constants.NEW_TESTAMENT_VERSES.count,
                                                            chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                                            endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
                                                        }
                                                        break
                                                    default:
                                                        break
                                                    }
                                                    
                                                    if endVerse >= startVerse {
                                                        if chaptersAndVerses[chapter] == nil {
                                                            chaptersAndVerses[chapter] = [Int]()
                                                        }
                                                        if startVerse == endVerse {
                                                            chaptersAndVerses[chapter]?.append(startVerse)
                                                        } else {
                                                            for verse in startVerse...endVerse {
                                                                chaptersAndVerses[chapter]?.append(verse)
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                startChapter = 0
                                            }
                                        } else {
                                            startVerse = number
                                            if let first = tokens.first, let number = Int(first) {
                                                tokens.remove(at: 0)
                                                endVerse = number
                                                if chaptersAndVerses[currentChapter] == nil {
                                                    chaptersAndVerses[currentChapter] = [Int]()
                                                }
                                                for verse in startVerse...endVerse {
                                                    chaptersAndVerses[currentChapter]?.append(verse)
                                                }
                                                startVerse = 0
                                            }
                                        }
                                        break
                                        
                                    default:
                                        if chaptersAndVerses[currentChapter] == nil {
                                            chaptersAndVerses[currentChapter] = [Int]()
                                        }
                                        chaptersAndVerses[currentChapter]?.append(number)
                                        break
                                    }
                                } else {
                                    if chaptersAndVerses[currentChapter] == nil {
                                        chaptersAndVerses[currentChapter] = [Int]()
                                    }
                                    chaptersAndVerses[currentChapter]?.append(number)
                                }
                                
                                if tokens.first == nil {
                                    startChapter = 0
                                }
                            }
                        }
                        break
                        
                    case "-":
                        if !startVerses {
                            debug("- Look for chapters")
                            
                            if let first = tokens.first, let chapter = Int(first) {
                                debug("Reference is split across chapters")
                                tokens.remove(at: 0)
                                endChapter = chapter
                            }
                            
                            debug("See if endChapter has verses")
                            
                            if tokens.first == ":" {
                                tokens.remove(at: 0)
                                
                                debug("First get the endVerse for the startChapter in the reference")
                                
                                startVerse = 1
                                
                                switch book.testament {
                                case Constants.Old_Testament:
                                    if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                        index < Constants.OLD_TESTAMENT_VERSES.count,
                                        startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
                                    }
                                    break
                                case Constants.New_Testament:
                                    if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
                                        index < Constants.NEW_TESTAMENT_VERSES.count,
                                        startChapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                        endVerse = Constants.NEW_TESTAMENT_VERSES[index][startChapter - 1]
                                    }
                                    break
                                default:
                                    break
                                }
                                
                                debug("Add the remaining verses for the startChapter")
                                
                                if chaptersAndVerses[startChapter] == nil {
                                    chaptersAndVerses[startChapter] = [Int]()
                                }
                                if startVerse == endVerse {
                                    chaptersAndVerses[startChapter]?.append(startVerse)
                                } else {
                                    for verse in startVerse...endVerse {
                                        chaptersAndVerses[startChapter]?.append(verse)
                                    }
                                }
                                
                                debug("Done w/ startChapter")
                                
                                startVerse = 0
                                //                            endVerse = 0
                                
                                debug("Now determine whether there are any chapters between the first and the last in the reference")
                                
                                if (endChapter - startChapter) > 1 {
                                    let start = startChapter + 1
                                    let end = endChapter - 1
                                    
                                    debug("If there are, add those verses")
                                    
                                    for chapter in start...end {
                                        startVerse = 1
                                        
                                        switch book.testament {
                                        case Constants.Old_Testament:
                                            if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                                index < Constants.OLD_TESTAMENT_VERSES.count,
                                                chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                            }
                                            break
                                        case Constants.New_Testament:
                                            if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
                                                index < Constants.NEW_TESTAMENT_VERSES.count,
                                                chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                                endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
                                            }
                                            break
                                        default:
                                            break
                                        }
                                        
                                        if endVerse >= startVerse {
                                            if chaptersAndVerses[chapter] == nil {
                                                chaptersAndVerses[chapter] = [Int]()
                                            }
                                            if startVerse == endVerse {
                                                chaptersAndVerses[chapter]?.append(startVerse)
                                            } else {
                                                for verse in startVerse...endVerse {
                                                    chaptersAndVerses[chapter]?.append(verse)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                debug("Done w/ chapters between startChapter and endChapter")
                                
                                debug("Now add the verses from the endChapter")
                                
                                debug("First find the end verse")
                                
                                if let first = tokens.first, let number = Int(first) {
                                    tokens.remove(at: 0)
                                    
                                    startVerse = 1
                                    endVerse = number
                                    
                                    if endVerse >= startVerse {
                                        if chaptersAndVerses[endChapter] == nil {
                                            chaptersAndVerses[endChapter] = [Int]()
                                        }
                                        if startVerse == endVerse {
                                            chaptersAndVerses[endChapter]?.append(startVerse)
                                        } else {
                                            for verse in startVerse...endVerse {
                                                chaptersAndVerses[endChapter]?.append(verse)
                                            }
                                        }
                                    }
                                    
                                    debug("Done w/ verses")
                                    
                                    startVerse = 0
                                }
                                
                                debug("Done w/ endChapter")
                            } else {
                                startVerse = 1
                                
                                switch book.testament {
                                case Constants.Old_Testament:
                                    if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                        index < Constants.OLD_TESTAMENT_VERSES.count,
                                        startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
                                    }
                                    break
                                case Constants.New_Testament:
                                    if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
                                        index < Constants.NEW_TESTAMENT_VERSES.count,
                                        startChapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                        endVerse = Constants.NEW_TESTAMENT_VERSES[index][startChapter - 1]
                                    }
                                    break
                                default:
                                    break
                                }
                                
                                debug("Add the verses for the startChapter")
                                
                                if chaptersAndVerses[startChapter] == nil {
                                    chaptersAndVerses[startChapter] = [Int]()
                                }
                                if startVerse == endVerse {
                                    chaptersAndVerses[startChapter]?.append(startVerse)
                                } else {
                                    for verse in startVerse...endVerse {
                                        chaptersAndVerses[startChapter]?.append(verse)
                                    }
                                }
                                
                                debug("Done w/ startChapter")
                                
                                startVerse = 0
                                
                                debug("Now determine whether there are any chapters between the first and the last in the reference")
                                
                                if (endChapter - startChapter) > 1 {
                                    let start = startChapter + 1
                                    let end = endChapter - 1
                                    
                                    debug("If there are, add those verses")
                                    
                                    for chapter in start...end {
                                        startVerse = 1
                                        
                                        switch book.testament {
                                        case Constants.Old_Testament:
                                            if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                                index < Constants.OLD_TESTAMENT_VERSES.count,
                                                chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                            }
                                            break
                                        case Constants.New_Testament:
                                            if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
                                                index < Constants.NEW_TESTAMENT_VERSES.count,
                                                chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                                endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
                                            }
                                            break
                                        default:
                                            break
                                        }
                                        
                                        if endVerse >= startVerse {
                                            if chaptersAndVerses[chapter] == nil {
                                                chaptersAndVerses[chapter] = [Int]()
                                            }
                                            if startVerse == endVerse {
                                                chaptersAndVerses[chapter]?.append(startVerse)
                                            } else {
                                                for verse in startVerse...endVerse {
                                                    chaptersAndVerses[chapter]?.append(verse)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                debug("Done w/ chapters between startChapter and endChapter")
                                
                                debug("Now add the verses from the endChapter")
                                
                                startVerse = 1
                                
                                switch book.testament {
                                case Constants.Old_Testament:
                                    if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                        index < Constants.OLD_TESTAMENT_VERSES.count,
                                        endChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][endChapter - 1]
                                    }
                                    break
                                case Constants.New_Testament:
                                    if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
                                        index < Constants.NEW_TESTAMENT_VERSES.count,
                                        endChapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                        endVerse = Constants.NEW_TESTAMENT_VERSES[index][endChapter - 1]
                                    }
                                    break
                                default:
                                    break
                                }
                                
                                if endVerse >= startVerse {
                                    if chaptersAndVerses[endChapter] == nil {
                                        chaptersAndVerses[endChapter] = [Int]()
                                    }
                                    if startVerse == endVerse {
                                        chaptersAndVerses[endChapter]?.append(startVerse)
                                    } else {
                                        for verse in startVerse...endVerse {
                                            chaptersAndVerses[endChapter]?.append(verse)
                                        }
                                    }
                                }
                                
                                debug("Done w/ verses")
                                
                                startVerse = 0
                                
                                debug("Done w/ endChapter")
                            }
                            
                            debug("Done w/ chapters")
                            
                            startChapter = 0
                            endChapter = 0
                            
                            currentChapter = 0
                        } else {
                            debug("- Look for verses")
                            
                            if let first = tokens.first,let number = Int(first) {
                                tokens.remove(at: 0)
                                
                                debug("See if reference is split across chapters")
                                
                                if tokens.first == ":" {
                                    tokens.remove(at: 0)
                                    
                                    debug("Reference is split across chapters")
                                    debug("First get the endVerse for the first chapter in the reference")
                                    
                                    switch book.testament {
                                    case Constants.Old_Testament:
                                        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][currentChapter - 1]
                                        }
                                        break
                                    case Constants.New_Testament:
                                        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
                                            endVerse = Constants.NEW_TESTAMENT_VERSES[index][currentChapter - 1]
                                        }
                                        break
                                    default:
                                        break
                                    }
                                    
                                    debug("Add the remaining verses for the first chapter")
                                    
                                    if chaptersAndVerses[currentChapter] == nil {
                                        chaptersAndVerses[currentChapter] = [Int]()
                                    }
                                    if startVerse == endVerse {
                                        chaptersAndVerses[currentChapter]?.append(startVerse)
                                    } else {
                                        for verse in startVerse...endVerse {
                                            chaptersAndVerses[currentChapter]?.append(verse)
                                        }
                                    }
                                    
                                    debug("Done w/ verses")
                                    
                                    startVerse = 0
                                    
                                    debug("Now determine whehter there are any chapters between the first and the last in the reference")
                                    
                                    currentChapter = number
                                    endChapter = number
                                    
                                    if (endChapter - startChapter) > 1 {
                                        let start = startChapter + 1
                                        let end = endChapter - 1
                                        
                                        debug("If there are, add those verses")
                                        
                                        for chapter in start...end {
                                            startVerse = 1
                                            
                                            switch book.testament {
                                            case Constants.Old_Testament:
                                                if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
                                                    index < Constants.OLD_TESTAMENT_VERSES.count,
                                                    chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                                }
                                                break
                                            case Constants.New_Testament:
                                                if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
                                                    index < Constants.NEW_TESTAMENT_VERSES.count,
                                                    chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
                                                    endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
                                                }
                                                break
                                            default:
                                                break
                                            }
                                            
                                            if endVerse >= startVerse {
                                                if chaptersAndVerses[chapter] == nil {
                                                    chaptersAndVerses[chapter] = [Int]()
                                                }
                                                if startVerse == endVerse {
                                                    chaptersAndVerses[chapter]?.append(startVerse)
                                                } else {
                                                    for verse in startVerse...endVerse {
                                                        chaptersAndVerses[chapter]?.append(verse)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    debug("Now add the verses from the last chapter")
                                    debug("First find the end verse")
                                    
                                    if let first = tokens.first, let number = Int(first) {
                                        tokens.remove(at: 0)
                                        
                                        startVerse = 1
                                        endVerse = number
                                        
                                        if chaptersAndVerses[currentChapter] == nil {
                                            chaptersAndVerses[currentChapter] = [Int]()
                                        }
                                        if startVerse == endVerse {
                                            chaptersAndVerses[currentChapter]?.append(startVerse)
                                        } else {
                                            for verse in startVerse...endVerse {
                                                chaptersAndVerses[currentChapter]?.append(verse)
                                            }
                                        }
                                        
                                        debug("Done w/ verses")
                                        
                                        startVerse = 0
                                    }
                                } else {
                                    debug("reference is not split across chapters")
                                    
                                    endVerse = number
                                    
                                    debug("\(currentChapter) \(startVerse) \(endVerse)")
                                    
                                    if chaptersAndVerses[currentChapter] == nil {
                                        chaptersAndVerses[currentChapter] = [Int]()
                                    }
                                    if startVerse == endVerse {
                                        chaptersAndVerses[currentChapter]?.append(startVerse)
                                    } else {
                                        for verse in startVerse...endVerse {
                                            chaptersAndVerses[currentChapter]?.append(verse)
                                        }
                                    }
                                    
                                    debug("Done w/ verses")
                                    
                                    startVerse = 0
                                }
                                
                                debug("Done w/ chapters")
                                
                                startChapter = 0
                                endChapter = 0
                            }
                        }
                        break
                        
                    default:
                        debug("default")
                        
                        if let number = Int(first) {
                            if let first = tokens.first {
                                if first == ":" {
                                    debug("chapter")
                                    
                                    startVerses = true
                                    startChapter = number
                                    currentChapter = number
                                } else {
                                    debug("chapter or verse")
                                    
                                    if startVerses {
                                        debug("verse")
                                        
                                        startVerse = number
                                    }
                                }
                            } else {
                                debug("no more tokens: chapter or verse")
                                
                                if startVerses {
                                    debug("verse")
                                    startVerse = number
                                }
                            }
                        } else {
                            // What happens in this case?
                            // We ignore it.  This is not a number or one of the text strings we recognize.
                        }
                        break
                    }
                }
            } while tokens.first != nil
            
            debug("Done w/ processing tokens")
            debug("If start and end (chapter,verse) remaining, process them")
            
            if startChapter > 0 {
                if endChapter > 0 {
                    if endChapter >= startChapter {
                        for chapter in startChapter...endChapter {
                            chaptersAndVerses[chapter] = book.versesForChapter(chapter)
                            
                            if chaptersAndVerses[chapter] == nil {
                                print(book as Any,self as Any)
                            }
                        }
                    }
                } else {
                    chaptersAndVerses[startChapter] = book.versesForChapter(startChapter)
                    
                    if chaptersAndVerses[startChapter] == nil {
                        print(book as Any,self as Any)
                    }
                }
                startChapter = 0
                endChapter = 0
            }
            if startVerse > 0 {
                if endVerse > 0 {
                    if chaptersAndVerses[currentChapter] == nil {
                        chaptersAndVerses[currentChapter] = [Int]()
                    }
                    for verse in startVerse...endVerse {
                        chaptersAndVerses[currentChapter]?.append(verse)
                    }
                } else {
                    chaptersAndVerses[currentChapter] = [startVerse]
                }
                startVerse = 0
                endVerse = 0
            }
        } else {
            return book.chaptersAndVerses
        }
        
        return chaptersAndVerses.count > 0 ? chaptersAndVerses : nil
    }
    
    var chapters : [Int]?
    {
        // This can only comprehend a range of chapters or a range of verses from a single book.
        
//        guard let scriptureReference = scriptureReference else {
//            return nil
//        }
        
        var chapters = [Int]()
        
        var colonCount = 0
        
        let string = self.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
        
        if (string == Constants.EMPTY_STRING) {
            return nil
        }
        
        let colon = string.range(of: ":")
        let hyphen = string.range(of: "-")
        let comma = string.range(of: ",")
        
        if (colon == nil) && (hyphen == nil) &&  (comma == nil) {
            if let number = Int(string) {
                chapters = [number]
            }
        } else {
            var chars = Constants.EMPTY_STRING
            
            var seenColon = false
            var seenHyphen = false
            var seenComma = false
            
            var startChapter = 0
            var endChapter = 0
            
            var breakOut = false
            
            for character in string {
                if breakOut {
                    break
                }
                switch character {
                case ":":
                    if !seenColon {
                        seenColon = true
                        if let num = Int(chars) {
                            if (startChapter == 0) {
                                startChapter = num
                            } else {
                                endChapter = num
                            }
                        }
                    } else {
                        if (seenHyphen) {
                            if let num = Int(chars) {
                                endChapter = num
                            }
                        } else {
                            //Error
                        }
                    }
                    colonCount += 1
                    chars = Constants.EMPTY_STRING
                    break
                    
                case "–":
                    fallthrough
                case "-":
                    seenHyphen = true
                    if colonCount == 0 {
                        // This is a chapter not a verse
                        if (startChapter == 0) {
                            if let num = Int(chars) {
                                startChapter = num
                            }
                        }
                    }
                    chars = Constants.EMPTY_STRING
                    break
                    
                case "(":
                    breakOut = true
                    break
                    
                case ",":
                    seenComma = true
                    if !seenColon {
                        // This is a chapter not a verse
                        if let num = Int(chars) {
                            chapters.append(num)
                        }
                        chars = Constants.EMPTY_STRING
                    } else {
                        // Could be chapter or a verse
                        chars = Constants.EMPTY_STRING
                    }
                    break
                    
                default:
                    chars.append(character)
                    break
                }
            }
            if (startChapter != 0) {
                if (endChapter == 0) {
                    if (colonCount == 0) {
                        if let num = Int(chars) {
                            endChapter = num
                        }
                        chars = Constants.EMPTY_STRING
                    }
                }
                if (endChapter != 0) {
                    for chapter in startChapter...endChapter {
                        chapters.append(chapter)
                    }
                } else {
                    chapters.append(startChapter)
                }
            }
            if seenComma {
                if let num = Int(chars) {
                    if !seenColon {
                        // This is a chapter not a verse
                        chapters.append(num)
                    }
                }
            }
        }
        
        return chapters.count > 0 ? chapters : nil
    }
    
    var books : [String]?
    {
//        guard let scriptureReference = scriptureReference else {
//            return nil
//        }
        
        let scriptureReference = self
        
        var books = [String]()
        
        var string = self
        
        var otBooks = [String]()
        
        for book in Constants.OLD_TESTAMENT_BOOKS {
            if let range = string.range(of: book) {
                otBooks.append(book)
                // .substring(to:
                string = String(string[..<range.lowerBound]) + Constants.SINGLE_SPACE + String(string[range.upperBound...])
            }
        }
        
        for book in Constants.NEW_TESTAMENT_BOOKS.reversed() {
            if let range = string.range(of: book) {
                books.append(book)
                // .substring(to:
                string = String(string[..<range.lowerBound]) + Constants.SINGLE_SPACE + String(string[range.upperBound...])
            }
        }
        
        let ntBooks = books.reversed()
        
        books = otBooks
        books.append(contentsOf: ntBooks)
        
        string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
        
        // Only works for "<book> - <book>"
        
        if (string == "-") {
            if books.count == 2 {
                let book1 = scriptureReference.range(of: books[0])
                let book2 = scriptureReference.range(of: books[1])
                let hyphen = scriptureReference.range(of: "-")
                
                if ((book1?.upperBound < hyphen?.lowerBound) && (hyphen?.upperBound < book2?.lowerBound)) ||
                    ((book2?.upperBound < hyphen?.lowerBound) && (hyphen?.upperBound < book1?.lowerBound)) {
                    books = [String]()
                    
                    let first = books[0]
                    let last = books[1]
                    
                    if Constants.OLD_TESTAMENT_BOOKS.contains(first) && Constants.OLD_TESTAMENT_BOOKS.contains(last) {
                        if let firstIndex = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: first),
                            let lastIndex = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: last) {
                            for index in firstIndex...lastIndex {
                                books.append(Constants.OLD_TESTAMENT_BOOKS[index])
                            }
                        }
                    }
                    
                    if Constants.OLD_TESTAMENT_BOOKS.contains(first) && Constants.NEW_TESTAMENT_BOOKS.contains(last) {
                        if let firstIndex = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: first) {
                            let lastIndex = Constants.OLD_TESTAMENT_BOOKS.count - 1
                            for index in firstIndex...lastIndex {
                                books.append(Constants.OLD_TESTAMENT_BOOKS[index])
                            }
                        }
                        let firstIndex = 0
                        if let lastIndex = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: last) {
                            for index in firstIndex...lastIndex {
                                books.append(Constants.NEW_TESTAMENT_BOOKS[index])
                            }
                        }
                    }
                    
                    if Constants.NEW_TESTAMENT_BOOKS.contains(first) && Constants.NEW_TESTAMENT_BOOKS.contains(last) {
                        if let firstIndex = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: first),
                            let lastIndex = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: last) {
                            for index in firstIndex...lastIndex {
                                books.append(Constants.NEW_TESTAMENT_BOOKS[index])
                            }
                        }
                    }
                }
            }
        }
        
        return books.count > 0 ? books.sorted() { scriptureReference.range(of: $0)?.lowerBound < scriptureReference.range(of: $1)?.lowerBound } : nil // redundant
    }
}

extension String
{
    var tagsSet : Set<String>?
    {
//        guard let tagsString = tagsString else {
//            return nil
//        }
        
        let tagsString = self
        
        var tags = tagsString
        var setOfTags = Set<String>()
        
        while let range = tags.range(of: Constants.TAGS_SEPARATOR) {
            // .substring(to:
            let tag = String(tags[..<range.lowerBound])
            setOfTags.insert(tag)
            tags = String(tags[range.upperBound...])
        }
        
        if !tags.isEmpty {
            setOfTags.insert(tags)
        }
        
        return setOfTags.count > 0 ? setOfTags : nil
    }
    
    var tagsArray : [String]?
    {
        var arrayOfTags:[String]?
        
        if let tags = self.tagsSet {
            arrayOfTags = Array(tags)
        }
        
        return arrayOfTags
    }

}

extension UIViewController
{
    func process(work:(()->(Any?))?,completion:((Any?)->())?)
    {
        let viewController = self
        
        guard let view = viewController.view else {
            return
        }
        
        guard (work != nil)  && (completion != nil) else {
            return
        }
        
        guard let loadingViewController = viewController.storyboard?.instantiateViewController(withIdentifier: "Loading View Controller") else {
            return
        }
        
        guard let container = loadingViewController.view else {
            return
        }
        
        Thread.onMainThread { () -> (Void) in
            if let buttons = viewController.navigationItem.rightBarButtonItems {
                for button in buttons {
                    button.isEnabled = false
                }
            }
            
            if let buttons = viewController.navigationItem.leftBarButtonItems {
                for button in buttons {
                    button.isEnabled = false
                }
            }
            
            container.frame = view.frame
            container.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
            
            container.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            
            view.addSubview(container)
            
            DispatchQueue.global(qos: .background).async {
                let data = work?()
                
                Thread.onMainThread { () -> (Void) in
                    if container != viewController.view {
                        container.removeFromSuperview()
                    }
                    
                    if let buttons = viewController.navigationItem.rightBarButtonItems {
                        for button in buttons {
                            button.isEnabled = true
                        }
                    }
                    
                    if let buttons = viewController.navigationItem.leftBarButtonItems {
                        for button in buttons {
                            button.isEnabled = true
                        }
                    }
                    
                    completion?(data)
                }
            }
        }
    }

}

