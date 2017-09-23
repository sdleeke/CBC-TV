//
//  functions.swift
//  CBC
//
//  Created by Steve Leeke on 8/18/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit

func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    case (nil, _?):
        return true
    default:
        return false
    }
}

func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

//typealias GroupTuple = (indexes: [Int]?, counts: [Int]?)

func documentsURL() -> URL?
{
    let fileManager = FileManager.default
    return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
}

func cachesURL() -> URL?
{
    let fileManager = FileManager.default
    return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
}

func filesOfTypeInCache(_ fileType:String) -> [String]?
{
    guard let path = cachesURL()?.path else {
        return nil
    }
    
    var files = [String]()
    
    let fileManager = FileManager.default
    
    do {
        let array = try fileManager.contentsOfDirectory(atPath: path)
        
        for string in array {
            if let range = string.range(of: fileType) {
                if fileType == string.substring(from: range.lowerBound) {
                    files.append(string)
                }
            }
        }
    } catch _ {
        print("failed to get files in caches directory")
    }
    
    return files.count > 0 ? files : nil
}

func removeJSONFromFileSystemDirectory()
{
    if let filename = globals.mediaCategory.filename, let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) {
        do {
            try FileManager.default.removeItem(atPath: jsonFileSystemURL.path)
        } catch _ {
            print("failed to copy mediaItems.json")
        }
    }
}

func jsonToFileSystemDirectory(key:String)
{
    guard let jsonBundlePath = Bundle.main.path(forResource: key, ofType: Constants.JSON.TYPE) else {
        return
    }
    
    let fileManager = FileManager.default
    
    if let filename = globals.mediaCategory.filename, let jsonFileURL = cachesURL()?.appendingPathComponent(filename) {
        // Check if file exist
        if (!fileManager.fileExists(atPath: jsonFileURL.path)){
            do {
                // Copy File From Bundle To Documents Directory
                try fileManager.copyItem(atPath: jsonBundlePath,toPath: jsonFileURL.path)
            } catch _ {
                print("failed to copy mediaItems.json")
            }
        } else {
            //    fileManager.removeItemAtPath(destination)
            // Which is newer, the bundle file or the file in the Documents folder?
            do {
                let jsonBundleAttributes = try fileManager.attributesOfItem(atPath: jsonBundlePath)
                
                let jsonDocumentsAttributes = try fileManager.attributesOfItem(atPath: jsonFileURL.path)
                
                let jsonBundleModDate = jsonBundleAttributes[FileAttributeKey.modificationDate] as! Date
                let jsonDocumentsModDate = jsonDocumentsAttributes[FileAttributeKey.modificationDate] as! Date
                
                if (jsonDocumentsModDate.isNewerThan(jsonBundleModDate)) {
                    //Do nothing, the json in Documents is newer, i.e. it was downloaded after the install.
                    print("JSON in Documents is newer than JSON in bundle")
                }
                
                if (jsonDocumentsModDate.isEqualTo(jsonBundleModDate)) {
                    print("JSON in Documents is the same date as JSON in bundle")
                    let jsonBundleFileSize = jsonBundleAttributes[FileAttributeKey.size] as! Int
                    let jsonDocumentsFileSize = jsonDocumentsAttributes[FileAttributeKey.size] as! Int
                    
                    if (jsonBundleFileSize != jsonDocumentsFileSize) {
                        print("Same dates different file sizes")
                        //We have a problem.
                    } else {
                        print("Same dates same file sizes")
                        //Do nothing, they are the same.
                    }
                }
                
                if (jsonBundleModDate.isNewerThan(jsonDocumentsModDate)) {
                    print("JSON in bundle is newer than JSON in Documents")
                    //copy the bundle into Documents directory
                    do {
                        // Copy File From Bundle To Documents Directory
                        try fileManager.removeItem(atPath: jsonFileURL.path)
                        try fileManager.copyItem(atPath: jsonBundlePath,toPath: jsonFileURL.path)
                    } catch _ {
                        print("failed to copy mediaItems.json")
                    }
                }
            } catch _ {
                print("failed to get json file attributes")
            }
        }
    }
}

func jsonFromURL(url:String) -> Any?
{
    guard globals.reachability.currentReachabilityStatus != .notReachable else {
        print("json not reachable.")
        
        //            globals.alert(title:"Network Error",message:"Newtork not available, attempting to load last available media list.")
        
        return nil
    }
    
    guard let url = URL(string: url) else {
        return nil
    }
    
    do {
        let data = try Data(contentsOf: url) // , options: NSData.ReadingOptions.mappedIfSafe
        print("able to read json from the URL.")
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            return json
        } catch let error as NSError {
            NSLog(error.localizedDescription)
        }
    } catch let error as NSError {
        NSLog(error.localizedDescription)
    }
    
    return nil
}

func jsonFromURL(url:String,filename:String) -> Any?
{
    guard let url = URL(string: url) else {
        return nil
    }
    
    guard let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) else {
        return nil
    }
    
    guard globals.reachability.currentReachabilityStatus != .notReachable else {
        print("json not reachable.")
        
        //            globals.alert(title:"Network Error",message:"Newtork not available, attempting to load last available media list.")
        
        return jsonFromFileSystem(filename: filename)
    }
    
    do {
        let data = try Data(contentsOf: url) // , options: NSData.ReadingOptions.mappedIfSafe
        print("able to read json from the URL.")
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            do {
                try data.write(to: jsonFileSystemURL)//, options: NSData.WritingOptions.atomic)
                
                print("able to write json to the file system")
            } catch let error as NSError {
                print("unable to write json to the file system.")
                
                NSLog(error.localizedDescription)
            }
            
            print(json)
            return json
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            return jsonFromFileSystem(filename: filename)
        }
    } catch let error as NSError {
        NSLog(error.localizedDescription)
        return jsonFromFileSystem(filename: filename)
    }
}

func jsonFromFileSystem(filename:String?) -> Any?
{
    guard let filename = filename else {
        return nil
    }
    
    guard let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) else {
        return nil
    }
    
    do {
        let data = try Data(contentsOf: jsonFileSystemURL) // , options: NSData.ReadingOptions.mappedIfSafe
        print("able to read json from the URL.")
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            return nil
        }
    } catch let error as NSError {
        print("Network unavailable: json could not be read from the file system.")
        NSLog(error.localizedDescription)
        return nil
    }
}

func jsonDataFromDocumentsDirectory() -> Any?
{
    jsonToFileSystemDirectory(key:Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES)
    
    if let filename = globals.mediaCategory.filename, let jsonURL = cachesURL()?.appendingPathComponent(filename) {
        if let data = try? Data(contentsOf: jsonURL) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                return json
            } catch let error as NSError {
                NSLog(error.localizedDescription)
                return nil
            }

//            let json = JSON(data: data)
//            if json != JSON.null {
//                return json
//            } else {
//                print("could not get json from data, make sure the file contains valid json.")
//            }
        } else {
            print("could not get data from the json file.")
        }
    }
    
    return nil
}

func jsonDataFromCachesDirectory() -> Any?
{
    if let filename = globals.mediaCategory.filename, let jsonURL = cachesURL()?.appendingPathComponent(filename) {
        if let data = try? Data(contentsOf: jsonURL) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                return json
            } catch let error as NSError {
                NSLog(error.localizedDescription)
                return nil
            }
            
//            let json = JSON(data: data)
//            if json != JSON.null {
//                return json
//            } else {
//                print("could not get json from data, make sure the file contains valid json.")
//            }
        } else {
            print("could not get data from the json file.")
        }
    }
    
    return nil
}

extension Date
{
    //MARK: Date extension

    init(dateString:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        let d = dateStringFormatter.date(from: dateString)!
        self = Date(timeInterval:0, since:d)
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

func stringWithoutPrefixes(_ fromString:String?) -> String?
{
    if let range = fromString?.range(of: "A is "), range.lowerBound == "a".startIndex {
        return fromString
    }
    
    let sourceString = fromString?.replacingOccurrences(of: Constants.QUOTE, with: Constants.EMPTY_STRING).replacingOccurrences(of: "...", with: Constants.EMPTY_STRING)
//    print(sourceString)
    
    let prefixes = ["A ","An ","The "] // "And ",
    
    var sortString = sourceString
    
    for prefix in prefixes {
        if (sourceString?.endIndex >= prefix.endIndex) && (sourceString?.substring(to: prefix.endIndex).lowercased() == prefix.lowercased()) {
            sortString = sourceString?.substring(from: prefix.endIndex)
            break
        }
    }

    if sortString == "" {
        print(sortString as Any)
    }

    return sortString
}

func mediaItemSections(_ mediaItems:[MediaItem]?,sorting:String?,grouping:String?) -> [String]?
{
    guard let sorting = sorting, let grouping = grouping else {
        return nil
    }
    
    var strings:[String]?
    
    switch grouping {
    case GROUPING.YEAR:
        strings = yearsFromMediaItems(mediaItems, sorting: sorting)?.map() { (year) in
            return "\(year)"
        }
        break
        
    case GROUPING.TITLE:
        strings = seriesSectionsFromMediaItems(mediaItems,withTitles: true)
        break
        
    case GROUPING.BOOK:
        strings = bookSectionsFromMediaItems(mediaItems)
        break
        
    case GROUPING.SPEAKER:
        strings = speakerSectionsFromMediaItems(mediaItems)
        break
        
    case GROUPING.CLASS:
        strings = classSectionsFromMediaItems(mediaItems)
        break
        
    default:
        strings = nil
        break
    }
    
    return strings
}


func yearsFromMediaItems(_ mediaItems:[MediaItem]?, sorting: String?) -> [Int]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    guard let sorting = sorting else {
        return nil
    }
    
    return Array(
            Set(
                mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
                    assert(mediaItem.fullDate != nil) // We're assuming this gets ALL mediaItems.
                    return mediaItem.fullDate != nil
                }).map({ (mediaItem:MediaItem) -> Int in
                    let calendar = Calendar.current
                    let components = (calendar as NSCalendar).components(.year, from: mediaItem.fullDate! as Date)
                    return components.year!
                })
            )
            ).sorted(by: { (first:Int, second:Int) -> Bool in
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

func testament(_ book:String) -> String
{
    if (Constants.OLD_TESTAMENT_BOOKS.contains(book)) {
        return Constants.Old_Testament
    } else
        if (Constants.NEW_TESTAMENT_BOOKS.contains(book)) {
            return Constants.New_Testament
    }
    
    return Constants.EMPTY_STRING
}

func versesFromScripture(_ scripture:String?) -> [Int]?
{
    guard let scripture = scripture else {
        return nil
    }
    
    var verses = [Int]()

    var string = scripture.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
    
    if string.isEmpty {
        return []
    }
    
    //Is not correct for books with only one chapter
    // e.g. ["Philemon","Jude","2 John","3 John"]
    guard let colon = string.range(of: ":") else {
        return []
    }
    
    //        let hyphen = string?.range(of: "-")
    //        let comma = string?.range(of: ",")
    
    string = string.substring(from: colon.upperBound)
    
    var chars = Constants.EMPTY_STRING
    
    var seenHyphen = false
    var seenComma = false
    
    var startVerse = 0
    var endVerse = 0
    
    var breakOut = false
    
    for character in string.characters {
        if breakOut {
            break
        }
        switch character {
        case "–":
            fallthrough
        case "-":
            seenHyphen = true
            if (startVerse == 0) {
                if Int(chars) != nil {
                    startVerse = Int(chars)!
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
        if Int(chars) != nil {
            startVerse = Int(chars)!
        }
    }
    if (startVerse != 0) {
        if (endVerse == 0) {
            if (Int(chars) != nil) {
                endVerse = Int(chars)!
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

func debug(_ string:String)
{
//    print(string)
}

func chaptersAndVersesForBook(_ book:String?) -> [Int:[Int]]?
{
    guard let book = book else {
        return nil
    }
    
    var chaptersAndVerses = [Int:[Int]]()
    
    var startChapter = 0
    var endChapter = 0
    var startVerse = 0
    var endVerse = 0

    startChapter = 1
    
    switch testament(book) {
    case Constants.Old_Testament:
        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book) {
            endChapter = Constants.OLD_TESTAMENT_CHAPTERS[index]
        }
        break
        
    case Constants.New_Testament:
        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book) {
            endChapter = Constants.NEW_TESTAMENT_CHAPTERS[index]
        }
        break
        
    default:
        break
    }
    
    for chapter in startChapter...endChapter {
        startVerse = 1
        
        switch testament(book) {
        case Constants.Old_Testament:
            if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book) {
                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
            }
            break
            
        case Constants.New_Testament:
            if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book) {
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

func versesForBookChapter(_ book:String?,_ chapter:Int) -> [Int]?
{
    guard let book = book else {
        return nil
    }
 
    var verses = [Int]()
    
    let startVerse = 1
    var endVerse = 0
    
    switch testament(book) {
    case Constants.Old_Testament:
        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
            index < Constants.OLD_TESTAMENT_VERSES.count,
            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
        }
        break
    case Constants.New_Testament:
        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
    
//    if verses.count == 0 {
//        switch testament(book!) {
//        case Constants.Old_Testament:
//            let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book!)
//            print(Constants.OLD_TESTAMENT_BOOKS.index(of: book!)!,Constants.OLD_TESTAMENT_VERSES.count,Constants.OLD_TESTAMENT_VERSES[index!].count)
//            break
//        case Constants.New_Testament:
//            let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book!)
//            print(Constants.NEW_TESTAMENT_BOOKS.index(of: book!)!,Constants.NEW_TESTAMENT_VERSES.count,Constants.NEW_TESTAMENT_VERSES[index!].count)
//            break
//        default:
//            break
//        }
//        print(book!,index,chapter)
//    }
    
    return verses.count > 0 ? verses : nil
}

func chaptersAndVersesFromScripture(book:String?,reference:String?) -> [Int:[Int]]?
{
    // This can only comprehend a range of chapters or a range of verses from a single book.
//    if (book == "Mark") && (reference == " 2:23-3:6") {
//        print(book,reference)
//    }
    guard let book = book else {
        return nil
    }
    
    guard (reference?.range(of: ".") == nil) else {
        return nil
    }
    
    guard (reference?.range(of: "&") == nil) else {
        return nil
    }
    
    guard let string = reference?.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING), !string.isEmpty else {
        //        print(book,reference)
        
        // Now we have a book w/ no chapter or verse references
        // FILL in all chapters and all verses and return
        
        return chaptersAndVersesForBook(book)
    }

    var chaptersAndVerses = [Int:[Int]]()
    
    var tokens = [String]()
    
    var currentChapter = 0
    var startChapter = 0
    var endChapter = 0
    var startVerse = 0
    var endVerse = 0
    
    //        print(book!,reference!)
    
//    print(string)
    
    var token = Constants.EMPTY_STRING
    
    for char in string.characters {
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
            return chaptersAndVersesForBook(book)
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
                                chaptersAndVerses[currentChapter] = versesForBookChapter(book,currentChapter)
                                
                                if chaptersAndVerses[currentChapter] == nil {
                                    print(book as Any,reference as Any)
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
                                                
                                                switch testament(book) {
                                                case Constants.Old_Testament:
                                                    if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                                        index < Constants.OLD_TESTAMENT_VERSES.count,
                                                        chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                                    }
                                                    break
                                                case Constants.New_Testament:
                                                    if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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

//                        if tokens.first == ":" {
//                            tokens.remove(at: 0)
//                            startVerses = true
//                            
//                            if let number = Int(first) {
//                                startChapter = number
//                                currentChapter = number
//                            }
//                        } else {
//                        }
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
                            
                            switch testament(book) {
                            case Constants.Old_Testament:
                                if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                    index < Constants.OLD_TESTAMENT_VERSES.count,
                                    startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
                                }
                                break
                            case Constants.New_Testament:
                                if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
                                    
                                    switch testament(book) {
                                    case Constants.Old_Testament:
                                        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                            index < Constants.OLD_TESTAMENT_VERSES.count,
                                            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                        }
                                        break
                                    case Constants.New_Testament:
                                        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
//                                endVerse = 0
                            }
                            
                            debug("Done w/ endChapter")
                        } else {
                            startVerse = 1
                            
                            switch testament(book) {
                            case Constants.Old_Testament:
                                if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                    index < Constants.OLD_TESTAMENT_VERSES.count,
                                    startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
                                }
                                break
                            case Constants.New_Testament:
                                if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
//                            endVerse = 0
                            
                            debug("Now determine whether there are any chapters between the first and the last in the reference")
                            
                            if (endChapter - startChapter) > 1 {
                                let start = startChapter + 1
                                let end = endChapter - 1
                                
                                debug("If there are, add those verses")
                                
                                for chapter in start...end {
                                    startVerse = 1
                                    
                                    switch testament(book) {
                                    case Constants.Old_Testament:
                                        if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                            index < Constants.OLD_TESTAMENT_VERSES.count,
                                            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                        }
                                        break
                                    case Constants.New_Testament:
                                        if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
                            
                            switch testament(book) {
                            case Constants.Old_Testament:
                                if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                    index < Constants.OLD_TESTAMENT_VERSES.count,
                                    endChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][endChapter - 1]
                                }
                                break
                            case Constants.New_Testament:
                                if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
//                            endVerse = 0
                            
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
                                
                                switch testament(book) {
                                case Constants.Old_Testament:
                                    if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book) {
                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][currentChapter - 1]
                                    }
                                    break
                                case Constants.New_Testament:
                                    if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book) {
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
//                                endVerse = 0
                                
                                debug("Now determine whehter there are any chapters between the first and the last in the reference")
                                
                                currentChapter = number
                                endChapter = number
                                
                                if (endChapter - startChapter) > 1 {
                                    let start = startChapter + 1
                                    let end = endChapter - 1
                                    
                                    debug("If there are, add those verses")
                                    
                                    for chapter in start...end {
                                        startVerse = 1
                                        
                                        switch testament(book) {
                                        case Constants.Old_Testament:
                                            if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book),
                                                index < Constants.OLD_TESTAMENT_VERSES.count,
                                                chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
                                                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
                                            }
                                            break
                                        case Constants.New_Testament:
                                            if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book),
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
//                                    endVerse = 0
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
//                                endVerse = 0
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
        
//        print(book!,reference!)
        
        if startChapter > 0 {
            if endChapter > 0 {
                if endChapter >= startChapter {
                    for chapter in startChapter...endChapter {
                        chaptersAndVerses[chapter] = versesForBookChapter(book,chapter)
                        
                        if chaptersAndVerses[chapter] == nil {
                            print(book as Any,reference as Any)
                        }
                    }
                }
            } else {
                chaptersAndVerses[startChapter] = versesForBookChapter(book,startChapter)
                
                if chaptersAndVerses[startChapter] == nil {
                    print(book as Any,reference as Any)
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
//        print(book,reference,string,tokens)
        return chaptersAndVersesForBook(book)
    }

//    print(chaptersAndVerses)

    return chaptersAndVerses.count > 0 ? chaptersAndVerses : nil
}

func chaptersFromScriptureReference(_ scriptureReference:String?) -> [Int]?
{
    // This can only comprehend a range of chapters or a range of verses from a single book.

    guard let scriptureReference = scriptureReference else {
        return nil
    }
    
    var chapters = [Int]()
    
    var colonCount = 0
    
    let string = scriptureReference.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
    
    if (string == Constants.EMPTY_STRING) {
        return nil
    }
    
    //        print("\(string!)")
    
    let colon = string.range(of: ":")
    let hyphen = string.range(of: "-")
    let comma = string.range(of: ",")
    
    //        print(scripture,string)
    
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
        
        for character in string.characters {
            if breakOut {
                break
            }
            switch character {
            case ":":
                if !seenColon {
                    seenColon = true
                    if (Int(chars) != nil) {
                        if (startChapter == 0) {
                            startChapter = Int(chars)!
                        } else {
                            endChapter = Int(chars)!
                        }
                    }
                } else {
                    if (seenHyphen) {
                        if (Int(chars) != nil) {
                            endChapter = Int(chars)!
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
                        if Int(chars) != nil {
                            startChapter = Int(chars)!
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
                //                    print(chars)
                break
            }
        }
        if (startChapter != 0) {
            if (endChapter == 0) {
                if (colonCount == 0) {
                    if (Int(chars) != nil) {
                        endChapter = Int(chars)!
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
            if Int(chars) != nil {
                if !seenColon {
                    // This is a chapter not a verse
                    if let num = Int(chars) {
                        chapters.append(num)
                    }
                }
            }
        }
    }
    
    //    print("\(scripture)")
    //    print("\(chapters)")
    
    return chapters.count > 0 ? chapters : nil
}

func booksFromScriptureReference(_ scriptureReference:String?) -> [String]?
{
    guard let scriptureReference = scriptureReference else {
        return nil
    }

    var books = [String]()

    var string = scriptureReference
    
    //        print(string)
    
    var otBooks = [String]()
    
    for book in Constants.OLD_TESTAMENT_BOOKS {
        if let range = string.range(of: book) {
            otBooks.append(book)
            string = string.substring(to: range.lowerBound) + Constants.SINGLE_SPACE + string.substring(from: range.upperBound)
        }
    }
    
    for book in Constants.NEW_TESTAMENT_BOOKS.reversed() {
        if let range = string.range(of: book) {
            books.append(book)
            string = string.substring(to: range.lowerBound) + Constants.SINGLE_SPACE + string.substring(from: range.upperBound)
        }
    }
    
    let ntBooks = books.reversed()
    
    books = otBooks
    books.append(contentsOf: ntBooks)
    
    string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
    
    //        print(string)
    
    // Only works for "<book> - <book>"
    
    if (string == "-") {
        if books.count == 2 {
            let book1 = scriptureReference.range(of: books[0])
            let book2 = scriptureReference.range(of: books[1])
            let hyphen = scriptureReference.range(of: "-")
            
            if ((book1?.upperBound < hyphen?.lowerBound) && (hyphen?.upperBound < book2?.lowerBound)) ||
                ((book2?.upperBound < hyphen?.lowerBound) && (hyphen?.upperBound < book1?.lowerBound)) {
                //                print(first)
                //                print(last)
                
                books = [String]()
                
                let first = books[0]
                let last = books[1]
                
                if Constants.OLD_TESTAMENT_BOOKS.contains(first) && Constants.OLD_TESTAMENT_BOOKS.contains(last) {
                    if let firstIndex = Constants.OLD_TESTAMENT_BOOKS.index(of: first),
                        let lastIndex = Constants.OLD_TESTAMENT_BOOKS.index(of: last) {
                        for index in firstIndex...lastIndex {
                            books.append(Constants.OLD_TESTAMENT_BOOKS[index])
                        }
                    }
                }
                
                if Constants.OLD_TESTAMENT_BOOKS.contains(first) && Constants.NEW_TESTAMENT_BOOKS.contains(last) {
                    if let firstIndex = Constants.OLD_TESTAMENT_BOOKS.index(of: first) {
                        let lastIndex = Constants.OLD_TESTAMENT_BOOKS.count - 1
                        for index in firstIndex...lastIndex {
                            books.append(Constants.OLD_TESTAMENT_BOOKS[index])
                        }
                    }
                    let firstIndex = 0
                    if let lastIndex = Constants.NEW_TESTAMENT_BOOKS.index(of: last) {
                        for index in firstIndex...lastIndex {
                            books.append(Constants.NEW_TESTAMENT_BOOKS[index])
                        }
                    }
                }
                
                if Constants.NEW_TESTAMENT_BOOKS.contains(first) && Constants.NEW_TESTAMENT_BOOKS.contains(last) {
                    if let firstIndex = Constants.NEW_TESTAMENT_BOOKS.index(of: first),
                        let lastIndex = Constants.NEW_TESTAMENT_BOOKS.index(of: last) {
                        for index in firstIndex...lastIndex {
                            books.append(Constants.NEW_TESTAMENT_BOOKS[index])
                        }
                    }
                }
            }
        }
    }
    
//    print(books)
    
    return books.count > 0 ? books.sorted() { scriptureReference.range(of: $0)?.lowerBound < scriptureReference.range(of: $1)?.lowerBound } : nil // redundant
}

func multiPartMediaItems(_ mediaItem:MediaItem?) -> [MediaItem]?
{
    guard let mediaItem = mediaItem else {
        return nil
    }
    
    var multiPartMediaItems:[MediaItem]?
    
    if mediaItem.hasMultipleParts, let multiPartSort = mediaItem.multiPartSort {
        if (globals.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL] == nil) {
            let seriesMediaItems = globals.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                return mediaItem.hasMultipleParts ? (testMediaItem.multiPartName == mediaItem.multiPartName) : (testMediaItem.id == mediaItem.id)
            })
            multiPartMediaItems = sortMediaItemsByYear(seriesMediaItems, sorting: SORTING.CHRONOLOGICAL)
        } else {
            if let multiPartSort = mediaItem.multiPartSort {
                multiPartMediaItems = globals.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL]
            }
        }
    } else {
        multiPartMediaItems = [mediaItem]
    }

    return multiPartMediaItems
}

func mediaItemsInBook(_ mediaItems:[MediaItem]?,book:String?) -> [MediaItem]?
{
    guard let book = book else {
        return nil
    }
    
    return mediaItems?.filter({ (mediaItem:MediaItem) -> Bool in
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

func booksFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard (mediaItems != nil) else {
        return nil
    }
    
    var bookSet = Set<String>()
    
    for mediaItem in mediaItems! {
        if let books = mediaItem.books {
            for book in books {
                bookSet.insert(book)
            }
        }
    }
    
    return Array(bookSet).sorted(by: { (first:String, second:String) -> Bool in
                var result = false
        
                if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) != nil) {
                    if bookNumberInBible(first) == bookNumberInBible(second) {
                        result = first < second
                    } else {
                        result = bookNumberInBible(first) < bookNumberInBible(second)
                    }
                } else
                    if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) == nil) {
                        result = true
                    } else
                        if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) != nil) {
                            result = false
                        } else
                            if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) == nil) {
                                result = first < second
                }

                return result
            })
}

func bookSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard (mediaItems != nil) else {
        return nil
    }
    
    var bookSectionSet = Set<String>()
    
    for mediaItem in mediaItems! {
        for bookSection in mediaItem.bookSections {
            bookSectionSet.insert(bookSection)
        }
    }
    
    return Array(bookSectionSet).sorted(by: { (first:String, second:String) -> Bool in
                var result = false
                if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) != nil) {
                    if bookNumberInBible(first) == bookNumberInBible(second) {
                        result = first < second
                    } else {
                        result = bookNumberInBible(first) < bookNumberInBible(second)
                    }
                } else
                    if (bookNumberInBible(first) != nil) && (bookNumberInBible(second) == nil) {
                        result = true
                    } else
                        if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) != nil) {
                            result = false
                        } else
                            if (bookNumberInBible(first) == nil) && (bookNumberInBible(second) == nil) {
                                result = first < second
                }
                return result
            })
}

func seriesFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return Array(
            Set(
                mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
                    return mediaItem.hasMultipleParts
                }).map({ (mediaItem:MediaItem) -> String in
                    return mediaItem.multiPartName!
                })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
}

func seriesSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return Array(
            Set(
                mediaItems.map({ (mediaItem:MediaItem) -> String in
                    return mediaItem.multiPartSection!
                })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
}

func seriesSectionsFromMediaItems(_ mediaItems:[MediaItem]?,withTitles:Bool) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return Array(
            Set(
                mediaItems.map({ (mediaItem:MediaItem) -> String in
                    if (mediaItem.hasMultipleParts) {
                        return mediaItem.multiPartName!
                    } else {
                        return withTitles ? mediaItem.title! : Constants.Individual_Media
                    }
                })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return stringWithoutPrefixes(first) < stringWithoutPrefixes(second)
            })
}

func bookNumberInBible(_ book:String?) -> Int?
{
    guard let book = book else {
        return nil
    }

    if let index = Constants.OLD_TESTAMENT_BOOKS.index(of: book) {
        return index
    }
    
    if let index = Constants.NEW_TESTAMENT_BOOKS.index(of: book) {
        return Constants.OLD_TESTAMENT_BOOKS.count + index
    }
    
    return Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE // Not in the Bible.  E.g. Selected Scriptures
}

func tokenCountsFromString(_ string:String?) -> [(String,Int)]?
{
    var tokenCounts = [(String,Int)]()
    
    if let tokens = tokensFromString(string) {
        for token in tokens {
            var count = 0
            var string = string
            
            while let range = string?.range(of: token, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
                count += 1
                string = string?.substring(from: range.upperBound)
            }
            
            tokenCounts.append((token,count))
        }
    }
    
    return tokenCounts.count > 0 ? tokenCounts : nil
}

func tokensFromString(_ string:String?) -> [String]?
{
    guard let string = string else {
        return nil
    }
    
    var tokens = Set<String>()
    
    var str = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    
    if let range = str.range(of: Constants.PART_INDICATOR_SINGULAR) {
        str = str.substring(to: range.lowerBound)
    }
    
    //        print(name)
    //        print(string)
    
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
                    token = token.substring(to: range.lowerBound)
                }
            }
            
            if token != token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars)) {
                //                print("\(token)")
                token = token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars))
                //                print("\(token)")
            }
            
            if token != Constants.EMPTY_STRING {
                tokens.insert(token.uppercased())
                token = Constants.EMPTY_STRING
            }
        } else {
            token = Constants.EMPTY_STRING
        }
    }
    
    for char in str.characters {
        //        print(char)
        
        if UnicodeScalar(String(char)) != nil {
            if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: breakChars).contains(unicodeScalar) {
                //                print(token)
                processToken()
            } else {
                if let unicodeScalar = UnicodeScalar(String(char)), !CharacterSet(charactersIn: "$0123456789").contains(unicodeScalar) {
                    if !CharacterSet(charactersIn: trimChars).contains(unicodeScalar) || (token != Constants.EMPTY_STRING) {
                        // DO NOT WANT LEADING CHARS IN SET
                        //                        print(token)
                        token.append(char)
                        //                        print(token)
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

func tokensAndCountsFromString(_ string:String?) -> [String:Int]?
{
    guard let string = string else {
        return nil
    }
    
    var tokens = [String:Int]()
    
    var str = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    
    // TOKENIZING A TITLE RATHER THAN THE BODY, THIS MAY CAUSE PROBLEMS FOR BODY TEXT.
    if let range = str.range(of: Constants.PART_INDICATOR_SINGULAR) {
        str = str.substring(to: range.lowerBound)
    }
    
    //        print(name)
    //        print(string)
    
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
                    token = token.substring(to: range.lowerBound)
                }
            }
            
            if token != token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars)) {
//                print("\(token)")
                token = token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars))
//                print("\(token)")
            }
            
            if token != Constants.EMPTY_STRING {
//                print(token.uppercased())
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
    
    for char in str.characters {
        //        print(char)
        
        if UnicodeScalar(String(char)) != nil {
            if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: breakChars).contains(unicodeScalar) {
//                print(token)
                processToken()
            } else {
                if let unicodeScalar = UnicodeScalar(String(char)), !CharacterSet(charactersIn: "$0123456789").contains(unicodeScalar) {
                    if !CharacterSet(charactersIn: trimChars).contains(unicodeScalar) || (token != Constants.EMPTY_STRING) {
                        // DO NOT WANT LEADING CHARS IN SET
//                        print(token)
                        token.append(char)
//                        print(token)
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

func lastNameFromName(_ name:String?) -> String?
{
    if let firstName = firstNameFromName(name), let range = name?.range(of: firstName) {
        return name?.substring(from: range.upperBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    } else {
        return name
    }
}

func firstNameFromName(_ name:String?) -> String?
{
    guard let name = name else {
        return nil
    }

    var firstName:String?
    
    var string:String
    
    if let title = titleFromName(name) {
        string = name.substring(from: title.endIndex)
    } else {
        string = name
    }
    
    string = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    
    //        print(name)
    //        print(string)
    
    var newString = Constants.EMPTY_STRING
    
    for char in string.characters {
        if String(char) == Constants.SINGLE_SPACE {
            firstName = newString
            break
        }
        newString.append(char)
    }

    return firstName
}

func titleFromName(_ name:String?) -> String?
{
    guard let name = name else {
        return nil
    }
    
    var title = Constants.EMPTY_STRING
    
    if name.range(of: ". ") != nil {
        for char in name.characters {
            title.append(char)
            if String(char) == "." {
                break
            }
        }
    }
    
    return title != Constants.EMPTY_STRING ? title : nil
}

func classSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return Array(
            Set(mediaItems.map({ (mediaItem:MediaItem) -> String in
                return mediaItem.classSection!
            })
            )
            ).sorted()
}

func speakerSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return Array(
            Set(mediaItems.map({ (mediaItem:MediaItem) -> String in
                return mediaItem.speakerSection!
            })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
}

func speakersFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    return Array(
            Set(mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
                return mediaItem.hasSpeaker
            }).map({ (mediaItem:MediaItem) -> String in
                return mediaItem.speaker!
            })
            )
            ).sorted(by: { (first:String, second:String) -> Bool in
                return lastNameFromName(first) < lastNameFromName(second)
            })
}

func sortMediaItemsChronologically(_ mediaItems:[MediaItem]?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
        if let firstDate = $0.fullDate, let secondDate = $1.fullDate {
            if (firstDate.isEqualTo(secondDate)) {
                if ($0.service == $1.service) {
                    //                print($0)
                    //                print($1)
                    
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

func sortMediaItemsReverseChronologically(_ mediaItems:[MediaItem]?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
        if let firstDate = $0.fullDate, let secondDate = $1.fullDate {
            if (firstDate.isEqualTo(secondDate)) {
                if ($0.service == $1.service) {
    //                print($0)
    //                print($1)
                    
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

func sortMediaItemsByYear(_ mediaItems:[MediaItem]?,sorting:String?) -> [MediaItem]?
{
    guard let sorting = sorting else {
        return nil
    }
    
    var sortedMediaItems:[MediaItem]?

    switch sorting {
    case SORTING.CHRONOLOGICAL:
        sortedMediaItems = sortMediaItemsChronologically(mediaItems)
        break
        
    case SORTING.REVERSE_CHRONOLOGICAL:
        sortedMediaItems = sortMediaItemsReverseChronologically(mediaItems)
        break
        
    default:
        break
    }
    
    return sortedMediaItems
}

func compareMediaItemDates(first:MediaItem, second:MediaItem, sorting:String?) -> Bool
{
    guard let firstDate = first.fullDate else {
        return false
    }
    
    guard let secondDate = second.fullDate else {
        return true
    }
    
    guard let sorting = sorting else {
        return false
    }
    
    var result = false

    switch sorting {
    case SORTING.CHRONOLOGICAL:
        if (firstDate.isEqualTo(secondDate)) {
            result = (first.service < second.service)
        } else {
            result = firstDate.isOlderThan(secondDate)
        }
        break
    
    case SORTING.REVERSE_CHRONOLOGICAL:
        if (firstDate.isEqualTo(secondDate)) {
            result = (first.service > second.service)
        } else {
            result = firstDate.isNewerThan(secondDate)
        }
        break
        
    default:
        break
    }

    return result
}

func sortMediaItemsByMultiPart(_ mediaItems:[MediaItem]?,sorting:String?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
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

func sortMediaItemsByClass(_ mediaItems:[MediaItem]?,sorting: String?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
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

func sortMediaItemsBySpeaker(_ mediaItems:[MediaItem]?,sorting: String?) -> [MediaItem]?
{
    return mediaItems?.sorted() {
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

func testMediaItemsTagsAndSeries()
{
    print("Testing for mediaItem series and tags the same - start")
    
    if let mediaItems = globals.mediaRepository.list {
        for mediaItem in mediaItems {
            if (mediaItem.hasMultipleParts) && (mediaItem.hasTags) {
                if (mediaItem.multiPartName == mediaItem.tags) {
                    print("Multiple Part Name and Tags the same in: \(mediaItem.title!) Multiple Part Name:\(mediaItem.multiPartName!) Tags:\(mediaItem.tags!)")
                }
            }
        }
    }
    
    print("Testing for mediaItem series and tags the same - end")
}

func testMediaItemsForAudio()
{
    print("Testing for audio - start")
    
    for mediaItem in globals.mediaRepository.list! {
        if (!mediaItem.hasAudio) {
            print("Audio missing in: \(mediaItem.title!)")
        } else {

        }
    }
    
    print("Testing for audio - end")
}

func testMediaItemsForSpeaker()
{
    print("Testing for speaker - start")
    
    for mediaItem in globals.mediaRepository.list! {
        if (!mediaItem.hasSpeaker) {
            print("Speaker missing in: \(mediaItem.title!)")
        }
    }
    
    print("Testing for speaker - end")
}

func testMediaItemsForSeries()
{
    print("Testing for mediaItems with \"(Part \" in the title but no series - start")
    
    for mediaItem in globals.mediaRepository.list! {
        if (mediaItem.title?.range(of: "(Part ", options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) && mediaItem.hasMultipleParts {
            print("Series missing in: \(mediaItem.title!)")
        }
    }
    
    print("Testing for mediaItems with \"(Part \" in the title but no series - end")
}

func tagsSetFromTagsString(_ tagsString:String?) -> Set<String>?
{
    guard let tagsString = tagsString else {
        return nil
    }
    
    var tags = tagsString
    var setOfTags = Set<String>()
    
    while let range = tags.range(of: Constants.TAGS_SEPARATOR) {
        let tag = tags.substring(to: range.lowerBound)
        setOfTags.insert(tag)
        tags = tags.substring(from: range.upperBound)
    }
    
    if !tags.isEmpty {
        setOfTags.insert(tags)
    }
    
    return setOfTags.count > 0 ? setOfTags : nil
}

func tagsArrayToTagsString(_ tagsArray:[String]?) -> String?
{
    if tagsArray != nil {
        var tagString:String?
        
        for tag in tagsArray! {
            tagString = tagString != nil ? tagString! + Constants.TAGS_SEPARATOR + tag : tag
        }
        
        return tagString
    } else {
        return nil
    }
}

func tagsArrayFromTagsString(_ tagsString:String?) -> [String]?
{
    var arrayOfTags:[String]?
    
    if let tags = tagsSetFromTagsString(tagsString) {
        arrayOfTags = Array(tags) //.sort() { $0 < $1 } // .sort() { stringWithoutLeadingTheOrAOrAn($0) < stringWithoutLeadingTheOrAOrAn($1) } // Not sorted
    }
    
    return arrayOfTags
}

func mediaItemsWithTag(_ mediaItems:[MediaItem]?,tag:String?) -> [MediaItem]?
{
    guard let mediaItems = mediaItems else {
        return nil
    }
    
    guard let tag = tag else {
        return nil
    }

    return mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
            if let tagSet = mediaItem.tagsSet {
                return tagSet.contains(tag)
            } else {
                return false
            }
        })
}

func tagsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
{
    guard (mediaItems != nil) else {
        return nil
    }

    var tagsSet = Set<String>()
    
    for mediaItem in mediaItems! {
        if let tags = mediaItem.tagsSet {
            tagsSet.formUnion(tags)
        }
    }
    
    
    var tagsArray = Array(tagsSet).sorted(by: { stringWithoutPrefixes($0) < stringWithoutPrefixes($1) })
    
    tagsArray.append(Constants.All)
    
    //    print("Tag Set: \(tagsSet)")
    //    print("Tag Array: \(tagsArray)")
    
    return tagsArray.count > 0 ? tagsArray : nil
}

//func sort(method:String?,strings:[String]?) -> [String]?
//{
//    guard let strings = strings else {
//        return nil
//    }
//    
//    guard let method = method else {
//        return nil
//    }
//
//    switch method {
//    case Constants.Sort.Alphabetical:
//        return strings.sorted()
//        
//    case Constants.Sort.Frequency:
//        return strings.sorted(by: { (first:String, second:String) -> Bool in
//            if let rangeFirst = first.range(of: " ("), let rangeSecond = second.range(of: " (") {
//                let left = first.substring(from: rangeFirst.upperBound)
//                let right = second.substring(from: rangeSecond.upperBound)
//                
//                let first = first.substring(to: rangeFirst.lowerBound)
//                let second = second.substring(to: rangeSecond.lowerBound)
//                
//                if let rangeLeft = left.range(of: ")"), let rangeRight = right.range(of: ")") {
//                    let left = left.substring(to: rangeLeft.lowerBound)
//                    let right = right.substring(to: rangeRight.lowerBound)
//                    
//                    if let left = Int(left), let right = Int(right) {
//                        if left == right {
//                            return first < second
//                        } else {
//                            return left > right
//                        }
//                    }
//                }
//                
//                return false
//            } else {
//                return false
//            }
//        })
//        
//    default:
//        return nil
//    }
//}

func process(viewController:UIViewController,work:(()->(Any?))?,completion:((Any?)->())?)
{
    guard (work != nil)  && (completion != nil) else {
        return
    }
    
    
    guard let loadingViewController = viewController.storyboard?.instantiateViewController(withIdentifier: "Loading View Controller") else {
        return
    }
    
    // to share
    
    DispatchQueue.main.async(execute: { () -> Void in
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
        
        let view = viewController.view!

        let container = loadingViewController.view!
        
        container.frame = view.frame
        container.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        
        container.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        
        view.addSubview(container)
        
        DispatchQueue.global(qos: .background).async {
            let data = work?()
            
            DispatchQueue.main.async(execute: { () -> Void in

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
            })
        }
    })
}

func translateTestament(_ testament:String) -> String
{
    var translation = Constants.EMPTY_STRING
    
    switch testament {
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

func translate(_ string:String?) -> String?
{
    guard let string = string else {
        return nil
    }
    
    switch string {
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

func addressString() -> String
{
    let addressString:String = "\n\n\(Constants.CBC.LONG)\n\(Constants.CBC.STREET_ADDRESS)\n\(Constants.CBC.CITY_STATE_ZIPCODE_COUNTRY)\nPhone: \(Constants.CBC.PHONE_NUMBER)\nE-mail:\(Constants.CBC.EMAIL)\nWeb: \(Constants.CBC.WEBSITE)"
    
    return addressString
}

var alert:UIAlertController!

func networkUnavailable(_ message:String?)
{
    alert(title:Constants.Network_Error,message:message)
}

func alert(title:String?,message:String?)
{
    guard alert == nil else {
        return
    }

    guard UIApplication.shared.applicationState == UIApplicationState.active else {
        return
    }

    alert = UIAlertController(title:title,
                              message: message,
                              preferredStyle: UIAlertControllerStyle.alert)
    
    let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
        alert = nil
    })
    alert.addAction(action)
    
    DispatchQueue.main.async(execute: { () -> Void in
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    })
}

func userAlert(title:String?,message:String?)
{
    if (UIApplication.shared.applicationState == UIApplicationState.active) {
        
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
            
        })
        alert.addAction(action)
        
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        })
    }
}

