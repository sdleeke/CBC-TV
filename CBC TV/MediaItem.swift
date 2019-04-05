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

class MediaItem : NSObject
{
    var storage : ThreadSafeDictionary<String>? = { // [String:String]?
        return ThreadSafeDictionary<String>(name: UUID().uuidString) // Can't be id because that becomes recursive.
    }()
    
    subscript(key:String?) -> String?
    {
        get {
            guard let key = key else {
                return nil
            }
            return storage?[key]
        }
        set {
            guard let key = key else {
                return
            }
            
            storage?[key] = newValue
        }
    }
    
    var singleLoaded = false

    var posterImageURL:URL?
    {
        get {
            guard hasVideo else {
                return nil
            }
            
            guard let year = year, let id = id else {
                return nil
            }
            
            if self[Field.poster] == nil {
                self[Field.poster] = Constants.BASE_URL.MEDIA + "\(year)/\(id)" + "poster.jpg"
            }
            
            return self[Field.poster]?.url
        }
    }
    
//    func posterImage(block:((UIImage?)->()))
//    {
//        posterImageURL?.image(block:block)
//    }
//
//    var posterImage:UIImage?
//    {
//        get {
//            return posterImageURL?.image
//        }
//    }

    lazy var posterImage:FetchImage? = { [weak self] in
        return FetchImage(url: self?.posterImageURL)
    }()
    
    var hasSeriesImage : Bool
    {
        return seriesImageName != nil
    }
    
    var seriesImageName : String?
    {
        return self[Field.seriesImage]
    }
    
    var seriesImageURL : URL?
    {
        guard let seriesImageName = seriesImageName else {
            return nil
        }
        
        let urlString = Constants.BASE_URL.MEDIA + "series/\(seriesImageName)"
        
        return urlString.url
    }
    
    lazy var seriesImage = { [weak self] in
        return FetchCachedImage(url: seriesImageURL)
    }()
    
    @objc func freeMemory()
    {

    }
    
    init(storage:[String:String]?)
    {
        super.init()
        
        self.storage?.update(storage: storage)
        
        Thread.onMainThread { () -> (Void) in
            NotificationCenter.default.addObserver(self, selector: #selector(self.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    var id:String!
    {
        get {
            return self[Field.id] ?? "ID"
        }
    }
    
    var classCode:String
    {
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
    
    var serviceCode:String
    {
        get {
            let afterClassCode = String(id[classCode.endIndex...])
            
            let ymd = "YYMMDD"
            
            let afterDate = String(afterClassCode[ymd.endIndex...])
            
            let code = String(afterDate[..<"x".endIndex])

            return code
        }
    }
    
    var conferenceCode:String?
    {
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
    
    var repeatCode:String?
    {
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

//    var multiPartMediaItems : [MediaItem]?
//    {
//        guard let mediaItem = mediaItem else {
//            return nil
//        }
//        
//        var multiPartMediaItems:[MediaItem]?
//        
//        if mediaItem.hasMultipleParts, let multiPartSort = mediaItem.multiPartSort {
//            if (Globals.shared.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL] == nil) {
//                let seriesMediaItems = Globals.shared.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
//                    return mediaItem.hasMultipleParts ? (testMediaItem.multiPartName == mediaItem.multiPartName) : (testMediaItem.id == mediaItem.id)
//                })
//                multiPartMediaItems = sortMediaItemsByYear(seriesMediaItems, sorting: SORTING.CHRONOLOGICAL)
//            } else {
//                if let multiPartSort = mediaItem.multiPartSort {
//                    multiPartMediaItems = Globals.shared.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL]
//                }
//            }
//        } else {
//            multiPartMediaItems = [mediaItem]
//        }
//        
//        return multiPartMediaItems
//    }

    var multiPartMediaItems:[MediaItem]?
    {
        get {
            guard hasMultipleParts, let multiPartSort = multiPartSort else {
                return [self]
            }
            
            var mediaItemParts:[MediaItem]?
            if (Globals.shared.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL] == nil) {
                mediaItemParts = Globals.shared.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                    if testMediaItem.hasMultipleParts {
                        return (testMediaItem.category == category) && (testMediaItem.multiPartName == multiPartName)
                    } else {
                        return false
                    }
                })
            } else {
                mediaItemParts = Globals.shared.media.all?.groupSort?[GROUPING.TITLE]?[multiPartSort]?[SORTING.CHRONOLOGICAL]?.filter({ (testMediaItem:MediaItem) -> Bool in
                    return (testMediaItem.multiPartName == multiPartName) && (testMediaItem.category == category)
                })
            }
            
            // Filter for conference series
            
            if conferenceCode != nil {
                mediaItemParts = mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                    return testMediaItem.conferenceCode == conferenceCode
                }).sortByYear(sorting: SORTING.CHRONOLOGICAL)
            } else {
                if hasClassName {
                    mediaItemParts = mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                        //                        print(classCode,testMediaItem.classCode)
                        return testMediaItem.classCode == classCode
                    }).sortByYear(sorting: SORTING.CHRONOLOGICAL)
                } else {
                    mediaItemParts = mediaItemParts?.sortByYear(sorting: SORTING.CHRONOLOGICAL)
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
        
        if let titleTokens = title?.tokens {
            array.append(contentsOf: titleTokens)
        }
        
        return array.count > 0 ? array : nil
    }
    
    func searchTokens() -> [String]?
    {
        var set = Set<String>()

        if let tagsArray = tagsArray {
            for tag in tagsArray {
                if let tokens = tag.tokens {
                    set = set.union(Set(tokens))
                }
            }
        }
        
        if hasSpeaker {
            if let firstname = speaker?.firstName {
                set.insert(firstname)
            }

            if let lastname = speaker?.lastName {
                set.insert(lastname)
            }
        }
        
        if let books = books {
            set = set.union(Set(books))
        }
        
        if let titleTokens = title?.tokens {
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
            mediaItems = Globals.shared.media.all?.tagMediaItems?[tag]
        }
        
        return mediaItems
    }

    var playingURL:URL?
    {
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
    
    var isInMediaPlayer:Bool
    {
        get {
            return (self == Globals.shared.mediaPlayer.mediaItem)
        }
    }
    
    var isLoaded:Bool
    {
        get {
            return isInMediaPlayer && Globals.shared.mediaPlayer.loaded
        }
    }
    
    var isPlaying:Bool
    {
        get {
            return Globals.shared.mediaPlayer.url == playingURL
        }
    }
    
    var playing:String?
    {
        get {
            if (self[Field.playing] == nil) {
                if let playing = mediaItemSettings?[Field.playing] {
                    self[Field.playing] = playing
                } else {
                    let playing = hasAudio ? Playing.audio : (hasVideo ? Playing.video : nil)
                    self[Field.playing] = playing
                }
            }
            
            if !hasAudio && (self[Field.playing] == Playing.audio) {
                self[Field.playing] = hasVideo ? Playing.video : nil
            }

            if !hasVideo && (self[Field.playing] == Playing.video) {
                self[Field.playing] = hasAudio ? Playing.video : nil
            }
            
            return self[Field.playing]
        }
        
        set {
            if newValue != self[Field.playing] {
                if Globals.shared.mediaPlayer.mediaItem == self {
                    Globals.shared.mediaPlayer.stop()
                }
                
                self[Field.playing] = newValue
                mediaItemSettings?[Field.playing] = newValue
            }
        }
    }
    
    var pageImages:[UIImage]?

    var pageNum:Int?

    var showing:String?
    {
        get {
            if (self[Field.showing] == nil) {
                if let showing = mediaItemSettings?[Field.showing] {
                    self[Field.showing] = showing
                } else {
                    self[Field.showing] = Showing.none
                }
            }
            return self[Field.showing]
        }
        
        set {
            self[Field.showing] = newValue
            mediaItemSettings?[Field.showing] = newValue
        }
    }
    
    var atEnd:Bool
    {
        get {
            guard let playing = playing else {
                return false
            }
            
            if let atEnd = mediaItemSettings?[Constants.SETTINGS.AT_END+playing] {
                self[Constants.SETTINGS.AT_END+playing] = atEnd
            } else {
                self[Constants.SETTINGS.AT_END+playing] = "NO"
            }
            return self[Constants.SETTINGS.AT_END+playing] == "YES"
        }
        
        set {
            guard let playing = playing else {
                return
            }
            
            self[Constants.SETTINGS.AT_END+playing] = newValue ? "YES" : "NO"
            mediaItemSettings?[Constants.SETTINGS.AT_END+playing] = newValue ? "YES" : "NO"
        }
    }
    
    var websiteURL:URL?
    {
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
    
    var currentTime:String?
    {
        get {
            guard let playing = playing else {
                return nil
            }
            
            if let current_time = mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing] {
                self[Constants.SETTINGS.CURRENT_TIME+playing] = current_time
            } else {
                self[Constants.SETTINGS.CURRENT_TIME+playing] = "\(0)"
            }

            return self[Constants.SETTINGS.CURRENT_TIME+playing]
        }
        
        set {
            guard let playing = playing else {
                return
            }
            
            self[Constants.SETTINGS.CURRENT_TIME+playing] = newValue
            
            if mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing] != newValue {
               mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing] = newValue
            }
        }
    }
    
    var seriesID:String!
    {
        get {
            if hasMultipleParts, let multiPartName = multiPartName {
                return (conferenceCode != nil ? conferenceCode! : classCode) + multiPartName
            } else {
                return id!
            }
        }
    }
    
    var year:Int?
    {
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
    
    var yearString:String!
    {
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
        guard Globals.shared.reachability.isReachable else {
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
    
    var formattedDate:String?
    {
        get {
            return formatDate("MMMM d, yyyy")
        }
    }
    
    var formattedDateMonth:String?
    {
        get {
            return formatDate("MMMM")
        }
    }
    
    var formattedDateDay:String?
    {
        get {
            return formatDate("d")
        }
    }
    
    var formattedDateYear:String?
    {
        get {
            return formatDate("yyyy")
        }
    }
    
    var dateService:String?
    {
        get {
            return self[Field.date]
        }
    }
    
    var date:String?
    {
        get {
            if let range = self[Field.date]?.range(of: Constants.SINGLE_SPACE) {
                if let stringSubSequence = self[Field.date]?[..<range.lowerBound] {
                    return String(stringSubSequence) // last two characters
                }
            }

            return nil
        }
    }
    
    var service:String?
    {
        get {
            if let string = self[Field.date], let range = string.range(of: Constants.SINGLE_SPACE) {
                return String(string[range.upperBound...]) // last two characters
            } else {
                return nil
            }
        }
    }
    
    var title:String?
    {
        get {
            return self[Field.title]
        }
    }
    
    var category:String?
    {
        get {
            return self[Field.category]
        }
    }
    
    var scriptureReference:String?
    {
        get {
            return self[Field.scripture]?.replacingOccurrences(of: "Psalm ", with: "Psalms ")
        }
    }
    
    var classSectionSort:String!
    {
        get {
            return classSection.lowercased()
        }
    }
    
    var classSection:String!
    {
        get {
            return hasClassName ? className! : Constants.None
        }
    }
    
    var className:String?
    {
        get {
            return self[Field.className]
        }
    }
    
    var eventSectionSort:String!
    {
        get {
            return eventSection.lowercased()
        }
    }
    
    var eventSection:String!
    {
        get {
            return eventName ?? Constants.None
        }
    }
    
    var eventName:String?
    {
        get {
            return self[Field.eventName]
        }
    }
    
    var speakerSectionSort:String!
    {
        get {
            return speakerSort?.lowercased() ?? "ERROR"
        }
    }
    
    var speakerSection:String!
    {
        get {
            return speaker ?? Constants.None
        }
    }
    
    var speaker:String?
    {
        get {
            return self[Field.speaker]
        }
    }
    
    // this saves calculated values in defaults between sessions
    var speakerSort:String?
    {
        get {
            if self[Field.speaker_sort] == nil {
                if let speakerSort = mediaItemSettings?[Field.speaker_sort] {
                    self[Field.speaker_sort] = speakerSort
                } else {
                    //Sort on last names.  This assumes the speaker names are all fo the form "... <last name>" with one or more spaces before the last name and no spaces IN the last name, e.g. "Van Winkle"

                    var speakerSort:String?
                    
                    if hasSpeaker, let speaker = speaker {
                        if !speaker.contains("Ministry Panel") {
                            if let lastName = speaker.lastName {
                                speakerSort = lastName
                            }
                            if let firstName = speaker.firstName {
                                speakerSort = ((speakerSort != nil) ? speakerSort! + "," : "") + firstName
                            }
                        } else {
                            speakerSort = speaker
                        }
                    }
                        
                    self[Field.speaker_sort] = speakerSort ?? Constants.None
                }
            }

            return self[Field.speaker_sort]
        }
    }
    
    var multiPartSectionSort:String!
    {
        get {
            if hasMultipleParts, let multiPartSort = multiPartSort {
                return multiPartSort.lowercased()
            } else {
                if let title = title?.withoutPrefixes.lowercased() {
                    return title
                }
            }

            return "ERROR"
        }
    }
    
    var multiPartSection:String!
    {
        get {
            return hasMultipleParts ? multiPartName! : (title ?? Constants.Individual_Media)
        }
    }
    
    var multiPartSort:String?
    {
        get {
            if self[Field.multi_part_name_sort] == nil {
                if let multiPartSort = mediaItemSettings?[Field.multi_part_name_sort] {
                    self[Field.multi_part_name_sort] = multiPartSort
                } else {
                    if let multiPartSort = multiPartName?.withoutPrefixes {
                        self[Field.multi_part_name_sort] = multiPartSort
                    } else {

                    }
                }
            }
            return self[Field.multi_part_name_sort]
        }
    }
    
    var multiPartName:String?
    {
        get {
            if (self[Field.multi_part_name] == nil) {
                if let range = title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
                    if let stringSubSequence = title?[..<range.lowerBound] {
                        let seriesString = String(stringSubSequence).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        
                        self[Field.multi_part_name] = seriesString
                    }
                }
            }
            
            return self[Field.multi_part_name]
        }
    }
    
    var part:String?
    {
        get {
            if hasMultipleParts && (self[Field.part] == nil) {
                if let title = title, let range = title.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
                    let partString = String(title[range.upperBound...])
                    
                    if let range = partString.range(of: ")") {
                        self[Field.part] = String(partString[..<range.lowerBound])
                    }
                }
            }
            
            return self[Field.part]
        }
    }
    
    func proposedTags(_ tags:String?) -> String?
    {
        var possibleTags = [String:Int]()
        
        if let tags = tags?.tagsArray {
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
        return proposedTags.count > 0 ? proposedTags.tagsString : nil
    }
    
    var dynamicTags:String?
    {
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
    var tags:String?
    {
        get {
            let jsonTags = self[Field.tags]
            
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
        
        let tags = mediaItemSettings?[Field.tags]?.tagsArray
        
        if tags?.firstIndex(of: tag) == nil {
            if let tags = mediaItemSettings?[Field.tags] {
                mediaItemSettings?[Field.tags] = tags + Constants.TAGS_SEPARATOR + tag
            } else {
                if (mediaItemSettings?[Field.tags] == nil) {
                    mediaItemSettings?[Field.tags] = tag
                }
            }
            
            let sortTag = tag.withoutPrefixes
            
            if !sortTag.isEmpty {
                if Globals.shared.media.all?.tagMediaItems?[sortTag] != nil {
                    if Globals.shared.media.all?.tagMediaItems?[sortTag]?.firstIndex(of: self) == nil {
                        Globals.shared.media.all?.tagMediaItems?[sortTag]?.append(self)
                        Globals.shared.media.all?.tagNames?[sortTag] = tag
                    }
                } else {
                    Globals.shared.media.all?.tagMediaItems?[sortTag] = [self]
                    Globals.shared.media.all?.tagNames?[sortTag] = tag
                }
                
                if Globals.shared.media.tags.selected == tag, let selected = Globals.shared.media.tags.selected {
                    Globals.shared.media.tagged[selected] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[sortTag])
                    
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
        
        guard Globals.shared.media.all != nil else {
            return
        }
        
        var tags = mediaItemSettings?[Field.tags]?.tagsArray
        
        while let index = tags?.firstIndex(of: tag) {
            tags?.remove(at: index)
        }
        
        mediaItemSettings?[Field.tags] = tags?.tagsString
        
        let sortTag = tag.withoutPrefixes
        
        if !sortTag.isEmpty {
            if let index = Globals.shared.media.all?.tagMediaItems?[sortTag]?.firstIndex(of: self) {
                Globals.shared.media.all?.tagMediaItems?[sortTag]?.remove(at: index)
            }
            
            if Globals.shared.media.all?.tagMediaItems?[sortTag]?.count == 0 {
                _ = Globals.shared.media.all?.tagMediaItems?.removeValue(forKey: sortTag)
            }
            
            if Globals.shared.media.tags.selected == tag {
                Globals.shared.media.tagged[tag] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[sortTag])
                
                Thread.onMainThread { () -> (Void) in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
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
    
    var tagsSet:Set<String>?
    {
        get {
            return tagsToSet(self.tags)
        }
    }
    
    var tagsArray:[String]?
    {
        get {
            guard let tagsSet = tagsSet else {
                return nil
            }

            return Array(tagsSet).sorted() {
                return $0 < $1
            }
        }
    }
    
    var audio:String?
    {
        get {
            if self[Field.audio] == nil, hasAudio, let year = year, let id = id {
                self[Field.audio] = Constants.BASE_URL.MEDIA + "\(year)/\(id)" + Constants.FILENAME_EXTENSION.MP3
            }
            
            return self[Field.audio]
        }
    }
    
    var mp4:String?
    {
        get {
            return self[Field.mp4]
        }
    }
    
    var m3u8:String?
    {
        get {
            return self[Field.m3u8]
        }
    }
    
    var video:String?
    {
        get {
            return m3u8
        }
    }
    
    var videoID:String?
    {
        get {
            guard let video = video else {
                return nil
            }
            
            guard video.contains(Constants.BASE_URL.VIDEO_PREFIX) else {
                return nil
            }
            
            let tail = String(video[Constants.BASE_URL.VIDEO_PREFIX.endIndex...])
            
            if let range = tail.range(of: ".m") {
                let id = String(tail[..<range.lowerBound])
                return id
            } else {
                return nil
            }
        }
    }
    
    var externalVideo:String?
    {
        get {
            guard let videoID = videoID else {
                return nil
            }
            
            return Constants.BASE_URL.EXTERNAL_VIDEO_PREFIX + videoID
        }
    }
    
    // A=Audio, V=Video, O=Outline, S=Slides, T=Transcript, H=HTML Transcript

    var files:String?
    {
        get {
            return self[Field.files]
        }
    }
    
    var hasAudio:Bool
    {
        get {
            if let contains = files?.contains("A") {
                return contains
            } else {
                return false
            }
        }
    }
    
    var hasVideo:Bool
    {
        get {
            if let contains = files?.contains("V") {
                return contains
            } else {
                return false
            }
        }
    }
    
    var audioURL:URL?
    {
        get {
            guard let audio = audio else {
                return nil
            }
            
            return URL(string: audio)
        }
    }
    
    var videoURL:URL?
    {
        get {
            guard let video = video else {
                return nil
            }
            
            return URL(string: video)
        }
    }
    
    var hasSlides:Bool
    {
        get {
            if let contains = files?.contains("S") {
                return contains
            } else {
                return false
            }
        }
    }
    
    var hasNotes:Bool
    {
        get {
            if let contains = files?.contains("T") {
                return contains
            } else {
                return false
            }
        }
    }

    var notes:String?
    {
        get {
            if (self[Field.notes] == nil), hasNotes, let year = year, let id = id {
                self[Field.notes] = Constants.BASE_URL.MEDIA + "\(year)/\(id)" + Field.notes + Constants.FILENAME_EXTENSION.PDF
            }
            
            return self[Field.notes]
        }
    }

    var slides:String?
    {
        get {
            if (self[Field.slides] == nil) && hasSlides, let year = year, let id = id {
                self[Field.slides] = Constants.BASE_URL.MEDIA + "\(year)/\(id)" + Field.slides + Constants.FILENAME_EXTENSION.PDF
            }
            
            return self[Field.slides]
        }
    }

    var notesURL:URL?
    {
        get {
            if let notes = notes {
                return URL(string: notes)
            } else {
                return nil
            }
        }
    }
    
    var slidesURL:URL?
    {
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

    var books:[String]?
    {
        get {
            return scriptureReference?.books
        }
    } //Derived from scripture
    
    lazy var fullDate:Date? = { [weak self] in
        if self?.hasDate == true, let date = self?.date {
            return Date(dateString:date)
        } else {
            return nil
        }
    }() //Derived from date
    
    var text : String?
    {
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
    
    override var description : String
    {
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
    
    lazy var mediaItemSettings:MediaItemSettings? = { [weak self] in
        return MediaItemSettings(mediaItem:self)
    }()
        
    lazy var multiPartSettings:MultiPartSettings? = { [weak self] in
        return MultiPartSettings(mediaItem:self)
    }()
    
    var viewSplit:String?
    {
        get {
            return multiPartSettings?[Constants.VIEW_SPLIT]
        }
        set {
            multiPartSettings?[Constants.VIEW_SPLIT] = newValue
        }
    }
    
    var slideSplit:String?
    {
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
