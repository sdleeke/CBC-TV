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

class SearchHit {
    var mediaItem:MediaItem?
    
    var searchText:String?
    
    init(_ mediaItem:MediaItem?,_ searchText:String?)
    {
        self.mediaItem = mediaItem
        self.searchText = searchText
    }
    
    var title:Bool {
        get {
            guard let searchText = searchText else {
                return false
            }
            return mediaItem?.title?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var formattedDate:Bool {
        get {
            guard let searchText = searchText else {
                return false
            }
            return mediaItem?.formattedDate?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var speaker:Bool {
        get {
            guard let searchText = searchText else {
                return false
            }
            return mediaItem?.speaker?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var scriptureReference:Bool {
        get {
            guard let searchText = searchText else {
                return false
            }
            return mediaItem?.scriptureReference?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var className:Bool {
        get {
            guard let searchText = searchText else {
                return false
            }
            return mediaItem?.className?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var eventName:Bool {
        get {
            guard let searchText = searchText else {
                return false
            }
            return mediaItem?.eventName?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
    var tags:Bool {
        get {
            guard let searchText = searchText else {
                return false
            }
            return mediaItem?.tags?.range(of:searchText, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
        }
    }
}

class MediaItem : NSObject {
    var dict:[String:String]?
    
    var singleLoaded = false

    @objc func freeMemory()
    {

    }
    
    init(dict:[String:String]?)
    {
        super.init()
        self.dict = dict
        
        Thread.onMainThread { () -> (Void) in
            NotificationCenter.default.addObserver(self, selector: #selector(MediaItem.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    var id:String! {
        get {
            return dict?[Field.id] ?? "ID"
        }
    }
    
    var classCode:String {
        get {
            var chars = Constants.EMPTY_STRING
            
            for char in id {
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
            let afterClassCode = String(id[classCode.endIndex...])
            
            let ymd = "YYMMDD"
            
            let afterDate = String(afterClassCode[ymd.endIndex...])
            
            let code = String(afterDate[..<"x".endIndex])

            return code
        }
    }
    
    var conferenceCode:String? {
        get {
            if serviceCode == "s" {
                let afterClassCode = String(id[classCode.endIndex...])
                
                var string = String(id[..<classCode.endIndex])
                
                let ymd = "YYMMDD"
                
                string = string + String(afterClassCode[..<ymd.endIndex])
                
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
            let afterClassCode = String(id[classCode.endIndex...])
            
            var string = String(id[..<classCode.endIndex])
            
            let ymd = "YYMMDD"
            
            string = string + String(afterClassCode[..<ymd.endIndex]) + serviceCode
            
            let code = String(id[string.endIndex...])
            
            if !code.isEmpty  {
                return code
            } else {
                return nil
            }
        }
    }
    
    var multiPartMediaItems:[MediaItem]? {
        get {
            guard hasMultipleParts, let multiPartSort = multiPartSort else {
                return [self]
            }
            
            var mediaItemParts:[MediaItem]?
            if (globals.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL] == nil) {
                mediaItemParts = globals.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                    if testMediaItem.hasMultipleParts {
                        return (testMediaItem.category == category) && (testMediaItem.multiPartName == multiPartName)
                    } else {
                        return false
                    }
                })
            } else {
                mediaItemParts = globals.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL]?.filter({ (testMediaItem:MediaItem) -> Bool in
                    return (testMediaItem.multiPartName == multiPartName) && (testMediaItem.category == category)
                })
            }
            
            // Filter for conference series
            
            if conferenceCode != nil {
                mediaItemParts = sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                    return testMediaItem.conferenceCode == conferenceCode
                }),sorting: SORTING.CHRONOLOGICAL)
            } else {
                if hasClassName {
                    mediaItemParts = sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                        //                        print(classCode,testMediaItem.classCode)
                        return testMediaItem.classCode == classCode
                    }),sorting: SORTING.CHRONOLOGICAL)
                } else {
                    mediaItemParts = sortMediaItemsByYear(mediaItemParts,sorting: SORTING.CHRONOLOGICAL)
                }
            }
            
            // Filter for multiple series of the same name
            var mediaList = [MediaItem]()
            
            if let mediaItemParts = mediaItemParts, mediaItemParts.count > 1 {
                var number = 0
                
                for mediaItem in mediaItemParts {
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
        }
    }
    
    func searchStrings() -> [String]?
    {
        var array = [String]()
        
        if hasSpeaker, let speaker = speaker {
            array.append(speaker)
        }
        
        if hasMultipleParts, let multiPartName = multiPartName {
            array.append(multiPartName)
        } else {
            if let title = title {
                array.append(title)
            }
        }
        
        if let books = books {
            array.append(contentsOf: books)
        }
        
        if let titleTokens = tokensFromString(title) {
            array.append(contentsOf: titleTokens)
        }
        
        return array.count > 0 ? array : nil
    }
    
    func searchTokens() -> [String]?
    {
        var set = Set<String>()

        if let tagsArray = tagsArray {
            for tag in tagsArray {
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
        
        if let books = books {
            set = set.union(Set(books))
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
        guard !tag.isEmpty else {
            return nil
        }
        
        guard let tagsSet = tagsSet else {
            return nil
        }
        
        var mediaItems:[MediaItem]?
        
        if tagsSet.contains(tag) {
            mediaItems = globals.media.all?.tagMediaItems?[tag]
        }
        
        return mediaItems
    }

    var playingURL:URL? {
        get {
            var url:URL?
            
            if let playing = playing {
                switch playing {
                case Playing.audio:
                    url = audioURL
                    break
                    
                case Playing.video:
                    url = videoURL
                    break
                    
                default:
                    break
                }
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
    
    var playing:String? {
        get {
            if (dict?[Field.playing] == nil) {
                if let playing = mediaItemSettings?[Field.playing] {
                    dict?[Field.playing] = playing
                } else {
                    let playing = hasAudio ? Playing.audio : (hasVideo ? Playing.video : nil)
                    dict?[Field.playing] = playing
                }
            }
            
            if !hasAudio && (dict?[Field.playing] == Playing.audio) {
                dict?[Field.playing] = hasVideo ? Playing.video : nil
            }

            if !hasVideo && (dict?[Field.playing] == Playing.video) {
                dict?[Field.playing] = hasAudio ? Playing.video : nil
            }
            
            return dict?[Field.playing]
        }
        
        set {
            if newValue != dict?[Field.playing] {
                if globals.mediaPlayer.mediaItem == self {
                    globals.mediaPlayer.stop()
                }
                
                dict?[Field.playing] = newValue
                mediaItemSettings?[Field.playing] = newValue
            }
        }
    }
    
//    var wasShowing:String? = Showing.none //This is an arbitrary choice
    
    var pageImages:[UIImage]?

    var pageNum:Int?
//    {
//        get {
//            if let range = showing?.range(of: Showing.slides) {
//                if let num = String(showing?[range.upperBound...]) {
//                    return Int(num)
//                }
//            }
//            
//            return nil
//        }
//        
//        set {
//            if let num = newValue, showing?.range(of: Showing.slides) != nil {
//                showing = "\(Showing.slides)\(num)"
//            }
//        }
//    }

    var showing:String? {
        get {
            if (dict?[Field.showing] == nil) {
                if let showing = mediaItemSettings?[Field.showing] {
                    dict?[Field.showing] = showing
                } else {
                    dict?[Field.showing] = Showing.none
                }
            }
            return dict?[Field.showing]
        }
        
        set {
            dict?[Field.showing] = newValue
            mediaItemSettings?[Field.showing] = newValue
        }
    }
    
    var atEnd:Bool {
        get {
            guard let playing = playing else {
                return false
            }
            
            if let atEnd = mediaItemSettings?[Constants.SETTINGS.AT_END+playing] {
                dict?[Constants.SETTINGS.AT_END+playing] = atEnd
            } else {
                dict?[Constants.SETTINGS.AT_END+playing] = "NO"
            }
            return dict?[Constants.SETTINGS.AT_END+playing] == "YES"
        }
        
        set {
            guard let playing = playing else {
                return
            }
            
            dict?[Constants.SETTINGS.AT_END+playing] = newValue ? "YES" : "NO"
            mediaItemSettings?[Constants.SETTINGS.AT_END+playing] = newValue ? "YES" : "NO"
        }
    }
    
    var websiteURL:URL? {
        get {
            return URL(string: Constants.CBC.SINGLE_WEBSITE + id)
        }
    }
    
    var hasCurrentTime : Bool
    {
        guard let currentTime = currentTime else {
            return false
        }
        
        return Float(currentTime) != nil
    }
    
    var currentTime:String? {
        get {
            guard let playing = playing else {
                return nil
            }
            
            if let current_time = mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing] {
                dict?[Constants.SETTINGS.CURRENT_TIME+playing] = current_time
            } else {
                dict?[Constants.SETTINGS.CURRENT_TIME+playing] = "\(0)"
            }

            return dict?[Constants.SETTINGS.CURRENT_TIME+playing]
        }
        
        set {
            guard let playing = playing else {
                return
            }
            
            dict?[Constants.SETTINGS.CURRENT_TIME+playing] = newValue
            
            if mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing] != newValue {
               mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing] = newValue
            }
        }
    }
    
    var seriesID:String! {
        get {
            if hasMultipleParts, let multiPartName = multiPartName {
                return (conferenceCode != nil ? conferenceCode! : classCode) + multiPartName
            } else {
                return id!
            }
        }
    }
    
    var year:Int? {
        get {
            if let date = date, let range = date.range(of: "-") {
                let year = String(date[..<range.lowerBound])
                return Int(year)
            } else {
                return nil
            }
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
            if let date = date, let range = date.range(of: "-") {
                let year = String(date[..<range.lowerBound])
                return year
            } else {
                return "None"
            }
        }
    }

    func singleJSONFromURL() -> [String:String]?
    {
        guard globals.reachability.isReachable else {
            return nil
        }
        
        guard let id = id, let url = URL(string: Constants.JSON.URL.SINGLE + id) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                return json as? [String:String]
            } catch let error as NSError {
                NSLog(error.localizedDescription)
            }
        } catch let error as NSError {
            NSLog(error.localizedDescription)
        }
        
        return nil
    }
    
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
    
    var dateService:String? {
        get {
            return dict?[Field.date]
        }
    }
    
    var date:String? {
        get {
            if let range = dict?[Field.date]?.range(of: Constants.SINGLE_SPACE) {
                if let stringSubSequence = dict?[Field.date]?[..<range.lowerBound] {
                    return String(stringSubSequence) // last two characters
                }
            }

            return nil
        }
    }
    
    var service:String? {
        get {
            if let string = dict?[Field.date], let range = string.range(of: Constants.SINGLE_SPACE) {
                return String(string[range.upperBound...]) // last two characters
            } else {
                return nil
            }
        }
    }
    
    var title:String? {
        get {
            return dict?[Field.title]
        }
    }
    
    var category:String? {
        get {
            return dict?[Field.category]
        }
    }
    
    var scriptureReference:String? {
        get {
            return dict?[Field.scripture]?.replacingOccurrences(of: "Psalm ", with: "Psalms ")
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
            return dict?[Field.className]
        }
    }
    
    var eventSectionSort:String! {
        get {
            return eventSection.lowercased()
        }
    }
    
    var eventSection:String! {
        get {
            return eventName ?? Constants.None
        }
    }
    
    var eventName:String? {
        get {
            return dict?[Field.eventName]
        }
    }
    
    var speakerSectionSort:String! {
        get {
            return speakerSort?.lowercased() ?? "ERROR"
        }
    }
    
    var speakerSection:String! {
        get {
            return speaker ?? Constants.None
        }
    }
    
    var speaker:String? {
        get {
            return dict?[Field.speaker]
        }
    }
    
    // this saves calculated values in defaults between sessions
    var speakerSort:String? {
        get {
            if dict?[Field.speaker_sort] == nil {
                if let speakerSort = mediaItemSettings?[Field.speaker_sort] {
                    dict?[Field.speaker_sort] = speakerSort
                } else {
                    //Sort on last names.  This assumes the speaker names are all fo the form "... <last name>" with one or more spaces before the last name and no spaces IN the last name, e.g. "Van Kirk"

                    var speakerSort:String?
                    
                    if hasSpeaker, let speaker = speaker {
                        if !speaker.contains("Ministry Panel") {
                            if let lastName = lastNameFromName(speaker) {
                                speakerSort = lastName
                            }
                            if let firstName = firstNameFromName(speaker) {
                                speakerSort = ((speakerSort != nil) ? speakerSort! + "," : "") + firstName
                            }
                        } else {
                            speakerSort = speaker
                        }
                    }
                        
                    dict?[Field.speaker_sort] = speakerSort ?? Constants.None
                }
            }

            return dict?[Field.speaker_sort]
        }
    }
    
    var multiPartSectionSort:String! {
        get {
            if hasMultipleParts, let multiPartSort = multiPartSort {
                return multiPartSort.lowercased()
            } else {
                if let title = stringWithoutPrefixes(title)?.lowercased() {
                    return title
                }
            }

            return "ERROR"
        }
    }
    
    var multiPartSection:String! {
        get {
            return hasMultipleParts ? multiPartName! : (title ?? Constants.Individual_Media)
        }
    }
    
    var multiPartSort:String? {
        get {
            if dict?[Field.multi_part_name_sort] == nil {
                if let multiPartSort = mediaItemSettings?[Field.multi_part_name_sort] {
                    dict?[Field.multi_part_name_sort] = multiPartSort
                } else {
                    if let multiPartSort = stringWithoutPrefixes(multiPartName) {
                        dict?[Field.multi_part_name_sort] = multiPartSort
                    } else {

                    }
                }
            }
            return dict?[Field.multi_part_name_sort]
        }
    }
    
    var multiPartName:String? {
        get {
            if (dict?[Field.multi_part_name] == nil) {
                if let range = title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
                    if let stringSubSequence = title?[..<range.lowerBound] {
                        let seriesString = String(stringSubSequence).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        
                        dict?[Field.multi_part_name] = seriesString
                    }
                }
            }
            
            return dict?[Field.multi_part_name]
        }
    }
    
    var part:String? {
        get {
            if hasMultipleParts && (dict?[Field.part] == nil) {
                if let title = title, let range = title.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
                    let partString = String(title[range.upperBound...])
                    
                    if let range = partString.range(of: ")") {
                        dict?[Field.part] = String(partString[..<range.lowerBound])
                    }
                }
            }
            
            return dict?[Field.part]
        }
    }
    
    func proposedTags(_ tags:String?) -> String?
    {
        var possibleTags = [String:Int]()
        
        if let tags = tagsArrayFromTagsString(tags) {
            for tag in tags {
                var possibleTag = tag
                
                if possibleTag.range(of: "-") != nil {
                    while let range = possibleTag.range(of: "-") {
                        let candidate = String(possibleTag[..<range.lowerBound]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        
                        if (Int(candidate) == nil) && !tags.contains(candidate) {
                            if let count = possibleTags[candidate] {
                                possibleTags[candidate] =  count + 1
                            } else {
                                possibleTags[candidate] =  1
                            }
                        }
                        
                        possibleTag = String(possibleTag[range.upperBound...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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
            
            if let className = className {
                dynamicTags = ((dynamicTags != nil) ? dynamicTags! + "|" : "") + className
            }
            
            if let eventName = eventName {
                dynamicTags = ((dynamicTags != nil) ? dynamicTags! + "|" : "") + eventName
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
                tags = ((tags != nil) ? tags! + "|" : "") + proposedTags
            }
            
            if let proposedTags = proposedTags(savedTags) {
                tags = ((tags != nil) ? tags! + "|" : "") + proposedTags
            }
            
            if let proposedTags = proposedTags(dynamicTags) {
                tags = ((tags != nil) ? tags! + "|" : "") + proposedTags
            }
            
            return tags
        }
    }
    
    func addTag(_ tag:String)
    {
        guard !tag.isEmpty else {
            return
        }
        
        let tags = tagsArrayFromTagsString(mediaItemSettings?[Field.tags])
        
        if tags?.index(of: tag) == nil {
            if let tags = mediaItemSettings?[Field.tags] {
                mediaItemSettings?[Field.tags] = tags + Constants.TAGS_SEPARATOR + tag
            } else {
                if (mediaItemSettings?[Field.tags] == nil) {
                    mediaItemSettings?[Field.tags] = tag
                }
            }
            
            if let sortTag = stringWithoutPrefixes(tag) {
                if globals.media.all?.tagMediaItems?[sortTag] != nil {
                    if globals.media.all?.tagMediaItems?[sortTag]?.index(of: self) == nil {
                        globals.media.all?.tagMediaItems?[sortTag]?.append(self)
                        globals.media.all?.tagNames?[sortTag] = tag
                    }
                } else {
                    globals.media.all?.tagMediaItems?[sortTag] = [self]
                    globals.media.all?.tagNames?[sortTag] = tag
                }
                
                if globals.media.tags.selected == tag, let selected = globals.media.tags.selected {
                    globals.media.tagged[selected] = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag])
                    
                    Thread.onMainThread { () -> (Void) in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
                    }
                }
                
                Thread.onMainThread { () -> (Void) in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
                }
            }
        }
    }
    
    func removeTag(_ tag:String)
    {
        guard (mediaItemSettings?[Field.tags] != nil) else {
            return
        }
        
        var tags = tagsArrayFromTagsString(mediaItemSettings?[Field.tags])
        
        while let index = tags?.index(of: tag) {
            tags?.remove(at: index)
        }
        
        mediaItemSettings?[Field.tags] = tagsArrayToTagsString(tags)
        
        if let sortTag = stringWithoutPrefixes(tag) {
            if let index = globals.media.all?.tagMediaItems?[sortTag]?.index(of: self) {
                globals.media.all?.tagMediaItems?[sortTag]?.remove(at: index)
            }
            
            if globals.media.all?.tagMediaItems?[sortTag]?.count == 0 {
                _ = globals.media.all?.tagMediaItems?.removeValue(forKey: sortTag)
            }
            
            if globals.media.tags.selected == tag, let selected = globals.media.tags.selected {
                globals.media.tagged[selected] = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag])
                
                Thread.onMainThread { () -> (Void) in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil) // globals.media.tagged
                }
            }
            
            Thread.onMainThread { () -> (Void) in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
            }
        }
    }
    
    func tagsSetToString(_ tagsSet:Set<String>?) -> String?
    {
        guard let tagsSet = tagsSet else {
            return nil
        }
        
        var tags:String?
        
        for tag in tagsSet {
            if let currentTags = tags {
                tags = currentTags + Constants.TAGS_SEPARATOR + tag
            } else {
                tags = tag
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
        
        while let range = tags.range(of: Constants.TAGS_SEPARATOR) {
            tag = String(tags[..<range.lowerBound])
            tagsSet.insert(tag)
            tags = String(tags[range.upperBound...])
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
            guard let tagsSet = tagsSet else {
                return nil
            }

            return Array(tagsSet).sorted() {
                return $0 < $1
            }
        }
    }
    
    var audio:String? {
        
        get {
            if dict?[Field.audio] == nil, hasAudio, let year = year, let id = id {
                dict?[Field.audio] = Constants.BASE_URL.MEDIA + "\(year)/\(id)" + Constants.FILENAME_EXTENSION.MP3
            }
            
            return dict?[Field.audio]
        }
    }
    
    var mp4:String? {
        get {
            return dict?[Field.mp4]
        }
    }
    
    var m3u8:String? {
        get {
            return dict?[Field.m3u8]
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
            
            guard let video = video else {
                return nil
            }
            
            guard video.contains(Constants.BASE_URL.VIDEO_PREFIX) else {
                return nil
            }
            
            let tail = String(video[Constants.BASE_URL.VIDEO_PREFIX.endIndex...])
//            print(tail)
            
            if let range = tail.range(of: ".m") {
                let id = String(tail[..<range.lowerBound])
                //            print(id)
                return id
            } else {
                return nil
            }
        }
    }
    
    var externalVideo:String? {
        get {
            guard let videoID = videoID else {
                return nil
            }
            
            return Constants.BASE_URL.EXTERNAL_VIDEO_PREFIX + videoID
        }
    }
    
    // A=Audio, V=Video, O=Outline, S=Slides, T=Transcript, H=HTML Transcript

    var files:String? {
        get {
            return dict?[Field.files]
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
            guard let audio = audio else {
                return nil
            }
            
            return URL(string: audio)
        }
    }
    
    var videoURL:URL? {
        get {
            guard let video = video else {
                return nil
            }
            
            return URL(string: video)
        }
    }
    
    var hasSlides:Bool {
        get {
            if let contains = files?.contains("S") {
                return contains
            } else {
                return false
            }
        }
    }
    
    var hasNotes:Bool {
        get {
            if let contains = files?.contains("T") {
                return contains
            } else {
                return false
            }
        }
    }

    var notes:String? {
        get {
            if (dict?[Field.notes] == nil), hasNotes, let year = year, let id = id {
                dict?[Field.notes] = Constants.BASE_URL.MEDIA + "\(year)/\(id)" + Field.notes + Constants.FILENAME_EXTENSION.PDF
            }
            
            //            print(dict?[Field.notes])
            return dict?[Field.notes]
        }
    }

    var slides:String? {
        get {
            if (dict?[Field.slides] == nil) && hasSlides, let year = year, let id = id {
                dict?[Field.slides] = Constants.BASE_URL.MEDIA + "\(year)/\(id)" + Field.slides + Constants.FILENAME_EXTENSION.PDF
            }
            
            return dict?[Field.slides]
        }
    }

    var notesURL:URL? {
        get {
            if let notes = notes {
                return URL(string: notes)
            } else {
                return nil
            }
        }
    }
    
    var slidesURL:URL? {
        get {
            if let slides = slides {
                return URL(string: slides)
            } else {
                return nil
            }
        }
    }

    var bookSections:[String]
    {
        get {
            guard let books = books else {
                if hasScripture, let scriptureReference = scriptureReference {
                    return [scriptureReference.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)]
                } else {
                    return [Constants.None]
                }
            }
            
            return books
        }
    }

    var books:[String]? {
        get {
            return booksFromScriptureReference(scriptureReference)
        }
    } //Derived from scripture
    
    lazy var fullDate:Date?  = {
        [unowned self] in
        if self.hasDate, let date = self.date {
            return Date(dateString:date)
        } else {
            return nil
        }
    }()//Derived from date
    
    var text : String? {
        get {
            var string:String?
            
            if hasDate, let formattedDate = formattedDate {
                string = formattedDate
            } else {
                string = "No Date"
            }
            
            if let service = service {
                string = string! + " \(service)"
            }
            
            if hasSpeaker, let speaker = speaker {
                string = string! + " \(speaker)"
            }
            
            if hasTitle, let title = title {
                if let range = title.range(of: " (Part ") {
                    let first = String(title[..<range.upperBound])
                    let second = String(title[range.upperBound...])
                    let combined = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
                    string = string! + "\n\(combined)"
                } else {
                    string = string! + "\n\(title)"
                }
            }
            
            if hasScripture, let scriptureReference = scriptureReference {
                string = string! + "\n\(scriptureReference)"
            }
            
            if hasClassName, let className = className {
                string = string! + "\n\(className)"
            }
            
            if hasEventName, let eventName = eventName {
                string = string! + "\n\(eventName)"
            }
            
            return string
        }
    }
    
    override var description : String {
        //This requires that date, service, title, and speaker fields all be non-nil
        
        var mediaItemString = "MediaItem: "
        
        if let category = category {
            mediaItemString = "\(mediaItemString) \(category)"
        }
        
        if let id = id {
            mediaItemString = "\(mediaItemString) \(id)"
        }
        
        if let date = date {
            mediaItemString = "\(mediaItemString) \(date)"
        }
        
        if let service = service {
            mediaItemString = "\(mediaItemString) \(service)"
        }
        
        if let title = title {
            mediaItemString = "\(mediaItemString) \(title)"
        }
        
        if let scriptureReference = scriptureReference {
            mediaItemString = "\(mediaItemString) \(scriptureReference)"
        }
        
        if let speaker = speaker {
            mediaItemString = "\(mediaItemString) \(speaker)"
        }
        
        return mediaItemString
    }
    
    class MediaItemSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        subscript(key:String) -> String? {
            get {
                guard let mediaItem = mediaItem else {
                    return nil
                }
                
                return globals.mediaItemSettings?[mediaItem.id]?[key]
            }
            set {
                guard let mediaItem = mediaItem else {
                    print("mediaItem == nil in Settings!")
                    return
                }
                
                if globals.mediaItemSettings == nil {
                    globals.mediaItemSettings = [String:[String:String]]()
                }
                if (globals.mediaItemSettings != nil) {
                    if (globals.mediaItemSettings?[mediaItem.id] == nil) {
                        globals.mediaItemSettings?[mediaItem.id] = [String:String]()
                    }
                    if (globals.mediaItemSettings?[mediaItem.id]?[key] != newValue) {
                        //                        print("\(mediaItem)")
                        globals.mediaItemSettings?[mediaItem.id]?[key] = newValue
                        
                        // For a high volume of activity this can be very expensive.
                        globals.saveSettingsBackground()
                    }
                } else {
                    print("globals.settings == nil in Settings!")
                }
            }
        }
    }
    
    lazy var mediaItemSettings:MediaItemSettings? = {
        [unowned self] in
        return MediaItemSettings(mediaItem:self)
    }()
    
    class MultiPartSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        subscript(key:String) -> String? {
            get {
                guard let mediaItem = mediaItem else {
                    print("mediaItem == nil in MultiPartSettings!")
                    return nil
                }
                
                return globals.multiPartSettings?[mediaItem.seriesID]?[key]
            }
            set {
                guard let mediaItem = mediaItem else {
                    print("mediaItem == nil in MultiPartSettings!")
                    return
                }

                if globals.multiPartSettings == nil {
                    globals.multiPartSettings = [String:[String:String]]()
                }
                
                guard (globals.multiPartSettings != nil) else {
                    print("globals.viewSplits == nil in SeriesSettings!")
                    return
                }
                
                if (globals.multiPartSettings?[mediaItem.seriesID] == nil) {
                    globals.multiPartSettings?[mediaItem.seriesID] = [String:String]()
                }
                if (globals.multiPartSettings?[mediaItem.seriesID]?[key] != newValue) {
                    //                        print("\(mediaItem)")
                    globals.multiPartSettings?[mediaItem.seriesID]?[key] = newValue
                    
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
    
    var hasDate:Bool
    {
        guard let isEmpty = date?.isEmpty else {
            return false
        }
        
        return !isEmpty
    }
    
    var hasTitle:Bool
    {
        guard let isEmpty = title?.isEmpty else {
            return false
        }
        
        return !isEmpty
    }
    
    var hasService:Bool
    {
        guard let isEmpty = service?.isEmpty else {
            return false
        }
        
        return !isEmpty
    }
    
    var playingAudio:Bool
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
        }
    }
    
    var hasClassName:Bool
        {
        get {
            guard let isEmpty = className?.isEmpty else {
                return false
            }
            
            return !isEmpty
        }
    }
    
    var hasEventName:Bool
        {
        get {
            guard let isEmpty = eventName?.isEmpty else {
                return false
            }
            
            return !isEmpty
        }
    }
    
    var hasMultipleParts:Bool
        {
        get {
            guard let isEmpty = multiPartName?.isEmpty else {
                return false
            }
            
            return !isEmpty
        }
    }
    
    var hasCategory:Bool
        {
        get {
            guard let isEmpty = category?.isEmpty else {
                return false
            }
            
            return !isEmpty
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
        }
    }
    
    var hasTags:Bool
    {
        get {
            guard let isEmpty = tags?.isEmpty else {
                return false
            }
            
            return !isEmpty
        }
    }
    
    var hasFavoritesTag:Bool
    {
        get {
            if hasTags, let tagsSet = tagsSet {
                return tagsSet.contains(Constants.Strings.Favorites)
            } else {
                return false
            }
        }
    }
}
