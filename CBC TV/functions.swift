
//  functions.swift
//  CBC
//
//  Created by Steve Leeke on 8/18/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit


func debug(_ string:String)
{
    //    print(string)
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

//func removeCacheFiles(fileExtension:String)
//{
//    // Clean up temp directory for cancelled downloads
//    let fileManager = FileManager.default
//    
//    guard let cachesURL = fileManager.cachesURL else {
//        return
//    }
//    
//    do {
//        let array = try fileManager.contentsOfDirectory(atPath: cachesURL.path)
//        print(array)
//        
//        for filename in array {
//            if let range = filename.range(of: "." + fileExtension) {
//                let id = String(filename[..<range.lowerBound])
//
//                if Globals.shared.mediaRepository.index?[id] != nil {
//                    let url = cachesURL.appendingPathComponent(filename)
//                    
//                    print(url.path)
//                    try fileManager.removeItem(atPath: url.path)
//                }
//            }
//        }
//    } catch let error as NSError {
//        NSLog(error.localizedDescription)
//        print("failed to remove temp files")
//    }
//}

//var documentsURL:URL?
//{
//    get {
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//    }
//}
//
//var cachesURL:URL?
//{
//    get {
//        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
//    }
//}

//func filesOfTypeInCache(_ fileType:String) -> [String]?
//{
//    guard let path = cachesURL?.path else {
//        return nil
//    }
//    
//    var files = [String]()
//    
//    let fileManager = FileManager.default
//    
//    do {
//        let array = try fileManager.contentsOfDirectory(atPath: path)
//        
//        for string in array {
//            if let range = string.range(of: fileType) {
//                if fileType == String(string[range.lowerBound...]) {
//                    files.append(string)
//                }
//            }
//        }
//    } catch let error as NSError {
//        NSLog(error.localizedDescription)
//        print("failed to get files in caches directory")
//    }
//    
//    return files.count > 0 ? files : nil
//}

//func removeJSONFromFileSystemDirectory()
//{
//    if let filename = Globals.shared.mediaCategory.filename, let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) {
//        do {
//            try FileManager.default.removeItem(atPath: jsonFileSystemURL.path)
//        } catch let error as NSError {
//            NSLog(error.localizedDescription)
//            print("failed to copy mediaItems.json")
//        }
//    }
//}

//func jsonToFileSystemDirectory(key:String)
//{
//    guard let jsonBundlePath = Bundle.main.path(forResource: key, ofType: Constants.JSON.TYPE) else {
//        return
//    }
//
//    let fileManager = FileManager.default
//
//    if let filename = Globals.shared.mediaCategory.filename, let jsonFileURL = cachesURL()?.appendingPathComponent(filename) {
//        // Check if file exist
//        if (!fileManager.fileExists(atPath: jsonFileURL.path)){
//            do {
//                // Copy File From Bundle To Documents Directory
//                try fileManager.copyItem(atPath: jsonBundlePath,toPath: jsonFileURL.path)
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//                print("failed to copy mediaItems.json")
//            }
//        } else {
//            //    fileManager.removeItemAtPath(destination)
//            // Which is newer, the bundle file or the file in the Documents folder?
//            do {
//                let jsonBundleAttributes = try fileManager.attributesOfItem(atPath: jsonBundlePath)
//
//                let jsonDocumentsAttributes = try fileManager.attributesOfItem(atPath: jsonFileURL.path)
//
//                if  let jsonBundleModDate = jsonBundleAttributes[FileAttributeKey.modificationDate] as? Date,
//                    let jsonDocumentsModDate = jsonDocumentsAttributes[FileAttributeKey.modificationDate] as? Date {
//                    if (jsonDocumentsModDate.isNewerThan(jsonBundleModDate)) {
//                        //Do nothing, the json in Documents is newer, i.e. it was downloaded after the install.
//                        print("JSON in Documents is newer than JSON in bundle")
//                    }
//
//                    if (jsonDocumentsModDate.isEqualTo(jsonBundleModDate)) {
//                        print("JSON in Documents is the same date as JSON in bundle")
//                        if  let jsonBundleFileSize = jsonBundleAttributes[FileAttributeKey.size] as? Int,
//                            let jsonDocumentsFileSize = jsonDocumentsAttributes[FileAttributeKey.size] as? Int {
//                            if (jsonBundleFileSize != jsonDocumentsFileSize) {
//                                print("Same dates different file sizes")
//                                //We have a problem.
//                            } else {
//                                print("Same dates same file sizes")
//                                //Do nothing, they are the same.
//                            }
//                        }
//                    }
//
//                    if (jsonBundleModDate.isNewerThan(jsonDocumentsModDate)) {
//                        print("JSON in bundle is newer than JSON in Documents")
//                        //copy the bundle into Documents directory
//                        do {
//                            // Copy File From Bundle To Documents Directory
//                            try fileManager.removeItem(atPath: jsonFileURL.path)
//                            try fileManager.copyItem(atPath: jsonBundlePath,toPath: jsonFileURL.path)
//                        } catch let error as NSError {
//                            NSLog(error.localizedDescription)
//                            print("failed to copy mediaItems.json")
//                        }
//                    }
//                }
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//                print("failed to get json file attributes")
//            }
//        }
//    }
//}

//func jsonFromURL(url:String) -> Any?
//{
//    guard Globals.shared.reachability.isReachable, let url = URL(string: url) else {
//        return nil
//    }
//
//    do {
//        let data = try Data(contentsOf: url)
//        print("able to read json from the URL.")
//
//        do {
//            let json = try JSONSerialization.jsonObject(with: data, options: [])
//
//            return json
//        } catch let error as NSError {
//            NSLog(error.localizedDescription)
//        }
//    } catch let error as NSError {
//        NSLog(error.localizedDescription)
//    }
//
//    return nil
//}

//func jsonFromURL(url:String,filename:String) -> Any?
//{
//    guard Globals.shared.reachability.isReachable, let url = URL(string: url) else {
//        return jsonFromFileSystem(filename: filename)
//    }
//
//    do {
//        let data = try Data(contentsOf: url)
//        print("able to read json from the URL.")
//
//        do {
//            let json = try JSONSerialization.jsonObject(with: data, options: [])
//
//            do {
//                if let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) {
//                    try data.write(to: jsonFileSystemURL)
//                }
//
//                print("able to write json to the file system")
//            } catch let error as NSError {
//                print("unable to write json to the file system.")
//
//                NSLog(error.localizedDescription)
//            }
//
//            print(json)
//            return json
//        } catch let error as NSError {
//            NSLog(error.localizedDescription)
//            return jsonFromFileSystem(filename: filename)
//        }
//    } catch let error as NSError {
//        NSLog(error.localizedDescription)
//        return jsonFromFileSystem(filename: filename)
//    }
//}

//func jsonFromFileSystem(filename:String?) -> Any?
//{
//    guard let filename = filename else {
//        return nil
//    }
//
//    guard let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) else {
//        return nil
//    }
//
//    do {
//        let data = try Data(contentsOf: jsonFileSystemURL)
//        print("able to read json from the URL.")
//
//        do {
//            let json = try JSONSerialization.jsonObject(with: data, options: [])
//            return json
//        } catch let error as NSError {
//            NSLog(error.localizedDescription)
//            return nil
//        }
//    } catch let error as NSError {
//        print("Network unavailable: json could not be read from the file system.")
//        NSLog(error.localizedDescription)
//        return nil
//    }
//}

//func jsonDataFromDocumentsDirectory() -> Any?
//{
//    jsonToFileSystemDirectory(key:Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES)
//
//    if let filename = Globals.shared.mediaCategory.filename, let jsonURL = cachesURL()?.appendingPathComponent(filename) {
//        if let data = try? Data(contentsOf: jsonURL) {
//            do {
//                let json = try JSONSerialization.jsonObject(with: data, options: [])
//                return json
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//                return nil
//            }
//        } else {
//            print("could not get data from the json file.")
//        }
//    }
//
//    return nil
//}

//func jsonDataFromCachesDirectory() -> Any?
//{
//    if let filename = Globals.shared.mediaCategory.filename, let jsonURL = cachesURL()?.appendingPathComponent(filename) {
//        if let data = try? Data(contentsOf: jsonURL) {
//            do {
//                let json = try JSONSerialization.jsonObject(with: data, options: [])
//                return json
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//                return nil
//            }
//        } else {
//            print("could not get data from the json file.")
//        }
//    }
//
//    return nil
//}

//func stringWithoutPrefixes(_ fromString:String?) -> String?
//{
//    guard let fromString = fromString else {
//        return nil
//    }
//    
//    return fromString.withoutPrefixes
//}

//func mediaItemSections(_ mediaItems:[MediaItem]?,sorting:String?,grouping:String?) -> [String]?
//{
//    guard let sorting = sorting, let grouping = grouping else {
//        return nil
//    }
//    
//    var strings:[String]?
//    
//    switch grouping {
//    case GROUPING.YEAR:
//        strings = yearsFromMediaItems(mediaItems, sorting: sorting)?.map() { (year) in
//            return "\(year)"
//        }
//        break
//        
//    case GROUPING.TITLE:
//        strings = seriesSectionsFromMediaItems(mediaItems,withTitles: true)
//        break
//        
//    case GROUPING.BOOK:
//        strings = bookSectionsFromMediaItems(mediaItems)
//        break
//        
//    case GROUPING.SPEAKER:
//        strings = speakerSectionsFromMediaItems(mediaItems)
//        break
//        
//    case GROUPING.CLASS:
//        strings = classSectionsFromMediaItems(mediaItems)
//        break
//        
//    default:
//        strings = nil
//        break
//    }
//    
//    return strings
//}
//
//
//func yearsFromMediaItems(_ mediaItems:[MediaItem]?, sorting: String?) -> [Int]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//    
//    guard let sorting = sorting else {
//        return nil
//    }
//    
//    return Array(
//            Set(
//                mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
//                    // We're assuming this gets ALL mediaItems.
//                    return mediaItem.fullDate != nil
//                }).map({ (mediaItem:MediaItem) -> Int in
//                    let calendar = Calendar.current
//                    if let fullDate = mediaItem.fullDate {
//                        let components = (calendar as NSCalendar).components(.year, from: fullDate)
//                        if let year = components.year {
//                            return year
//                        }
//                    }
//                    
//                    return -1
//                })
//            )
//            ).sorted(by: { (first:Int, second:Int) -> Bool in
//                switch sorting {
//                case SORTING.CHRONOLOGICAL:
//                    return first < second
//                    
//                case SORTING.REVERSE_CHRONOLOGICAL:
//                    return first > second
//                    
//                default:
//                    break
//                }
//                
//                return false
//            })
//}

//func testament(_ book:String) -> String
//{
//    if (Constants.OLD_TESTAMENT_BOOKS.contains(book)) {
//        return Constants.Old_Testament
//    } else
//        if (Constants.NEW_TESTAMENT_BOOKS.contains(book)) {
//            return Constants.New_Testament
//    }
//    
//    return Constants.EMPTY_STRING
//}
//
//func versesFromScripture(_ scripture:String?) -> [Int]?
//{
//    guard let scripture = scripture else {
//        return nil
//    }
//    
//    var verses = [Int]()
//
//    var string = scripture.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
//    
//    if string.isEmpty {
//        return []
//    }
//    
//    //Is not correct for books with only one chapter
//    // e.g. ["Philemon","Jude","2 John","3 John"]
//    guard let colon = string.range(of: ":") else {
//        return []
//    }
//    
//    string = String(string[colon.upperBound...])
//    
//    var chars = Constants.EMPTY_STRING
//    
//    var seenHyphen = false
//    var seenComma = false
//    
//    var startVerse = 0
//    var endVerse = 0
//    
//    var breakOut = false
//    
//    for character in string {
//        if breakOut {
//            break
//        }
//        switch character {
//        case "–":
//            fallthrough
//        case "-":
//            seenHyphen = true
//            if (startVerse == 0) {
//                if let num = Int(chars) {
//                    startVerse = num
//                }
//            }
//            chars = Constants.EMPTY_STRING
//            break
//            
//        case "(":
//            breakOut = true
//            break
//            
//        case ",":
//            seenComma = true
//            if let num = Int(chars) {
//                verses.append(num)
//            }
//            chars = Constants.EMPTY_STRING
//            break
//            
//        default:
//            chars.append(character)
//            //                print(chars)
//            break
//        }
//    }
//    if !seenHyphen {
//        if let num = Int(chars) {
//            startVerse = num
//        }
//    }
//    if (startVerse != 0) {
//        if (endVerse == 0) {
//            if let num = Int(chars) {
//                endVerse = num
//            }
//            chars = Constants.EMPTY_STRING
//        }
//        if (endVerse != 0) {
//            for verse in startVerse...endVerse {
//                verses.append(verse)
//            }
//        } else {
//            verses.append(startVerse)
//        }
//    }
//    if seenComma {
//        if let num = Int(chars) {
//            verses.append(num)
//        }
//    }
//    return verses.count > 0 ? verses : nil
//}

//func chaptersAndVersesForBook(_ book:String?) -> [Int:[Int]]?
//{
//    guard let book = book else {
//        return nil
//    }
//    
//    var chaptersAndVerses = [Int:[Int]]()
//    
//    var startChapter = 0
//    var endChapter = 0
//    var startVerse = 0
//    var endVerse = 0
//
//    startChapter = 1
//    
//    switch testament(book) {
//    case Constants.Old_Testament:
//        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
//            endChapter = Constants.OLD_TESTAMENT_CHAPTERS[index]
//        }
//        break
//        
//    case Constants.New_Testament:
//        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
//            endChapter = Constants.NEW_TESTAMENT_CHAPTERS[index]
//        }
//        break
//        
//    default:
//        break
//    }
//    
//    for chapter in startChapter...endChapter {
//        startVerse = 1
//        
//        switch testament(book) {
//        case Constants.Old_Testament:
//            if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
//                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
//            }
//            break
//            
//        case Constants.New_Testament:
//            if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
//                endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
//            }
//            break
//            
//        default:
//            break
//        }
//        
//        for verse in startVerse...endVerse {
//            if chaptersAndVerses[chapter] == nil {
//                chaptersAndVerses[chapter] = [verse]
//            } else {
//                chaptersAndVerses[chapter]?.append(verse)
//            }
//        }
//    }
//    
//    return chaptersAndVerses
//}
//
//func versesForBookChapter(_ book:String?,_ chapter:Int) -> [Int]?
//{
//    guard let book = book else {
//        return nil
//    }
// 
//    var verses = [Int]()
//    
//    let startVerse = 1
//    var endVerse = 0
//    
//    switch testament(book) {
//    case Constants.Old_Testament:
//        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
//            index < Constants.OLD_TESTAMENT_VERSES.count,
//            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
//            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
//        }
//        break
//    case Constants.New_Testament:
//        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
//            index < Constants.NEW_TESTAMENT_VERSES.count,
//            chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
//            endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
//        }
//        break
//    default:
//        break
//    }
//    
//    if startVerse == endVerse {
//        verses.append(startVerse)
//    } else {
//        if endVerse >= startVerse {
//            for verse in startVerse...endVerse {
//                verses.append(verse)
//            }
//        }
//    }
//    
//    return verses.count > 0 ? verses : nil
//}
//
//func chaptersAndVersesFromScripture(book:String?,reference:String?) -> [Int:[Int]]?
//{
//    // This can only comprehend a range of chapters or a range of verses from a single book.
//
//    guard let book = book else {
//        return nil
//    }
//    
//    guard (reference?.range(of: ".") == nil) else {
//        return nil
//    }
//    
//    guard (reference?.range(of: "&") == nil) else {
//        return nil
//    }
//    
//    guard let string = reference?.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING), !string.isEmpty else {
//        // Now we have a book w/ no chapter or verse references
//        // FILL in all chapters and all verses and return
//        
//        return chaptersAndVersesForBook(book)
//    }
//
//    var chaptersAndVerses = [Int:[Int]]()
//    
//    var tokens = [String]()
//    
//    var currentChapter = 0
//    var startChapter = 0
//    var endChapter = 0
//    var startVerse = 0
//    var endVerse = 0
//    
//    var token = Constants.EMPTY_STRING
//    
//    for char in string {
//        if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: ":,-").contains(unicodeScalar) {
//            tokens.append(token)
//            token = Constants.EMPTY_STRING
//            
//            tokens.append(String(char))
//        } else {
//            if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: "0123456789").contains(unicodeScalar) {
//                token.append(char)
//            }
//        }
//    }
//    
//    if token != Constants.EMPTY_STRING {
//        tokens.append(token)
//    }
//    
//    debug("Done w/ parsing and creating tokens")
//    
//    if tokens.count > 0 {
//        var startVerses = Constants.NO_CHAPTER_BOOKS.contains(book)
//        
//        if let first = tokens.first, let number = Int(first) {
//            tokens.remove(at: 0)
//            if Constants.NO_CHAPTER_BOOKS.contains(book) {
//                currentChapter = 1
//                startVerse = number
//            } else {
//                currentChapter = number
//                startChapter = number
//            }
//        } else {
//            return chaptersAndVersesForBook(book)
//        }
//        
//        repeat {
//            if let first = tokens.first {
//                tokens.remove(at: 0)
//                
//                switch first {
//                case ":":
//                    debug(": Verses follow")
//                    
//                    startVerses = true
//                    //                        startChapter = 0
//                    break
//                    
//                case ",":
//                    if !startVerses {
//                        debug(", Look for chapters")
//                        
//                        if let first = tokens.first, let number = Int(first) {
//                            tokens.remove(at: 0)
//
//                            if tokens.first == ":" {
//                                tokens.remove(at: 0)
//                                startChapter = number
//                                currentChapter = number
//                            } else {
//                                currentChapter = number
//                                chaptersAndVerses[currentChapter] = versesForBookChapter(book,currentChapter)
//                                
//                                if chaptersAndVerses[currentChapter] == nil {
//                                    print(book as Any,reference as Any)
//                                }
//                            }
//                        }
//                    } else {
//                        debug(", Look for verses")
//
//                        if startVerse > 0 {
//                            if chaptersAndVerses[currentChapter] == nil {
//                                chaptersAndVerses[currentChapter] = [Int]()
//                            }
//                            chaptersAndVerses[currentChapter]?.append(startVerse)
//                            
//                            startVerse = 0
//                        }
//
//                        if let first = tokens.first, let number = Int(first) {
//                            tokens.remove(at: 0)
//                            
//                            if let first = tokens.first {
//                                switch first {
//                                case ":":
//                                    tokens.remove(at: 0)
//                                    startVerses = true
//                                    
//                                    startChapter = number
//                                    currentChapter = number
//                                    break
//                                    
//                                case "-":
//                                    tokens.remove(at: 0)
//                                    if endVerse > 0, number < endVerse {
//                                        // This is a chapter!
//                                        startVerse = 0
//                                        endVerse = 0
//                                        
//                                        startChapter = number
//                                        
//                                        if let first = tokens.first, let number = Int(first) {
//                                            tokens.remove(at: 0)
//                                            endChapter = number
//
//                                            for chapter in startChapter...endChapter {
//                                                startVerse = 1
//                                                
//                                                switch testament(book) {
//                                                case Constants.Old_Testament:
//                                                    if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
//                                                        index < Constants.OLD_TESTAMENT_VERSES.count,
//                                                        chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
//                                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
//                                                    }
//                                                    break
//                                                case Constants.New_Testament:
//                                                    if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
//                                                        index < Constants.NEW_TESTAMENT_VERSES.count,
//                                                        chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
//                                                        endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
//                                                    }
//                                                    break
//                                                default:
//                                                    break
//                                                }
//                                                
//                                                if endVerse >= startVerse {
//                                                    if chaptersAndVerses[chapter] == nil {
//                                                        chaptersAndVerses[chapter] = [Int]()
//                                                    }
//                                                    if startVerse == endVerse {
//                                                        chaptersAndVerses[chapter]?.append(startVerse)
//                                                    } else {
//                                                        for verse in startVerse...endVerse {
//                                                            chaptersAndVerses[chapter]?.append(verse)
//                                                        }
//                                                    }
//                                                }
//                                            }
//
//                                            startChapter = 0
//                                        }
//                                    } else {
//                                        startVerse = number
//                                        if let first = tokens.first, let number = Int(first) {
//                                            tokens.remove(at: 0)
//                                            endVerse = number
//                                            if chaptersAndVerses[currentChapter] == nil {
//                                                chaptersAndVerses[currentChapter] = [Int]()
//                                            }
//                                            for verse in startVerse...endVerse {
//                                                chaptersAndVerses[currentChapter]?.append(verse)
//                                            }
//                                            startVerse = 0
//                                        }
//                                    }
//                                    break
//                                    
//                                default:
//                                    if chaptersAndVerses[currentChapter] == nil {
//                                        chaptersAndVerses[currentChapter] = [Int]()
//                                    }
//                                    chaptersAndVerses[currentChapter]?.append(number)
//                                    break
//                                }
//                            } else {
//                                if chaptersAndVerses[currentChapter] == nil {
//                                    chaptersAndVerses[currentChapter] = [Int]()
//                                }
//                                chaptersAndVerses[currentChapter]?.append(number)
//                            }
//                            
//                            if tokens.first == nil {
//                                startChapter = 0
//                            }
//                        }
//                    }
//                    break
//                    
//                case "-":
//                    if !startVerses {
//                        debug("- Look for chapters")
//                        
//                        if let first = tokens.first, let chapter = Int(first) {
//                            debug("Reference is split across chapters")
//                            tokens.remove(at: 0)
//                            endChapter = chapter
//                        }
//                        
//                        debug("See if endChapter has verses")
//                        
//                        if tokens.first == ":" {
//                            tokens.remove(at: 0)
//                            
//                            debug("First get the endVerse for the startChapter in the reference")
//                            
//                            startVerse = 1
//                            
//                            switch testament(book) {
//                            case Constants.Old_Testament:
//                                if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
//                                    index < Constants.OLD_TESTAMENT_VERSES.count,
//                                    startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
//                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
//                                }
//                                break
//                            case Constants.New_Testament:
//                                if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
//                                    index < Constants.NEW_TESTAMENT_VERSES.count,
//                                    startChapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
//                                    endVerse = Constants.NEW_TESTAMENT_VERSES[index][startChapter - 1]
//                                }
//                                break
//                            default:
//                                break
//                            }
//                            
//                            debug("Add the remaining verses for the startChapter")
//                            
//                            if chaptersAndVerses[startChapter] == nil {
//                                chaptersAndVerses[startChapter] = [Int]()
//                            }
//                            if startVerse == endVerse {
//                                chaptersAndVerses[startChapter]?.append(startVerse)
//                            } else {
//                                for verse in startVerse...endVerse {
//                                    chaptersAndVerses[startChapter]?.append(verse)
//                                }
//                            }
//                            
//                            debug("Done w/ startChapter")
//                            
//                            startVerse = 0
////                            endVerse = 0
//                            
//                            debug("Now determine whether there are any chapters between the first and the last in the reference")
//                            
//                            if (endChapter - startChapter) > 1 {
//                                let start = startChapter + 1
//                                let end = endChapter - 1
//                                
//                                debug("If there are, add those verses")
//                                
//                                for chapter in start...end {
//                                    startVerse = 1
//                                    
//                                    switch testament(book) {
//                                    case Constants.Old_Testament:
//                                        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
//                                            index < Constants.OLD_TESTAMENT_VERSES.count,
//                                            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
//                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
//                                        }
//                                        break
//                                    case Constants.New_Testament:
//                                        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
//                                            index < Constants.NEW_TESTAMENT_VERSES.count,
//                                            chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
//                                            endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
//                                        }
//                                        break
//                                    default:
//                                        break
//                                    }
//                                    
//                                    if endVerse >= startVerse {
//                                        if chaptersAndVerses[chapter] == nil {
//                                            chaptersAndVerses[chapter] = [Int]()
//                                        }
//                                        if startVerse == endVerse {
//                                            chaptersAndVerses[chapter]?.append(startVerse)
//                                        } else {
//                                            for verse in startVerse...endVerse {
//                                                chaptersAndVerses[chapter]?.append(verse)
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                            
//                            debug("Done w/ chapters between startChapter and endChapter")
//
//                            debug("Now add the verses from the endChapter")
//
//                            debug("First find the end verse")
//                            
//                            if let first = tokens.first, let number = Int(first) {
//                                tokens.remove(at: 0)
//                                
//                                startVerse = 1
//                                endVerse = number
//                                
//                                if endVerse >= startVerse {
//                                    if chaptersAndVerses[endChapter] == nil {
//                                        chaptersAndVerses[endChapter] = [Int]()
//                                    }
//                                    if startVerse == endVerse {
//                                        chaptersAndVerses[endChapter]?.append(startVerse)
//                                    } else {
//                                        for verse in startVerse...endVerse {
//                                            chaptersAndVerses[endChapter]?.append(verse)
//                                        }
//                                    }
//                                }
//                                
//                                debug("Done w/ verses")
//                                
//                                startVerse = 0
//                            }
//                            
//                            debug("Done w/ endChapter")
//                        } else {
//                            startVerse = 1
//                            
//                            switch testament(book) {
//                            case Constants.Old_Testament:
//                                if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
//                                    index < Constants.OLD_TESTAMENT_VERSES.count,
//                                    startChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
//                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][startChapter - 1]
//                                }
//                                break
//                            case Constants.New_Testament:
//                                if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
//                                    index < Constants.NEW_TESTAMENT_VERSES.count,
//                                    startChapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
//                                    endVerse = Constants.NEW_TESTAMENT_VERSES[index][startChapter - 1]
//                                }
//                                break
//                            default:
//                                break
//                            }
//                            
//                            debug("Add the verses for the startChapter")
//                            
//                            if chaptersAndVerses[startChapter] == nil {
//                                chaptersAndVerses[startChapter] = [Int]()
//                            }
//                            if startVerse == endVerse {
//                                chaptersAndVerses[startChapter]?.append(startVerse)
//                            } else {
//                                for verse in startVerse...endVerse {
//                                    chaptersAndVerses[startChapter]?.append(verse)
//                                }
//                            }
//                            
//                            debug("Done w/ startChapter")
//                            
//                            startVerse = 0
//                            
//                            debug("Now determine whether there are any chapters between the first and the last in the reference")
//                            
//                            if (endChapter - startChapter) > 1 {
//                                let start = startChapter + 1
//                                let end = endChapter - 1
//                                
//                                debug("If there are, add those verses")
//                                
//                                for chapter in start...end {
//                                    startVerse = 1
//                                    
//                                    switch testament(book) {
//                                    case Constants.Old_Testament:
//                                        if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
//                                            index < Constants.OLD_TESTAMENT_VERSES.count,
//                                            chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
//                                            endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
//                                        }
//                                        break
//                                    case Constants.New_Testament:
//                                        if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
//                                            index < Constants.NEW_TESTAMENT_VERSES.count,
//                                            chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
//                                                endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
//                                        }
//                                        break
//                                    default:
//                                        break
//                                    }
//                                    
//                                    if endVerse >= startVerse {
//                                        if chaptersAndVerses[chapter] == nil {
//                                            chaptersAndVerses[chapter] = [Int]()
//                                        }
//                                        if startVerse == endVerse {
//                                            chaptersAndVerses[chapter]?.append(startVerse)
//                                        } else {
//                                            for verse in startVerse...endVerse {
//                                                chaptersAndVerses[chapter]?.append(verse)
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                            
//                            debug("Done w/ chapters between startChapter and endChapter")
//                            
//                            debug("Now add the verses from the endChapter")
//                            
//                            startVerse = 1
//                            
//                            switch testament(book) {
//                            case Constants.Old_Testament:
//                                if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
//                                    index < Constants.OLD_TESTAMENT_VERSES.count,
//                                    endChapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
//                                    endVerse = Constants.OLD_TESTAMENT_VERSES[index][endChapter - 1]
//                                }
//                                break
//                            case Constants.New_Testament:
//                                if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
//                                    index < Constants.NEW_TESTAMENT_VERSES.count,
//                                    endChapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
//                                    endVerse = Constants.NEW_TESTAMENT_VERSES[index][endChapter - 1]
//                                }
//                                break
//                            default:
//                                break
//                            }
//                            
//                            if endVerse >= startVerse {
//                                if chaptersAndVerses[endChapter] == nil {
//                                    chaptersAndVerses[endChapter] = [Int]()
//                                }
//                                if startVerse == endVerse {
//                                    chaptersAndVerses[endChapter]?.append(startVerse)
//                                } else {
//                                    for verse in startVerse...endVerse {
//                                        chaptersAndVerses[endChapter]?.append(verse)
//                                    }
//                                }
//                            }
//                            
//                            debug("Done w/ verses")
//                            
//                            startVerse = 0
//                            
//                            debug("Done w/ endChapter")
//                        }
//                        
//                        debug("Done w/ chapters")
//                        
//                        startChapter = 0
//                        endChapter = 0
//                        
//                        currentChapter = 0
//                    } else {
//                        debug("- Look for verses")
//                        
//                        if let first = tokens.first,let number = Int(first) {
//                            tokens.remove(at: 0)
//                            
//                            debug("See if reference is split across chapters")
//                            
//                            if tokens.first == ":" {
//                                tokens.remove(at: 0)
//                                
//                                debug("Reference is split across chapters")
//                                debug("First get the endVerse for the first chapter in the reference")
//                                
//                                switch testament(book) {
//                                case Constants.Old_Testament:
//                                    if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
//                                        endVerse = Constants.OLD_TESTAMENT_VERSES[index][currentChapter - 1]
//                                    }
//                                    break
//                                case Constants.New_Testament:
//                                    if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
//                                        endVerse = Constants.NEW_TESTAMENT_VERSES[index][currentChapter - 1]
//                                    }
//                                    break
//                                default:
//                                    break
//                                }
//                                
//                                debug("Add the remaining verses for the first chapter")
//                                
//                                if chaptersAndVerses[currentChapter] == nil {
//                                    chaptersAndVerses[currentChapter] = [Int]()
//                                }
//                                if startVerse == endVerse {
//                                    chaptersAndVerses[currentChapter]?.append(startVerse)
//                                } else {
//                                    for verse in startVerse...endVerse {
//                                        chaptersAndVerses[currentChapter]?.append(verse)
//                                    }
//                                }
//                                
//                                debug("Done w/ verses")
//                                
//                                startVerse = 0
//                                
//                                debug("Now determine whehter there are any chapters between the first and the last in the reference")
//                                
//                                currentChapter = number
//                                endChapter = number
//                                
//                                if (endChapter - startChapter) > 1 {
//                                    let start = startChapter + 1
//                                    let end = endChapter - 1
//                                    
//                                    debug("If there are, add those verses")
//                                    
//                                    for chapter in start...end {
//                                        startVerse = 1
//                                        
//                                        switch testament(book) {
//                                        case Constants.Old_Testament:
//                                            if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book),
//                                                index < Constants.OLD_TESTAMENT_VERSES.count,
//                                                chapter <= Constants.OLD_TESTAMENT_VERSES[index].count {
//                                                endVerse = Constants.OLD_TESTAMENT_VERSES[index][chapter - 1]
//                                            }
//                                            break
//                                        case Constants.New_Testament:
//                                            if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book),
//                                                index < Constants.NEW_TESTAMENT_VERSES.count,
//                                                chapter <= Constants.NEW_TESTAMENT_VERSES[index].count {
//                                                endVerse = Constants.NEW_TESTAMENT_VERSES[index][chapter - 1]
//                                            }
//                                            break
//                                        default:
//                                            break
//                                        }
//
//                                        if endVerse >= startVerse {
//                                            if chaptersAndVerses[chapter] == nil {
//                                                chaptersAndVerses[chapter] = [Int]()
//                                            }
//                                            if startVerse == endVerse {
//                                                chaptersAndVerses[chapter]?.append(startVerse)
//                                            } else {
//                                                for verse in startVerse...endVerse {
//                                                    chaptersAndVerses[chapter]?.append(verse)
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                                
//                                debug("Now add the verses from the last chapter")
//                                debug("First find the end verse")
//                                
//                                if let first = tokens.first, let number = Int(first) {
//                                    tokens.remove(at: 0)
//                                    
//                                    startVerse = 1
//                                    endVerse = number
//                                    
//                                    if chaptersAndVerses[currentChapter] == nil {
//                                        chaptersAndVerses[currentChapter] = [Int]()
//                                    }
//                                    if startVerse == endVerse {
//                                        chaptersAndVerses[currentChapter]?.append(startVerse)
//                                    } else {
//                                        for verse in startVerse...endVerse {
//                                            chaptersAndVerses[currentChapter]?.append(verse)
//                                        }
//                                    }
//                                    
//                                    debug("Done w/ verses")
//                                    
//                                    startVerse = 0
//                                }
//                            } else {
//                                debug("reference is not split across chapters")
//                                
//                                endVerse = number
//                                
//                                debug("\(currentChapter) \(startVerse) \(endVerse)")
//                                
//                                if chaptersAndVerses[currentChapter] == nil {
//                                    chaptersAndVerses[currentChapter] = [Int]()
//                                }
//                                if startVerse == endVerse {
//                                    chaptersAndVerses[currentChapter]?.append(startVerse)
//                                } else {
//                                    for verse in startVerse...endVerse {
//                                        chaptersAndVerses[currentChapter]?.append(verse)
//                                    }
//                                }
//                                
//                                debug("Done w/ verses")
//                                
//                                startVerse = 0
//                            }
//                            
//                            debug("Done w/ chapters")
//                            
//                            startChapter = 0
//                            endChapter = 0
//                        }
//                    }
//                    break
//                    
//                default:
//                    debug("default")
//                    
//                    if let number = Int(first) {
//                        if let first = tokens.first {
//                            if first == ":" {
//                                debug("chapter")
//                                
//                                startVerses = true
//                                startChapter = number
//                                currentChapter = number
//                            } else {
//                                debug("chapter or verse")
//                                
//                                if startVerses {
//                                    debug("verse")
//                                    
//                                    startVerse = number
//                                }
//                            }
//                        } else {
//                            debug("no more tokens: chapter or verse")
//                            
//                            if startVerses {
//                                debug("verse")
//                                startVerse = number
//                            }
//                        }
//                    } else {
//                        // What happens in this case?
//                        // We ignore it.  This is not a number or one of the text strings we recognize.
//                    }
//                    break
//                }
//            }
//        } while tokens.first != nil
//        
//        debug("Done w/ processing tokens")
//        debug("If start and end (chapter,verse) remaining, process them")
//        
//        if startChapter > 0 {
//            if endChapter > 0 {
//                if endChapter >= startChapter {
//                    for chapter in startChapter...endChapter {
//                        chaptersAndVerses[chapter] = versesForBookChapter(book,chapter)
//                        
//                        if chaptersAndVerses[chapter] == nil {
//                            print(book as Any,reference as Any)
//                        }
//                    }
//                }
//            } else {
//                chaptersAndVerses[startChapter] = versesForBookChapter(book,startChapter)
//                
//                if chaptersAndVerses[startChapter] == nil {
//                    print(book as Any,reference as Any)
//                }
//            }
//            startChapter = 0
//            endChapter = 0
//        }
//        if startVerse > 0 {
//            if endVerse > 0 {
//                if chaptersAndVerses[currentChapter] == nil {
//                    chaptersAndVerses[currentChapter] = [Int]()
//                }
//                for verse in startVerse...endVerse {
//                    chaptersAndVerses[currentChapter]?.append(verse)
//                }
//            } else {
//                chaptersAndVerses[currentChapter] = [startVerse]
//            }
//            startVerse = 0
//            endVerse = 0
//        }
//    } else {
//        return chaptersAndVersesForBook(book)
//    }
//
//    return chaptersAndVerses.count > 0 ? chaptersAndVerses : nil
//}
//
//func chaptersFromScriptureReference(_ scriptureReference:String?) -> [Int]?
//{
//    // This can only comprehend a range of chapters or a range of verses from a single book.
//
//    guard let scriptureReference = scriptureReference else {
//        return nil
//    }
//    
//    var chapters = [Int]()
//    
//    var colonCount = 0
//    
//    let string = scriptureReference.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
//    
//    if (string == Constants.EMPTY_STRING) {
//        return nil
//    }
//    
//    let colon = string.range(of: ":")
//    let hyphen = string.range(of: "-")
//    let comma = string.range(of: ",")
//    
//    if (colon == nil) && (hyphen == nil) &&  (comma == nil) {
//        if let number = Int(string) {
//            chapters = [number]
//        }
//    } else {
//        var chars = Constants.EMPTY_STRING
//        
//        var seenColon = false
//        var seenHyphen = false
//        var seenComma = false
//        
//        var startChapter = 0
//        var endChapter = 0
//        
//        var breakOut = false
//        
//        for character in string {
//            if breakOut {
//                break
//            }
//            switch character {
//            case ":":
//                if !seenColon {
//                    seenColon = true
//                    if let num = Int(chars) {
//                        if (startChapter == 0) {
//                            startChapter = num
//                        } else {
//                            endChapter = num
//                        }
//                    }
//                } else {
//                    if (seenHyphen) {
//                        if let num = Int(chars) {
//                            endChapter = num
//                        }
//                    } else {
//                        //Error
//                    }
//                }
//                colonCount += 1
//                chars = Constants.EMPTY_STRING
//                break
//                
//            case "–":
//                fallthrough
//            case "-":
//                seenHyphen = true
//                if colonCount == 0 {
//                    // This is a chapter not a verse
//                    if (startChapter == 0) {
//                        if let num = Int(chars) {
//                            startChapter = num
//                        }
//                    }
//                }
//                chars = Constants.EMPTY_STRING
//                break
//                
//            case "(":
//                breakOut = true
//                break
//                
//            case ",":
//                seenComma = true
//                if !seenColon {
//                    // This is a chapter not a verse
//                    if let num = Int(chars) {
//                        chapters.append(num)
//                    }
//                    chars = Constants.EMPTY_STRING
//                } else {
//                    // Could be chapter or a verse
//                    chars = Constants.EMPTY_STRING
//                }
//                break
//                
//            default:
//                chars.append(character)
//                break
//            }
//        }
//        if (startChapter != 0) {
//            if (endChapter == 0) {
//                if (colonCount == 0) {
//                    if let num = Int(chars) {
//                        endChapter = num
//                    }
//                    chars = Constants.EMPTY_STRING
//                }
//            }
//            if (endChapter != 0) {
//                for chapter in startChapter...endChapter {
//                    chapters.append(chapter)
//                }
//            } else {
//                chapters.append(startChapter)
//            }
//        }
//        if seenComma {
//            if let num = Int(chars) {
//                if !seenColon {
//                    // This is a chapter not a verse
//                    chapters.append(num)
//                }
//            }
//        }
//    }
//    
//    return chapters.count > 0 ? chapters : nil
//}
//
//func booksFromScriptureReference(_ scriptureReference:String?) -> [String]?
//{
//    guard let scriptureReference = scriptureReference else {
//        return nil
//    }
//
//    var books = [String]()
//
//    var string = scriptureReference
//    
//    var otBooks = [String]()
//    
//    for book in Constants.OLD_TESTAMENT_BOOKS {
//        if let range = string.range(of: book) {
//            otBooks.append(book)
//            // .substring(to:
//            string = String(string[..<range.lowerBound]) + Constants.SINGLE_SPACE + String(string[range.upperBound...])
//        }
//    }
//    
//    for book in Constants.NEW_TESTAMENT_BOOKS.reversed() {
//        if let range = string.range(of: book) {
//            books.append(book)
//            // .substring(to:
//            string = String(string[..<range.lowerBound]) + Constants.SINGLE_SPACE + String(string[range.upperBound...])
//        }
//    }
//    
//    let ntBooks = books.reversed()
//    
//    books = otBooks
//    books.append(contentsOf: ntBooks)
//    
//    string = string.replacingOccurrences(of: Constants.SINGLE_SPACE, with: Constants.EMPTY_STRING)
//    
//    // Only works for "<book> - <book>"
//    
//    if (string == "-") {
//        if books.count == 2 {
//            let book1 = scriptureReference.range(of: books[0])
//            let book2 = scriptureReference.range(of: books[1])
//            let hyphen = scriptureReference.range(of: "-")
//            
//            if ((book1?.upperBound < hyphen?.lowerBound) && (hyphen?.upperBound < book2?.lowerBound)) ||
//                ((book2?.upperBound < hyphen?.lowerBound) && (hyphen?.upperBound < book1?.lowerBound)) {
//                books = [String]()
//                
//                let first = books[0]
//                let last = books[1]
//                
//                if Constants.OLD_TESTAMENT_BOOKS.contains(first) && Constants.OLD_TESTAMENT_BOOKS.contains(last) {
//                    if let firstIndex = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: first),
//                        let lastIndex = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: last) {
//                        for index in firstIndex...lastIndex {
//                            books.append(Constants.OLD_TESTAMENT_BOOKS[index])
//                        }
//                    }
//                }
//                
//                if Constants.OLD_TESTAMENT_BOOKS.contains(first) && Constants.NEW_TESTAMENT_BOOKS.contains(last) {
//                    if let firstIndex = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: first) {
//                        let lastIndex = Constants.OLD_TESTAMENT_BOOKS.count - 1
//                        for index in firstIndex...lastIndex {
//                            books.append(Constants.OLD_TESTAMENT_BOOKS[index])
//                        }
//                    }
//                    let firstIndex = 0
//                    if let lastIndex = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: last) {
//                        for index in firstIndex...lastIndex {
//                            books.append(Constants.NEW_TESTAMENT_BOOKS[index])
//                        }
//                    }
//                }
//                
//                if Constants.NEW_TESTAMENT_BOOKS.contains(first) && Constants.NEW_TESTAMENT_BOOKS.contains(last) {
//                    if let firstIndex = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: first),
//                        let lastIndex = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: last) {
//                        for index in firstIndex...lastIndex {
//                            books.append(Constants.NEW_TESTAMENT_BOOKS[index])
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    return books.count > 0 ? books.sorted() { scriptureReference.range(of: $0)?.lowerBound < scriptureReference.range(of: $1)?.lowerBound } : nil // redundant
//}

//func multiPartMediaItems(_ mediaItem:MediaItem?) -> [MediaItem]?
//{
//    guard let mediaItem = mediaItem else {
//        return nil
//    }
//    
//    var multiPartMediaItems:[MediaItem]?
//    
//    if mediaItem.hasMultipleParts, let multiPartSort = mediaItem.multiPartSort {
//        if (Globals.shared.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL] == nil) {
//            let seriesMediaItems = Globals.shared.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
//                return mediaItem.hasMultipleParts ? (testMediaItem.multiPartName == mediaItem.multiPartName) : (testMediaItem.id == mediaItem.id)
//            })
//            multiPartMediaItems = sortMediaItemsByYear(seriesMediaItems, sorting: SORTING.CHRONOLOGICAL)
//        } else {
//            if let multiPartSort = mediaItem.multiPartSort {
//                multiPartMediaItems = Globals.shared.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL]
//            }
//        }
//    } else {
//        multiPartMediaItems = [mediaItem]
//    }
//
//    return multiPartMediaItems
//}
//
//func mediaItemsInBook(_ mediaItems:[MediaItem]?,book:String?) -> [MediaItem]?
//{
//    guard let book = book else {
//        return nil
//    }
//    
//    return mediaItems?.filter({ (mediaItem:MediaItem) -> Bool in
//        if let books = mediaItem.books {
//            return books.contains(book)
//        } else {
//            return false
//        }
//    }).sorted(by: { (first:MediaItem, second:MediaItem) -> Bool in
//        if let firstDate = first.fullDate, let secondDate = second.fullDate {
//            if (firstDate.isEqualTo(secondDate)) {
//                return first.service < second.service
//            } else {
//                return firstDate.isOlderThan(secondDate)
//            }
//        } else {
//            return false
//        }
//    })
//}
//
//func booksFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//    
//    var bookSet = Set<String>()
//    
//    for mediaItem in mediaItems {
//        if let books = mediaItem.books {
//            for book in books {
//                bookSet.insert(book)
//            }
//        }
//    }
//    
//    return Array(bookSet).sorted(by: { (first:String, second:String) -> Bool in
//                var result = false
//        
//                if (first.bookNumberInBible != nil) && (second.bookNumberInBible != nil) {
//                    if first.bookNumberInBible == second.bookNumberInBible {
//                        result = first < second
//                    } else {
//                        result = first.bookNumberInBible < second.bookNumberInBible
//                    }
//                } else
//                    if (first.bookNumberInBible != nil) && (second.bookNumberInBible == nil) {
//                        result = true
//                    } else
//                        if (first.bookNumberInBible == nil) && (second.bookNumberInBible != nil) {
//                            result = false
//                        } else
//                            if (first.bookNumberInBible == nil) && (second.bookNumberInBible == nil) {
//                                result = first < second
//                }
//
//                return result
//            })
//}
//
//func bookSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//    
//    var bookSectionSet = Set<String>()
//    
//    for mediaItem in mediaItems {
//        for bookSection in mediaItem.bookSections {
//            bookSectionSet.insert(bookSection)
//        }
//    }
//    
//    return Array(bookSectionSet).sorted(by: { (first:String, second:String) -> Bool in
//                var result = false
//                if (first.bookNumberInBible != nil) && (second.bookNumberInBible != nil) {
//                    if first.bookNumberInBible == second.bookNumberInBible {
//                        result = first < second
//                    } else {
//                        result = first.bookNumberInBible < second.bookNumberInBible
//                    }
//                } else
//                    if (first.bookNumberInBible != nil) && (second.bookNumberInBible == nil) {
//                        result = true
//                    } else
//                        if (first.bookNumberInBible == nil) && (second.bookNumberInBible != nil) {
//                            result = false
//                        } else
//                            if (first.bookNumberInBible == nil) && (second.bookNumberInBible == nil) {
//                                result = first < second
//                }
//                return result
//            })
//}
//
//func seriesFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//    
//    return Array(
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
//}
//
//func seriesSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//    
//    return Array(
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
//}
//
//func seriesSectionsFromMediaItems(_ mediaItems:[MediaItem]?,withTitles:Bool) -> [String]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//    
//    return Array(
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
//}

//func bookNumberInBible(_ book:String?) -> Int?
//{
//    guard let book = book else {
//        return nil
//    }
//
//    if let index = Constants.OLD_TESTAMENT_BOOKS.firstIndex(of: book) {
//        return index
//    }
//    
//    if let index = Constants.NEW_TESTAMENT_BOOKS.firstIndex(of: book) {
//        return Constants.OLD_TESTAMENT_BOOKS.count + index
//    }
//    
//    return Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE // Not in the Bible.  E.g. Selected Scriptures
//}

//func tokenCountsFromString(_ string:String?) -> [(String,Int)]?
//{
//    guard string != nil else {
//        return nil
//    }
//    
//    var tokenCounts = [(String,Int)]()
//    
//    if let tokens = tokensFromString(string) {
//        for token in tokens {
//            var count = 0
//            guard var string = string else {
//                continue
//            }
//            
//            while let range = string.range(of: token, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
//                count += 1
//                string = String(string[range.upperBound...])
//            }
//            
//            tokenCounts.append((token,count))
//        }
//    }
//    
//    return tokenCounts.count > 0 ? tokenCounts : nil
//}
//
//func tokensFromString(_ string:String?) -> [String]?
//{
//    guard let string = string else {
//        return nil
//    }
//    
//    var tokens = Set<String>()
//    
//    var str = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//    
//    if let range = str.range(of: Constants.PART_INDICATOR_SINGULAR) {
//        // .substring(to:
//        str = String(str[..<range.lowerBound])
//    }
//    
//    var token = Constants.EMPTY_STRING
//    let trimChars = Constants.UNBREAKABLE_SPACE + Constants.QUOTES + " '" // ‘”
//    let breakChars = "\" :-!;,.()?&/<>[]" + Constants.UNBREAKABLE_SPACE + Constants.DOUBLE_QUOTES // ‘“
//
//    func processToken()
//    {
//        if (token.endIndex > "XX".endIndex) {
//            // "Q", "A", "I", "at", "or", "to", "of", "in", "on",  "be", "is", "vs", "us", "An"
//            for word in ["are", "can", "And", "The", "for"] {
//                if token.lowercased() == word.lowercased() {
//                    token = Constants.EMPTY_STRING
//                    break
//                }
//            }
//            
//            if let range = token.lowercased().range(of: "i'"), range.lowerBound == token.startIndex {
//                token = Constants.EMPTY_STRING
//            }
//            
//            if token.lowercased() != "it's" {
//                if let range = token.lowercased().range(of: "'s") {
//                    // .substring(to: 
//                    token = String(token[..<range.lowerBound])
//                }
//            }
//            
//            if token != token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars)) {
//                token = token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars))
//            }
//            
//            if token != Constants.EMPTY_STRING {
//                tokens.insert(token.uppercased())
//                token = Constants.EMPTY_STRING
//            }
//        } else {
//            token = Constants.EMPTY_STRING
//        }
//    }
//    
//    for char in str {
//        if UnicodeScalar(String(char)) != nil {
//            if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: breakChars).contains(unicodeScalar) {
//                processToken()
//            } else {
//                if let unicodeScalar = UnicodeScalar(String(char)), !CharacterSet(charactersIn: "$0123456789").contains(unicodeScalar) {
//                    if !CharacterSet(charactersIn: trimChars).contains(unicodeScalar) || (token != Constants.EMPTY_STRING) {
//                        // DO NOT WANT LEADING CHARS IN SET
//                        token.append(char)
//                    }
//                }
//            }
//        }
//    }
//    
//    if !token.isEmpty {
//        processToken()
//    }
//    
//    return Array(tokens).sorted() {
//        $0.lowercased() < $1.lowercased()
//    }
//}
//
//func tokensAndCountsFromString(_ string:String?) -> [String:Int]?
//{
//    guard let string = string else {
//        return nil
//    }
//    
//    var tokens = [String:Int]()
//    
//    var str = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//    
//    // TOKENIZING A TITLE RATHER THAN THE BODY, THIS MAY CAUSE PROBLEMS FOR BODY TEXT.
//    if let range = str.range(of: Constants.PART_INDICATOR_SINGULAR) {
//        // .substring(to:
//        str = String(str[..<range.lowerBound])
//    }
//    
//    var token = Constants.EMPTY_STRING
//    let trimChars = Constants.UNBREAKABLE_SPACE + Constants.QUOTES + " '" // ‘”
//    let breakChars = "\" :-!;,.()?&/<>[]" + Constants.UNBREAKABLE_SPACE + Constants.DOUBLE_QUOTES // ‘“
//    
//    func processToken()
//    {
//        if (token.endIndex > "XX".endIndex) {
//            // "Q", "A", "I", "at", "or", "to", "of", "in", "on",  "be", "is", "vs", "us", "An"
//            for word in ["are", "can", "And", "The", "for"] {
//                if token.lowercased() == word.lowercased() {
//                    token = Constants.EMPTY_STRING
//                    break
//                }
//            }
//            
//            if let range = token.lowercased().range(of: "i'"), range.lowerBound == token.startIndex {
//                token = Constants.EMPTY_STRING
//            }
//            
//            if token.lowercased() != "it's" {
//                if let range = token.lowercased().range(of: "'s") {
//                    // .substring(to:
//                    token = String(token[..<range.lowerBound])
//                }
//            }
//            
//            if token != token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars)) {
//                token = token.trimmingCharacters(in: CharacterSet(charactersIn: trimChars))
//            }
//            
//            if token != Constants.EMPTY_STRING {
//                if let count = tokens[token.uppercased()] {
//                    tokens[token.uppercased()] = count + 1
//                } else {
//                    tokens[token.uppercased()] = 1
//                }
//                token = Constants.EMPTY_STRING
//            }
//        } else {
//            token = Constants.EMPTY_STRING
//        }
//    }
//    
//    for char in str {
//        if UnicodeScalar(String(char)) != nil {
//            if let unicodeScalar = UnicodeScalar(String(char)), CharacterSet(charactersIn: breakChars).contains(unicodeScalar) {
//                processToken()
//            } else {
//                if let unicodeScalar = UnicodeScalar(String(char)), !CharacterSet(charactersIn: "$0123456789").contains(unicodeScalar) {
//                    if !CharacterSet(charactersIn: trimChars).contains(unicodeScalar) || (token != Constants.EMPTY_STRING) {
//                        // DO NOT WANT LEADING CHARS IN SET
//                        token.append(char)
//                    }
//                }
//            }
//        }
//    }
//    
//    if !token.isEmpty {
//        processToken()
//    }
//    
//    return tokens.count > 0 ? tokens : nil
//}
//
//func lastNameFromName(_ name:String?) -> String?
//{
//    guard let name = name else {
//        return nil
//    }
//
//    if let firstName = firstNameFromName(name), let range = name.range(of: firstName) {
//        return String(name[range.upperBound...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//    } else {
//        return name
//    }
//}
//
//func firstNameFromName(_ name:String?) -> String?
//{
//    guard let name = name else {
//        return nil
//    }
//
//    var firstName:String?
//    
//    var string:String
//    
//    if let title = titleFromName(name) {
//        string = String(name[title.endIndex...])
//    } else {
//        string = name
//    }
//    
//    string = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//    
//    var newString = Constants.EMPTY_STRING
//    
//    for char in string {
//        if String(char) == Constants.SINGLE_SPACE {
//            firstName = newString
//            break
//        }
//        newString.append(char)
//    }
//
//    return firstName
//}
//
//func titleFromName(_ name:String?) -> String?
//{
//    guard let name = name else {
//        return nil
//    }
//    
//    var title = Constants.EMPTY_STRING
//    
//    if name.range(of: ". ") != nil {
//        for char in name {
//            title.append(char)
//            if String(char) == "." {
//                break
//            }
//        }
//    }
//    
//    return title != Constants.EMPTY_STRING ? title : nil
//}

//func classSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//    
//    return Array(
//            Set(mediaItems.map({ (mediaItem:MediaItem) -> String in
//                return mediaItem.classSection ?? "CLASS SECTION"
//            })
//            )
//            ).sorted()
//}
//
//func speakerSectionsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//    
//    return Array(
//            Set(mediaItems.map({ (mediaItem:MediaItem) -> String in
//                return mediaItem.speakerSection ?? "SPEAKER SECTION"
//            })
//            )
//            ).sorted(by: { (first:String, second:String) -> Bool in
//                return lastNameFromName(first) < lastNameFromName(second)
//            })
//}
//
//func speakersFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//    
//    return Array(
//            Set(mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
//                return mediaItem.hasSpeaker
//            }).map({ (mediaItem:MediaItem) -> String in
//                return mediaItem.speaker ?? "SPEAKER"
//            })
//            )
//            ).sorted(by: { (first:String, second:String) -> Bool in
//                return lastNameFromName(first) < lastNameFromName(second)
//            })
//}
//
//func sortMediaItemsChronologically(_ mediaItems:[MediaItem]?) -> [MediaItem]?
//{
//    return mediaItems?.sorted() {
//        if let firstDate = $0.fullDate, let secondDate = $1.fullDate {
//            if (firstDate.isEqualTo(secondDate)) {
//                if ($0.service == $1.service) {
//                    return $0.id < $1.id
//                } else {
//                    return $0.service < $1.service
//                }
//            } else {
//                return firstDate.isOlderThan(secondDate)
//            }
//        } else {
//            return false
//        }
//    }
//}
//
//func sortMediaItemsReverseChronologically(_ mediaItems:[MediaItem]?) -> [MediaItem]?
//{
//    return mediaItems?.sorted() {
//        if let firstDate = $0.fullDate, let secondDate = $1.fullDate {
//            if (firstDate.isEqualTo(secondDate)) {
//                if ($0.service == $1.service) {
//                    return $0.id > $1.id
//                } else {
//                    return $0.service > $1.service
//                }
//            } else {
//                return firstDate.isNewerThan(secondDate)
//            }
//        } else {
//            return false
//        }
//    }
//}
//
//func sortMediaItemsByYear(_ mediaItems:[MediaItem]?,sorting:String?) -> [MediaItem]?
//{
//    guard let sorting = sorting else {
//        return nil
//    }
//    
//    var sortedMediaItems:[MediaItem]?
//
//    switch sorting {
//    case SORTING.CHRONOLOGICAL:
//        sortedMediaItems = sortMediaItemsChronologically(mediaItems)
//        break
//        
//    case SORTING.REVERSE_CHRONOLOGICAL:
//        sortedMediaItems = sortMediaItemsReverseChronologically(mediaItems)
//        break
//        
//    default:
//        break
//    }
//    
//    return sortedMediaItems
//}

//func sortMediaItemsByMultiPart(_ mediaItems:[MediaItem]?,sorting:String?) -> [MediaItem]?
//{
//    return mediaItems?.sorted() {
//        var result = false
//        
//        let first = $0
//        let second = $1
//        
//        if (first.multiPartSectionSort != second.multiPartSectionSort) {
//            result = first.multiPartSectionSort < second.multiPartSectionSort
//        } else {
//            result = compareMediaItemDates(first: first,second: second, sorting: sorting)
//        }
//
//        return result
//    }
//}
//
//func sortMediaItemsByClass(_ mediaItems:[MediaItem]?,sorting: String?) -> [MediaItem]?
//{
//    return mediaItems?.sorted() {
//        var result = false
//        
//        let first = $0
//        let second = $1
//        
//        if (first.classSectionSort != second.classSectionSort) {
//            result = first.classSectionSort < second.classSectionSort
//        } else {
//            result = compareMediaItemDates(first: first,second: second, sorting: sorting)
//        }
//        
//        return result
//    }
//}
//
//func sortMediaItemsBySpeaker(_ mediaItems:[MediaItem]?,sorting: String?) -> [MediaItem]?
//{
//    return mediaItems?.sorted() {
//        var result = false
//        
//        let first = $0
//        let second = $1
//        
//        if (first.speakerSectionSort != second.speakerSectionSort) {
//            result = first.speakerSectionSort < second.speakerSectionSort
//        } else {
//            result = compareMediaItemDates(first: first,second: second, sorting: sorting)
//        }
//        
//        return result
//    }
//}

//func testMediaItemsTagsAndSeries()
//{
//    print("Testing for mediaItem series and tags the same - start")
//    
//    if let mediaItems = Globals.shared.mediaRepository.list {
//        for mediaItem in mediaItems {
//            if (mediaItem.hasMultipleParts) && (mediaItem.hasTags) {
//                if (mediaItem.multiPartName == mediaItem.tags) {
//                    print("Multiple Part Name and Tags the same in: \(mediaItem.title!) Multiple Part Name:\(mediaItem.multiPartName!) Tags:\(mediaItem.tags!)")
//                }
//            }
//        }
//    }
//    
//    print("Testing for mediaItem series and tags the same - end")
//}
//
//func testMediaItemsForAudio()
//{
//    print("Testing for audio - start")
//    
//    for mediaItem in Globals.shared.mediaRepository.list! {
//        if (!mediaItem.hasAudio) {
//            print("Audio missing in: \(mediaItem.title!)")
//        } else {
//
//        }
//    }
//    
//    print("Testing for audio - end")
//}
//
//func testMediaItemsForSpeaker()
//{
//    print("Testing for speaker - start")
//    
//    for mediaItem in Globals.shared.mediaRepository.list! {
//        if (!mediaItem.hasSpeaker) {
//            print("Speaker missing in: \(mediaItem.title!)")
//        }
//    }
//    
//    print("Testing for speaker - end")
//}
//
//func testMediaItemsForSeries()
//{
//    print("Testing for mediaItems with \"(Part \" in the title but no series - start")
//    
//    for mediaItem in Globals.shared.mediaRepository.list! {
//        if (mediaItem.title?.range(of: "(Part ", options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) && mediaItem.hasMultipleParts {
//            print("Series missing in: \(mediaItem.title!)")
//        }
//    }
//    
//    print("Testing for mediaItems with \"(Part \" in the title but no series - end")
//}

//func tagsSetFromTagsString(_ tagsString:String?) -> Set<String>?
//{
//    guard let tagsString = tagsString else {
//        return nil
//    }
//    
//    var tags = tagsString
//    var setOfTags = Set<String>()
//    
//    while let range = tags.range(of: Constants.TAGS_SEPARATOR) {
//        // .substring(to:
//        let tag = String(tags[..<range.lowerBound])
//        setOfTags.insert(tag)
//        tags = String(tags[range.upperBound...])
//    }
//    
//    if !tags.isEmpty {
//        setOfTags.insert(tags)
//    }
//    
//    return setOfTags.count > 0 ? setOfTags : nil
//}
//
//func tagsArrayToTagsString(_ tagsArray:[String]?) -> String?
//{
//    guard let tagsArray = tagsArray else {
//        return nil
//    }
//    
//    var tagString:String?
//    
//    for tag in tagsArray {
//        tagString = (tagString != nil ? tagString! + Constants.TAGS_SEPARATOR : "") + tag
//    }
//    
//    return tagString
//}
//
//func tagsArrayFromTagsString(_ tagsString:String?) -> [String]?
//{
//    var arrayOfTags:[String]?
//    
//    if let tags = tagsSetFromTagsString(tagsString) {
//        arrayOfTags = Array(tags)
//    }
//    
//    return arrayOfTags
//}

//func mediaItemsWithTag(_ mediaItems:[MediaItem]?,tag:String?) -> [MediaItem]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//    
//    guard let tag = tag else {
//        return nil
//    }
//
//    return mediaItems.filter({ (mediaItem:MediaItem) -> Bool in
//            if let tagSet = mediaItem.tagsSet {
//                return tagSet.contains(tag)
//            } else {
//                return false
//            }
//        })
//}
//
//func tagsFromMediaItems(_ mediaItems:[MediaItem]?) -> [String]?
//{
//    guard let mediaItems = mediaItems else {
//        return nil
//    }
//
//    var tagsSet = Set<String>()
//    
//    for mediaItem in mediaItems {
//        if let tags = mediaItem.tagsSet {
//            tagsSet.formUnion(tags)
//        }
//    }
//    
//    
//    var tagsArray = Array(tagsSet).sorted(by: { $0.withoutPrefixes < $1.withoutPrefixes })
//    
//    tagsArray.append(Constants.All)
//    
//    return tagsArray.count > 0 ? tagsArray : nil
//}

//func process(viewController:UIViewController,work:(()->(Any?))?,completion:((Any?)->())?)
//{
//    guard let view = viewController.view else {
//        return
//    }
//    
//    guard (work != nil)  && (completion != nil) else {
//        return
//    }
//    
//    guard let loadingViewController = viewController.storyboard?.instantiateViewController(withIdentifier: "Loading View Controller") else {
//        return
//    }
//
//    guard let container = loadingViewController.view else {
//        return
//    }
//    
//    Thread.onMainThread { () -> (Void) in
//        if let buttons = viewController.navigationItem.rightBarButtonItems {
//            for button in buttons {
//                button.isEnabled = false
//            }
//        }
//        
//        if let buttons = viewController.navigationItem.leftBarButtonItems {
//            for button in buttons {
//                button.isEnabled = false
//            }
//        }
//        
//        container.frame = view.frame
//        container.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
//        
//        container.backgroundColor = UIColor.white.withAlphaComponent(0.5)
//        
//        view.addSubview(container)
//        
//        DispatchQueue.global(qos: .background).async {
//            let data = work?()
//            
//            Thread.onMainThread { () -> (Void) in
//                if container != viewController.view {
//                    container.removeFromSuperview()
//                }
//                
//                if let buttons = viewController.navigationItem.rightBarButtonItems {
//                    for button in buttons {
//                        button.isEnabled = true
//                    }
//                }
//                
//                if let buttons = viewController.navigationItem.leftBarButtonItems {
//                    for button in buttons {
//                        button.isEnabled = true
//                    }
//                }
//                
//                completion?(data)
//            }
//        }
//    }
//}

//func translateTestament(_ testament:String) -> String
//{
//    var translation = Constants.EMPTY_STRING
//    
//    switch testament {
//    case Constants.OT:
//        translation = Constants.Old_Testament
//        break
//        
//    case Constants.NT:
//        translation = Constants.New_Testament
//        break
//        
//    default:
//        break
//    }
//    
//    return translation
//}
//
//func translate(_ string:String?) -> String?
//{
//    guard let string = string else {
//        return nil
//    }
//    
//    switch string {
//    case SORTING.CHRONOLOGICAL:
//        return Sorting.Oldest_to_Newest
//        
//    case SORTING.REVERSE_CHRONOLOGICAL:
//        return Sorting.Newest_to_Oldest
//
//    case GROUPING.YEAR:
//        return Grouping.Year
//        
//    case GROUPING.TITLE:
//        return Grouping.Title
//        
//    case GROUPING.BOOK:
//        return Grouping.Book
//        
//    case GROUPING.SPEAKER:
//        return Grouping.Speaker
//        
//    case GROUPING.CLASS:
//        return Grouping.Class
//        
//    default:
//        return nil
//    }
//}

//func addressString() -> String
//{
//    let addressString:String = "\n\n\(Constants.CBC.LONG)\n\(Constants.CBC.STREET_ADDRESS)\n\(Constants.CBC.CITY_STATE_ZIPCODE_COUNTRY)\nPhone: \(Constants.CBC.PHONE_NUMBER)\nE-mail:\(Constants.CBC.EMAIL)\nWeb: \(Constants.CBC.WEBSITE)"
//    
//    return addressString
//}


