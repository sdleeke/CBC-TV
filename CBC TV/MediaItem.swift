//
//  MediaItem.swift
//  CBC
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import AVKit

struct SearchHit {
    var mediaItem:MediaItem?
    
    var searchText:String?
    
    init(_ mediaItem:MediaItem?,_ searchText:String?)
    {
        self.mediaItem = mediaItem
        self.searchText = searchText
    }
    
    var title:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.title?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var formattedDate:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.formattedDate?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var speaker:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.speaker?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var scriptureReference:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.scriptureReference?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var className:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.className?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var eventName:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.eventName?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var tags:Bool {
        get {
            guard searchText != nil else {
                return false
            }
            return mediaItem?.tags?.range(of:searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
}

class MediaItem : NSObject {
    var dict:[String:String]?
    
    var singleLoaded = false

    func freeMemory()
    {

    }
    
    init(dict:[String:String]?)
    {
        super.init()
//        print("\(dict)")
        self.dict = dict
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaItem.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    var id:String! {
        get {
            return dict![Field.id]
        }
    }
    
    var classCode:String {
        get {
            var chars = Constants.EMPTY_STRING
            
            for char in id.characters {
                if Int(String(char)) != nil {
                    break
                }
                chars.append(char)
            }
            
            return chars
        }
    }
    
    var serviceCode:String {
        get {
            let afterClassCode = id.substring(from: classCode.endIndex)
            
            let ymd = "YYMMDD"
            
            let afterDate = afterClassCode.substring(from: ymd.endIndex)
            
            let code = afterDate.substring(to: "x".endIndex)
            
            //        print(code)
            
            return code
        }
    }
    
    var conferenceCode:String? {
        get {
            if serviceCode == "s" {
                let afterClassCode = id.substring(from: classCode.endIndex)
                
                var string = id.substring(to: classCode.endIndex)
                
                let ymd = "YYMMDD"
                
                string = string + afterClassCode.substring(to: ymd.endIndex)
                
                let s = "s"
                
                let code = string + s
                
                //            print(code)
                
                return code
            }
            
            return nil
        }
    }
    
    var repeatCode:String? {
        get {
            let afterClassCode = id.substring(from: classCode.endIndex)
            
            var string = id.substring(to: classCode.endIndex)
            
            let ymd = "YYMMDD"
            
            string = string + afterClassCode.substring(to: ymd.endIndex) + serviceCode
            
            let code = id.substring(from: string.endIndex)
            
            if code != Constants.EMPTY_STRING  {
                //            print(code)
                return code
            } else {
                return nil
            }
        }
    }
    
    var multiPartMediaItems:[MediaItem]? {
        get {
            if (hasMultipleParts) {
                var mediaItemParts:[MediaItem]?
//                print(multiPartSort)
                if (globals.media.all?.groupSort?[Grouping.TITLE]?[multiPartSort!]?[Sorting.CHRONOLOGICAL] == nil) {
                    mediaItemParts = globals.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                        if testMediaItem.hasMultipleParts {
                            return (testMediaItem.category == category) && (testMediaItem.multiPartName == multiPartName)
                        } else {
                            return false
                        }
                    })
                } else {
                    mediaItemParts = globals.media.all?.groupSort?[Grouping.TITLE]?[multiPartSort!]?[Sorting.CHRONOLOGICAL]?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return (testMediaItem.multiPartName == multiPartName) && (testMediaItem.category == category)
                    })
                }

//                print(id)
//                print(id.range(of: "s")?.lowerBound)
//                print("flYYMMDD".endIndex)
                
//                print(mediaItemParts)
                
                // Filter for conference series
                
                if conferenceCode != nil {
                    mediaItemParts = sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return testMediaItem.conferenceCode == conferenceCode
                    }),sorting: Sorting.CHRONOLOGICAL)
                } else {
                    if hasClassName {
                        mediaItemParts = sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                            //                        print(classCode,testMediaItem.classCode)
                            return testMediaItem.classCode == classCode
                        }),sorting: Sorting.CHRONOLOGICAL)
                    } else {
                        mediaItemParts = sortMediaItemsByYear(mediaItemParts,sorting: Sorting.CHRONOLOGICAL)
                    }
                }
                
                // Filter for multiple series of the same name
                var mediaList = [MediaItem]()
                
                if mediaItemParts?.count > 1 {
                    var number = 0
                    
                    for mediaItem in mediaItemParts! {
                        if let part = mediaItem.part, let partNumber = Int(part) {
                            if partNumber > number {
                                mediaList.append(mediaItem)
                                number = partNumber
                            } else {
                                if (mediaList.count > 0) && mediaList.contains(self) {
                                    break
                                } else {
                                    mediaList = [mediaItem]
                                    number = partNumber
                                }
                            }
                        }
                    }
                    
                    return mediaList.count > 0 ? mediaList : nil
                } else {
                    return mediaItemParts
                }
            } else {
                return [self]
            }
        }
    }
    
    func searchStrings() -> [String]?
    {
        var array = [String]()
        
        if hasSpeaker {
            array.append(speaker!)
        }
        
        if hasMultipleParts {
            array.append(multiPartName!)
        } else {
            array.append(title!)
        }
        
        if books != nil {
            array.append(contentsOf: books!)
        }
        
        if let titleTokens = tokensFromString(title) {
            array.append(contentsOf: titleTokens)
        }
        
        return array.count > 0 ? array : nil
    }
    
    func searchTokens() -> [String]?
    {
        var set = Set<String>()

        if tagsArray != nil {
            for tag in tagsArray! {
                if let tokens = tokensFromString(tag) {
                    set = set.union(Set(tokens))
                }
            }
        }
        
        if hasSpeaker {
            if let firstname = firstNameFromName(speaker) {
                set.insert(firstname)
            }

            if let lastname = lastNameFromName(speaker) {
                set.insert(lastname)
            }
        }
        
        if books != nil {
            set = set.union(Set(books!))
        }
        
        if let titleTokens = tokensFromString(title) {
            set = set.union(Set(titleTokens))
        }
        
        return set.count > 0 ? Array(set).map({ (string:String) -> String in
                return string.uppercased()
            }).sorted() : nil
    }
    
    func searchHit(_ searchText:String?) -> SearchHit
    {
        return SearchHit(self,searchText)
    }
    
    func search(_ searchText:String?) -> Bool
    {
        let searchHit = SearchHit(self,searchText)
        
//        if searchHit.tags {
//            print(self)
//            print(tags)
//        }
        
        return searchHit.title || searchHit.formattedDate || searchHit.speaker || searchHit.scriptureReference || searchHit.className || searchHit.eventName || searchHit.tags
    }
        
    func mediaItemsInCollection(_ tag:String) -> [MediaItem]?
    {
        var mediaItems:[MediaItem]?
        
        if (tagsSet != nil) && tagsSet!.contains(tag) {
            mediaItems = globals.media.all?.tagMediaItems?[tag]
        }
        
        return mediaItems
    }

    var playingURL:URL? {
        get {
            var url:URL?
            
            switch playing! {
            case Playing.audio:
                url = audioURL
                break
                
            case Playing.video:
                url = videoURL
                break
                
            default:
                break
            }
            
            return url
        }
    }
    
    var isInMediaPlayer:Bool {
        get {
            return (self == globals.mediaPlayer.mediaItem)
        }
    }
    
    var isLoaded:Bool {
        get {
            return isInMediaPlayer && globals.mediaPlayer.loaded
        }
    }
    
    var isPlaying:Bool {
        get {
            return globals.mediaPlayer.url == playingURL
        }
    }
    
    // this supports settings values that are saved in defaults between sessions
    var playing:String? {
        get {
            if (dict![Field.playing] == nil) {
                if let playing = mediaItemSettings?[Field.playing] {
                    dict![Field.playing] = playing
                } else {
                    dict![Field.playing] = hasAudio ? Playing.audio : (hasVideo ? Playing.video : nil)
                }
            }
            
            if !hasAudio && (dict![Field.playing] == Playing.audio) {
                dict![Field.playing] = hasVideo ? Playing.video : nil
            }

            if !hasVideo && (dict![Field.playing] == Playing.video) {
                dict![Field.playing] = hasAudio ? Playing.video : nil
            }
            
            return dict![Field.playing]
        }
        
        set {
            if newValue != dict![Field.playing] {
                //Changing audio to video or vice versa resets the state and time.
                if globals.mediaPlayer.mediaItem == self {
                    globals.mediaPlayer.stop()
                }
                
                dict![Field.playing] = newValue
                mediaItemSettings?[Field.playing] = newValue
            }
        }
    }
    
    var wasShowing:String? = Showing.slides //This is an arbitrary choice
    
    // this supports settings values that are saved in defaults between sessions
    var showing:String? {
        get {
            if (dict![Field.showing] == nil) {
                if let showing = mediaItemSettings?[Field.showing] {
                    dict![Field.showing] = showing
                } else {
                    dict![Field.showing] = Showing.none
                }
            }
            return dict![Field.showing]
        }
        
        set {
            if newValue != Showing.video {
                wasShowing = newValue
            }
            dict![Field.showing] = newValue
            mediaItemSettings?[Field.showing] = newValue
        }
    }
    
    var atEnd:Bool {
        get {
            if let atEnd = mediaItemSettings?[Constants.SETTINGS.AT_END+playing!] {
                dict![Constants.SETTINGS.AT_END+playing!] = atEnd
            } else {
                dict![Constants.SETTINGS.AT_END+playing!] = "NO"
            }
            return dict![Constants.SETTINGS.AT_END+playing!] == "YES"
        }
        
        set {
            dict![Constants.SETTINGS.AT_END+playing!] = newValue ? "YES" : "NO"
            mediaItemSettings?[Constants.SETTINGS.AT_END+playing!] = newValue ? "YES" : "NO"
        }
    }
    
    var websiteURL:URL? {
        get {
            return URL(string: Constants.CBC.SINGLE_WEBSITE + id)
        }
    }
    
    func hasCurrentTime() -> Bool
    {
        return (currentTime != nil) && (Float(currentTime!) != nil)
    }
    
    var currentTime:String? {
        get {
            if let current_time = mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] {
                dict![Constants.SETTINGS.CURRENT_TIME+playing!] = current_time
            } else {
                dict![Constants.SETTINGS.CURRENT_TIME+playing!] = "\(0)"
            }
//            print(dict![Constants.SETTINGS.CURRENT_TIME+playing!])
            return dict![Constants.SETTINGS.CURRENT_TIME+playing!]
        }
        
        set {
            dict![Constants.SETTINGS.CURRENT_TIME+playing!] = newValue
            
            if mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] != newValue {
               mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] = newValue 
            }
        }
    }
    
    var seriesID:String! {
        get {
            if hasMultipleParts {
                return (conferenceCode != nil ? conferenceCode! : classCode) + multiPartName!
            } else {
                return id!
            }
        }
    }
    
    var year:Int? {
        get {
            if (fullDate != nil) {
                return (Calendar.current as NSCalendar).components(.year, from: fullDate!).year
            }
            return nil
        }
    }
    
    var yearSection:String!
    {
        get {
            return yearString
        }
    }
    
    var yearString:String! {
        get {
            if (year != nil) {
                return "\(year!)"
            } else {
                return "None"
            }
        }
    }

    func singleJSONFromURL() -> [String:String]?
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(string: Constants.JSON.URL.SINGLE + self.id!)!) // , options: NSData.ReadingOptions.mappedIfSafe
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                return json as? [String:String]
            } catch let error as NSError {
                NSLog(error.localizedDescription)
            }
            
            //            let json = JSON(data: data)
            //            if json != JSON.null {
            //
            ////                print(json)
            //
            //                return json
            //            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
        }
        
        return nil
    }
    
//    func singleJSONFromURL() -> JSON
//    {
//        do {
//            let data = try Data(contentsOf: URL(string: Constants.JSON.URL.SINGLE + self.id!)!) // , options: NSData.ReadingOptions.mappedIfSafe
//            
//            let json = JSON(data: data)
//            if json != JSON.null {
//                
////                print(json)
//                
//                return json
//            }
//        } catch let error as NSError {
//            NSLog(error.localizedDescription)
//        }
//        
//        return nil
//    }
    
//    func loadSingleDict() -> [String:String]?
//    {
//        var mediaItemDicts = [[String:String]]()
//        
//        let json = singleJSONFromURL() // jsonDataFromDocumentsDirectory()
//        
//        if json != JSON.null {
//            print("single json:\(json)")
//            
//            let mediaItems = json[Constants.JSON.ARRAY_KEY.SINGLE_ENTRY]
//            
//            for i in 0..<mediaItems.count {
//                
//                var dict = [String:String]()
//                
//                for (key,value) in mediaItems[i] {
//                    dict["\(key)"] = "\(value)"
//                }
//                
//                mediaItemDicts.append(dict)
//            }
//            
////            print(mediaItemDicts)
//            
//            return mediaItemDicts.count > 0 ? mediaItemDicts[0] : nil
//        } else {
//            print("could not get json from URL, make sure that URL contains valid json.")
//        }
//        
//        return nil
//    }
    
    func formatDate(_ format:String?) -> String? {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = format
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateStringFormatter.string(for: fullDate)
    }
    
    var formattedDate:String? {
        get {
            return formatDate("MMMM d, yyyy")
        }
    }
    
    var formattedDateMonth:String? {
        get {
            return formatDate("MMMM")
        }
    }
    
    var formattedDateDay:String? {
        get {
            return formatDate("d")
        }
    }
    
    var formattedDateYear:String? {
        get {
            return formatDate("yyyy")
        }
    }
    
    var date:String? {
        get {
            return dict![Field.date]?.substring(to: dict![Field.date]!.range(of: Constants.SINGLE_SPACE)!.lowerBound) // last two characters // dict![Field.title]
        }
    }
    
    var service:String? {
        get {
            return dict![Field.date]?.substring(from: dict![Field.date]!.range(of: Constants.SINGLE_SPACE)!.upperBound) // last two characters // dict![Field.title]
        }
    }
    
    var title:String? {
        get {
            return dict![Field.title]
        }
    }
    
    var category:String? {
        get {
            return dict![Field.category]
        }
    }
    
    var scriptureReference:String? {
        get {
            return dict![Field.scripture]?.replacingOccurrences(of: "Psalm ", with: "Psalms ")
        }
    }
    
    var classSectionSort:String! {
        get {
            return classSection.lowercased()
        }
    }
    
    var classSection:String! {
        get {
            return hasClassName ? className! : Constants.None
        }
    }
    
    var className:String? {
        get {
            return dict![Field.className]
        }
    }
    
    var eventSectionSort:String! {
        get {
            return eventSection.lowercased()
        }
    }
    
    var eventSection:String! {
        get {
            return hasEventName ? eventName! : Constants.None
        }
    }
    
    var eventName:String? {
        get {
            return dict![Field.eventName]
        }
    }
    
    var speakerSectionSort:String! {
        get {
            return speakerSort!.lowercased()
        }
    }
    
    var speakerSection:String! {
        get {
            return hasSpeaker ? speaker! : Constants.None
        }
    }
    
    var speaker:String? {
        get {
            return dict![Field.speaker]
        }
    }
    
    // this saves calculated values in defaults between sessions
    var speakerSort:String? {
        get {
            if dict![Field.speaker_sort] == nil {
                if let speakerSort = mediaItemSettings?[Field.speaker_sort] {
                    dict![Field.speaker_sort] = speakerSort
                } else {
                    //Sort on last names.  This assumes the speaker names are all fo the form "... <last name>" with one or more spaces before the last name and no spaces IN the last name, e.g. "Van Kirk"

                    var speakerSort:String?
                    
                    if hasSpeaker {
                        if !speaker!.contains("Ministry Panel") {
                            if let lastName = lastNameFromName(speaker) {
                                speakerSort = lastName
                            }
                            if let firstName = firstNameFromName(speaker) {
                                speakerSort = (speakerSort != nil) ? speakerSort! + "," + firstName : firstName
                            }
                        } else {
                            speakerSort = speaker
                        }
                    }
                        
//                    print(speaker)
//                    print(speakerSort)
                    
                    dict![Field.speaker_sort] = speakerSort != nil ? speakerSort : Constants.None
                }
            }

            return dict![Field.speaker_sort]
        }
    }
    
    var multiPartSectionSort:String! {
        get {
            return hasMultipleParts ? multiPartSort!.lowercased() : stringWithoutPrefixes(title)!.lowercased() // Constants.Individual_Media
        }
    }
    
    var multiPartSection:String! {
        get {
            return hasMultipleParts ? multiPartName! : title! // Constants.Individual_Media
        }
    }
    
    // this saves calculated values in defaults between sessions
    var multiPartSort:String? {
        get {
            if dict![Field.multi_part_name_sort] == nil {
                if let multiPartSort = mediaItemSettings?[Field.multi_part_name_sort] {
                    dict![Field.multi_part_name_sort] = multiPartSort
                } else {
                    if let multiPartSort = stringWithoutPrefixes(multiPartName) {
                        dict![Field.multi_part_name_sort] = multiPartSort
//                        settings?[Field.series_sort] = multiPartSort
                    } else {
//                        print("multiPartSort is nil")
                    }
                }
            }
            return dict![Field.multi_part_name_sort]
        }
    }
    
    var multiPartName:String? {
        get {
            if (dict![Field.multi_part_name] == nil) {
                if (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) {
                    let seriesString = title!.substring(to: (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)!.lowerBound)!).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                    dict![Field.multi_part_name] = seriesString
                }
            }
            
            return dict![Field.multi_part_name]
        }
    }
    
    var part:String? {
        get {
            if hasMultipleParts && (dict![Field.part] == nil) {
                if (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) {
                    let partString = title!.substring(from: (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)!.upperBound)!)
//                    print(partString)
                    dict![Field.part] = partString.substring(to: partString.range(of: ")")!.lowerBound)
                }
            }
            
//            print(dict![Field.part])
            return dict![Field.part]
        }
    }
    
    func proposedTags(_ tags:String?) -> String?
    {
        var possibleTags = [String:Int]()
        
        if let tags = tagsArrayFromTagsString(tags) {
            for tag in tags {
                var possibleTag = tag
                
                if possibleTag.range(of: "-") != nil {
                    while possibleTag.range(of: "-") != nil {
                        let range = possibleTag.range(of: "-")
                        
                        let candidate = possibleTag.substring(to: range!.lowerBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        
                        if (Int(candidate) == nil) && !tags.contains(candidate) {
                            if let count = possibleTags[candidate] {
                                possibleTags[candidate] =  count + 1
                            } else {
                                possibleTags[candidate] =  1
                            }
                        }
                        
                        possibleTag = possibleTag.substring(from: range!.upperBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    }
                    
                    if !possibleTag.isEmpty {
                        let candidate = possibleTag.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        
                        if (Int(candidate) == nil) && !tags.contains(candidate) {
                            if let count = possibleTags[candidate] {
                                possibleTags[candidate] =  count + 1
                            } else {
                                possibleTags[candidate] =  1
                            }
                        }
                    }
                }
            }
        }
        
        let proposedTags:[String] = possibleTags.keys.map { (string:String) -> String in
            return string
        }
        return proposedTags.count > 0 ? tagsArrayToTagsString(proposedTags) : nil
    }
    
    var dynamicTags:String? {
        get {
            var dynamicTags:String?
            
            if hasClassName {
                dynamicTags = dynamicTags != nil ? dynamicTags! + "|" + className! : className!
            }
            
            if hasEventName {
                dynamicTags = dynamicTags != nil ? dynamicTags! + "|" + eventName! : eventName!
            }
            
            return dynamicTags
        }
    }
    
    // nil better be okay for these or expect a crash
    var tags:String? {
        get {
            let jsonTags = dict?[Field.tags]
            
            let savedTags = mediaItemSettings?[Field.tags]
            
            var tags:String?

            tags = tags != nil ? tags! + (jsonTags != nil ? "|" + jsonTags! : "") : (jsonTags != nil ? jsonTags : nil)
            
            tags = tags != nil ? tags! + (savedTags != nil ? "|" + savedTags! : "") : (savedTags != nil ? savedTags : nil)
            
            tags = tags != nil ? tags! + (dynamicTags != nil ? "|" + dynamicTags! : "") : (dynamicTags != nil ? dynamicTags : nil)
            
            if let proposedTags = proposedTags(jsonTags) {
                tags = tags != nil ? tags! + "|" + proposedTags : proposedTags
            }
            
            if let proposedTags = proposedTags(savedTags) {
                tags = tags != nil ? tags! + "|" + proposedTags : proposedTags
            }
            
            if let proposedTags = proposedTags(dynamicTags) {
                tags = tags != nil ? tags! + "|" + proposedTags : proposedTags
            }
            
//            print(tags)
            
            return tags
        }
    }
    
    func addTag(_ tag:String)
    {
        let tags = tagsArrayFromTagsString(mediaItemSettings![Field.tags])
        
//        print(tags)
        
        if tags?.index(of: tag) == nil {
            if (mediaItemSettings?[Field.tags] == nil) {
                mediaItemSettings?[Field.tags] = tag
            } else {
                mediaItemSettings?[Field.tags] = mediaItemSettings![Field.tags]! + Constants.TAGS_SEPARATOR + tag
            }
            
//            let tags = tagsArrayFromTagsString(mediaItemSettings![Field.tags])
//            print(tags)

            let sortTag = stringWithoutPrefixes(tag)
            
            if globals.media.all!.tagMediaItems![sortTag!] != nil {
                if globals.media.all!.tagMediaItems![sortTag!]!.index(of: self) == nil {
                    globals.media.all!.tagMediaItems![sortTag!]!.append(self)
                    globals.media.all!.tagNames![sortTag!] = tag
                }
            } else {
                globals.media.all!.tagMediaItems![sortTag!] = [self]
                globals.media.all!.tagNames![sortTag!] = tag
            }
            
            if (globals.media.tags.selected == tag) {
                globals.media.tagged[globals.media.tags.selected!] = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag!])
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil) // globals.media.tagged
                })
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
            }
        }
    }
    
    func removeTag(_ tag:String)
    {
        if (mediaItemSettings?[Field.tags] != nil) {
            var tags = tagsArrayFromTagsString(mediaItemSettings![Field.tags])
            
//            print(tags)
            
            while tags?.index(of: tag) != nil {
                tags?.remove(at: tags!.index(of: tag)!)
            }
            
//            print(tags)
            
            mediaItemSettings?[Field.tags] = tagsArrayToTagsString(tags)
            
            let sortTag = stringWithoutPrefixes(tag)
            
            if let index = globals.media.all?.tagMediaItems?[sortTag!]?.index(of: self) {
                globals.media.all?.tagMediaItems?[sortTag!]?.remove(at: index)
            }
            
            if globals.media.all?.tagMediaItems?[sortTag!]?.count == 0 {
                _ = globals.media.all?.tagMediaItems?.removeValue(forKey: sortTag!)
            }
            
            if (globals.media.tags.selected == tag) {
                globals.media.tagged[globals.media.tags.selected!] = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag!])
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil) // globals.media.tagged
                })
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
            }
        }
    }
    
    func tagsSetToString(_ tagsSet:Set<String>?) -> String?
    {
        var tags:String?
        
        if tagsSet != nil {
            for tag in tagsSet! {
                if tags == nil {
                    tags = tag
                } else {
                    tags = tags! + Constants.TAGS_SEPARATOR + tag
                }
            }
        }
        
        return tags
    }
    
    func tagsToSet(_ tags:String?) -> Set<String>?
    {
        guard var tags = tags else {
            return nil
        }
        
        var tag:String
        var tagsSet = Set<String>()
        
        while (tags.range(of: Constants.TAGS_SEPARATOR) != nil) {
            tag = tags.substring(to: tags.range(of: Constants.TAGS_SEPARATOR)!.lowerBound)
            tagsSet.insert(tag)
            tags = tags.substring(from: tags.range(of: Constants.TAGS_SEPARATOR)!.upperBound)
        }
        
        tagsSet.insert(tags)
        
        return tagsSet.count == 0 ? nil : tagsSet
    }
    
    var tagsSet:Set<String>? {
        get {
            return tagsToSet(self.tags)
        }
    }
    
    var tagsArray:[String]? {
        get {
            return tagsSet == nil ? nil : Array(tagsSet!).sorted() {
                return $0 < $1
            }
        }
    }
    
    var audio:String? {
        
        get {
            if (dict?[Field.audio] == nil) && hasAudio {
                dict![Field.audio] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Constants.FILENAME_EXTENSION.MP3
            }
            
//            print(dict![Field.audio])
            
            return dict![Field.audio]
        }
    }
    
    var mp4:String? {
        get {
            return dict![Field.mp4]
        }
    }
    
    var m3u8:String? {
        get {
            return dict![Field.m3u8]
        }
    }
    
    var video:String? {
        get {
            return m3u8
        }
    }
    
    var videoID:String? {
        get {
//            print(video)
            
            guard video != nil else {
                return nil
            }
            
            guard video!.contains(Constants.BASE_URL.VIDEO_PREFIX) else {
                return nil
            }
            
            let tail = video?.substring(from: Constants.BASE_URL.VIDEO_PREFIX.endIndex)
//            print(tail)
            
            let id = tail?.substring(to: tail!.range(of: ".m")!.lowerBound)
//            print(id)

            return id
        }
    }
    
    var externalVideo:String? {
        get {
            return videoID != nil ? Constants.BASE_URL.EXTERNAL_VIDEO_PREFIX + videoID! : nil
        }
    }
    
    // A=Audio, V=Video, O=Outline, S=Slides, T=Transcript, H=HTML Transcript

    var files:String? {
        get {
            return dict![Field.files]
        }
    }
    
    var hasAudio:Bool {
        get {
            if let contains = files?.contains("A") {
                return contains
            } else {
                return false
            }
        }
    }
    
    var hasVideo:Bool {
        get {
            if let contains = files?.contains("V") {
                return contains
            } else {
                return false
            }
        }
    }
    
    var audioURL:URL? {
        get {
//            print(audio)
            return audio != nil ? URL(string: audio!) : nil
        }
    }
    
    var videoURL:URL? {
        get {
            return video != nil ? URL(string: video!) : nil
        }
    }
    
    var bookSections:[String]
    {
        get {
            return books != nil ? books! : (hasScripture ? [scriptureReference!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)] : [Constants.None])
        }
    }

    var books:[String]? {
        get {
            return booksFromScriptureReference(scriptureReference)
        }
    } //Derived from scripture
    
    lazy var fullDate:Date?  = {
        [unowned self] in
        if (self.hasDate()) {
            return Date(dateString:self.date!)
        } else {
            return nil
        }
    }()//Derived from date
    
    var text : String? {
        get {
            var string:String?
            
            if hasDate() {
                string = formattedDate
            } else {
                string = "No Date"
            }
            
            if let service = service {
                string = string! + " \(service)"
            }
            
            if let speaker = speaker {
                string = string! + " \(speaker)"
            }
            
            if hasTitle() {
                if (title!.range(of: " (Part ") != nil) {
                    let first = title!.substring(to: (title!.range(of: " (Part")?.upperBound)!)
                    let second = title!.substring(from: (title!.range(of: " (Part ")?.upperBound)!)
                    let combined = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
                    string = string! + "\n\(combined)"
                } else {
                    string = string! + "\n\(title!)"
                }
            }
            
            if hasScripture {
                string = string! + "\n\(scriptureReference!)"
            }
            
            if hasClassName {
                string = string! + "\n\(className!)"
            }
            
            if hasEventName {
                string = string! + "\n\(eventName!)"
            }
            
            return string
        }
    }
    
    override var description : String {
        //This requires that date, service, title, and speaker fields all be non-nil
        
        var mediaItemString = "MediaItem: "
        
        if (category != nil) {
            mediaItemString = "\(mediaItemString) \(category!)"
        }
        
        if (id != nil) {
            mediaItemString = "\(mediaItemString) \(id!)"
        }
        
        if (date != nil) {
            mediaItemString = "\(mediaItemString) \(date!)"
        }
        
        if (service != nil) {
            mediaItemString = "\(mediaItemString) \(service!)"
        }
        
        if (title != nil) {
            mediaItemString = "\(mediaItemString) \(title!)"
        }
        
        if (scriptureReference != nil) {
            mediaItemString = "\(mediaItemString) \(scriptureReference!)"
        }
        
        if (speaker != nil) {
            mediaItemString = "\(mediaItemString) \(speaker!)"
        }
        
        return mediaItemString
    }
    
    struct MediaItemSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.mediaItemSettings?[mediaItem!.id]?[key]
            }
            set {
                if (mediaItem != nil) {
                    if globals.mediaItemSettings == nil {
                        globals.mediaItemSettings = [String:[String:String]]()
                    }
                    if (globals.mediaItemSettings != nil) {
                        if (globals.mediaItemSettings?[mediaItem!.id] == nil) {
                            globals.mediaItemSettings?[mediaItem!.id] = [String:String]()
                        }
                        if (globals.mediaItemSettings?[mediaItem!.id]?[key] != newValue) {
                            //                        print("\(mediaItem)")
                            globals.mediaItemSettings?[mediaItem!.id]?[key] = newValue
                            
                            // For a high volume of activity this can be very expensive.
                            globals.saveSettingsBackground()
                        }
                    } else {
                        print("globals.settings == nil in Settings!")
                    }
                } else {
                    print("mediaItem == nil in Settings!")
                }
            }
        }
    }
    
    lazy var mediaItemSettings:MediaItemSettings? = {
        [unowned self] in
        return MediaItemSettings(mediaItem:self)
    }()
    
    struct MultiPartSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.multiPartSettings?[mediaItem!.seriesID]?[key]
            }
            set {
                guard (mediaItem != nil) else {
                    print("mediaItem == nil in SeriesSettings!")
                    return
                }

                if globals.multiPartSettings == nil {
                    globals.multiPartSettings = [String:[String:String]]()
                }
                
                guard (globals.multiPartSettings != nil) else {
                    print("globals.viewSplits == nil in SeriesSettings!")
                    return
                }
                
                if (globals.multiPartSettings?[mediaItem!.seriesID] == nil) {
                    globals.multiPartSettings?[mediaItem!.seriesID] = [String:String]()
                }
                if (globals.multiPartSettings?[mediaItem!.seriesID]?[key] != newValue) {
                    //                        print("\(mediaItem)")
                    globals.multiPartSettings?[mediaItem!.seriesID]?[key] = newValue
                    
                    // For a high volume of activity this can be very expensive.
                    globals.saveSettingsBackground()
                }
            }
        }
    }
    
    lazy var multiPartSettings:MultiPartSettings? = {
        [unowned self] in
        return MultiPartSettings(mediaItem:self)
    }()
    
    var viewSplit:String? {
        get {
            return multiPartSettings?[Constants.VIEW_SPLIT]
        }
        set {
            multiPartSettings?[Constants.VIEW_SPLIT] = newValue
        }
    }
    
    var slideSplit:String? {
        get {
            return multiPartSettings?[Constants.SLIDE_SPLIT]
        }
        set {
            multiPartSettings?[Constants.SLIDE_SPLIT] = newValue
        }
    }
    
    func hasDate() -> Bool
    {
        return (date != nil) && (date != Constants.EMPTY_STRING)
    }
    
    func hasTitle() -> Bool
    {
        return (title != nil) && (title != Constants.EMPTY_STRING)
    }
    
    func playingAudio() -> Bool
    {
        return (playing == Playing.audio)
    }
    
    var playingVideo:Bool
    {
        get {
            return (playing == Playing.video)
        }
    }
    
    var showingVideo:Bool
    {
        get {
            return (showing == Showing.video)
        }
    }
    
    var hasScripture:Bool
        {
        get {
            guard let isEmpty = scriptureReference?.isEmpty else {
                return false
            }
            
            return !isEmpty
//            return (self.scriptureReference != nil) && (self.scriptureReference != Constants.EMPTY_STRING)
        }
    }
    
    var hasClassName:Bool
        {
        get {
            guard let isEmpty = className?.isEmpty else {
                return false
            }
            
            return !isEmpty
            //            return (self.className != nil) && (self.className != Constants.EMPTY_STRING)
        }
    }
    
    var hasEventName:Bool
        {
        get {
            guard let isEmpty = eventName?.isEmpty else {
                return false
            }
            
            return !isEmpty
            //            return (self.eventName != nil) && (self.eventName != Constants.EMPTY_STRING)
        }
    }
    
    var hasMultipleParts:Bool
        {
        get {
            guard let isEmpty = multiPartName?.isEmpty else {
                return false
            }
            
            return !isEmpty
//            return (self.multiPartName != nil) && (self.multiPartName != Constants.EMPTY_STRING)
        }
    }
    
    var hasCategory:Bool
        {
        get {
            guard let isEmpty = category?.isEmpty else {
                return false
            }
            
            return !isEmpty
//            return (self.category != nil) && (self.category != Constants.EMPTY_STRING)
        }
    }
    
    var hasBook:Bool
    {
        get {
            return (self.books != nil)
        }
    }
    
    var hasSpeaker:Bool
    {
        get {
            guard let isEmpty = speaker?.isEmpty else {
                return false
            }
            
            if isEmpty {
                print("speaker is empty")
            }
            
            return !isEmpty
//            return (self.speaker != nil) && (self.speaker != Constants.EMPTY_STRING)
        }
    }
    
    var hasTags:Bool
    {
        get {
            guard let isEmpty = tags?.isEmpty else {
                return false
            }
            
            return !isEmpty
//            return (self.tags != nil) && (self.tags != Constants.EMPTY_STRING)
        }
    }
    
    var hasFavoritesTag:Bool
    {
        get {
            return hasTags ? tagsSet!.contains(Constants.Favorites) : false
        }
    }
}
