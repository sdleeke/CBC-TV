//
//  Globals.swift
//  CBC
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit

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

struct MediaNeed {
    var sorting:Bool = true
    var grouping:Bool = true
}

class Display {
    var mediaItems:[MediaItem]?
    var section = Section()
}

class MediaRepository {
    var list:[MediaItem]? { //Not in any specific order
        willSet {
            
        }
        didSet {
            index = nil
            classes = nil
            events = nil
            
            guard let list = list else {
                return
            }
            
            for mediaItem in list {
                if let id = mediaItem.id {
                    if index == nil {
                        index = [String:MediaItem]()
                    }
                    if index?[id] == nil {
                        index?[id] = mediaItem
                    } else {
                        print("DUPLICATE MEDIAITEM ID: \(mediaItem)")
                    }
                }
                
                if let className = mediaItem.className {
                    if classes == nil {
                        classes = [className]
                    } else {
                        classes?.append(className)
                    }
                }
                
                if let eventName = mediaItem.eventName {
                    if events == nil {
                        events = [eventName]
                    } else {
                        events?.append(eventName)
                    }
                }
            }
            
            Globals.shared.groupings = Constants.groupings
            Globals.shared.groupingTitles = Constants.GroupingTitles

            if classes?.count > 0 {
                Globals.shared.groupings.append(GROUPING.CLASS)
                Globals.shared.groupingTitles.append(Grouping.Class)
            }
            
            if events?.count > 0 {
                Globals.shared.groupings.append(GROUPING.EVENT)
                Globals.shared.groupingTitles.append(Grouping.Event)
            }
            
            if let grouping = Globals.shared.grouping, !Globals.shared.groupings.contains(grouping) {
                Globals.shared.grouping = GROUPING.YEAR
            }
        }
    }

    var index:[String:MediaItem]?
    var classes:[String]?
    var events:[String]?
}

class Tags {
    var showing:String? {
        get {
            return selected == nil ? Constants.ALL : Constants.TAGGED
        }
    }
    
    var selected:String? {
        get {
            return Globals.shared.mediaCategory.tag
        }
        set {
            if let newValue = newValue {
                if (Globals.shared.media.tagged[newValue] == nil) {
                    if Globals.shared.media.all == nil {
                        //This is filtering, i.e. searching all mediaItems => s/b in background
                        Globals.shared.media.tagged[newValue] = MediaListGroupSort(mediaItems: mediaItemsWithTag(Globals.shared.mediaRepository.list, tag: newValue))
                    } else {
                        if let tag = stringWithoutPrefixes(newValue) {
                            Globals.shared.media.tagged[newValue] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[tag])
                        }
                    }
                }
            } else {

            }
            
            Globals.shared.mediaCategory.tag = newValue
        }
    }
}

class Media {
    var need = MediaNeed()

    //All mediaItems
    var all:MediaListGroupSort?
    
    //The mediaItems with the selected tags, although now we only support one tag being selected
    var tagged = [String:MediaListGroupSort]()
    
    var tags = Tags()
    
    var toSearch:MediaListGroupSort? {
        get {
            guard let showing = tags.showing else {
                return nil
            }
            
            var mediaItems:MediaListGroupSort?
            
            switch showing {
            case Constants.TAGGED:
                if let selected = tags.selected {
                    mediaItems = tagged[selected]
                }
                break
                
            case Constants.ALL:
                mediaItems = all
                break
                
            default:
                break
            }
            
            return mediaItems
        }
    }
    
    var active:MediaListGroupSort? {
        get {
            guard let showing = tags.showing else {
                return nil
            }
            
            var mediaItems:MediaListGroupSort?
            
            switch showing {
            case Constants.TAGGED:
                if let selected = tags.selected {
                    mediaItems = tagged[selected]
                }
                break
                
            case Constants.ALL:
                mediaItems = all
                break
                
            default:
                break
            }
            
            if Globals.shared.search.active {
                if let searchText = Globals.shared.search.text?.uppercased() {
                    mediaItems = mediaItems?.searches?[searchText] 
                }
            }
            
            return mediaItems
        }
    }
}

class MediaCategory {
    var dicts:[String:String]?
    
    var filename:String? {
        get {
            guard let selectedID = selectedID else {
                return nil
            }

            return Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES + selectedID +  Constants.JSON.FILENAME_EXTENSION
        }
    }
    
    var names:[String]? {
        get {
            guard let keys = dicts?.keys else {
                return nil
            }

            return [String](keys).sorted()
            
//            return dicts?.keys.map({ (key:String) -> String in
//                return key
//            }).sorted()
        }
    }
    
    // This doesn't work if we someday allow multiple categories to be selected at the same time - unless the string contains multiple categories, as with tags.
    // In that case it would need to be an array.  Not a big deal, just a change.
    var selected:String? {
        get {
            if UserDefaults.standard.object(forKey: Constants.MEDIA_CATEGORY) == nil {
                UserDefaults.standard.set(Constants.Strings.Sermons, forKey: Constants.MEDIA_CATEGORY)
            }
            
            return UserDefaults.standard.string(forKey: Constants.MEDIA_CATEGORY)
        }
        set {
            if selected != nil {
                UserDefaults.standard.set(newValue, forKey: Constants.MEDIA_CATEGORY)
            } else {
                UserDefaults.standard.removeObject(forKey: Constants.MEDIA_CATEGORY)
            }
            
            UserDefaults.standard.synchronize()
        }
    }
    
    var selectedID:String? {
        get {
            guard let selected = selected, dicts?[selected] != nil else {
                return "1"
            }
            
            return dicts?[selected]
        }
    }

    var settings:[String:[String:String]]?

    var allowSaveSettings = true
    
    func saveSettingsBackground()
    {
        if allowSaveSettings {
            print("saveSettingsBackground")
            
            DispatchQueue.global(qos: .background).async {
                self.saveSettings()
            }
        }
    }
    
    func saveSettings()
    {
        if allowSaveSettings {
            print("saveSettings")
            let defaults = UserDefaults.standard
            defaults.set(settings, forKey: Constants.SETTINGS.KEY.CATEGORY)
            defaults.synchronize()
        }
    }
    
    subscript(key:String) -> String? {
        get {
            if let selected = selected {
                return settings?[selected]?[key]
            } else {
                return nil
            }
        }
        set {
            guard let selected = selected else {
                print("selected == nil!")
                return
            }

            if settings == nil {
                settings = [String:[String:String]]()
            }
            
            guard (settings != nil) else {
                print("settings == nil!")
                return
            }

            if (settings?[selected] == nil) {
                settings?[selected] = [String:String]()
            }
            if (settings?[selected]?[key] != newValue) {
                settings?[selected]?[key] = newValue

                // For a high volume of activity this can be very expensive.
                saveSettingsBackground()
            }
        }
    }
    
    var tag:String? {
        get {
            return self[Constants.SETTINGS.KEY.COLLECTION]
        }
        set {
            self[Constants.SETTINGS.KEY.COLLECTION] = newValue
        }
    }
    
    var playing:String? {
        get {
            return self[Constants.SETTINGS.MEDIA_PLAYING]
        }
        set {
            self[Constants.SETTINGS.MEDIA_PLAYING] = newValue
        }
    }

    var selectedInMaster:String? {
        get {
            return self[Constants.SETTINGS.KEY.SELECTED_MEDIA.MASTER]
        }
        set {
            self[Constants.SETTINGS.KEY.SELECTED_MEDIA.MASTER] = newValue
        }
    }
    
    var selectedInDetail:String? {
        get {
            return self[Constants.SETTINGS.KEY.SELECTED_MEDIA.DETAIL]
        }
        set {
            self[Constants.SETTINGS.KEY.SELECTED_MEDIA.DETAIL] = newValue
        }
    }
}

class SelectedMediaItem {
    var master:MediaItem? {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = Globals.shared.mediaCategory.selectedInMaster {
                selectedMediaItem = Globals.shared.mediaRepository.index?[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        
        set {
            Globals.shared.mediaCategory.selectedInMaster = newValue?.id
        }
    }
    
    var detail:MediaItem? {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = Globals.shared.mediaCategory.selectedInDetail {
                selectedMediaItem = Globals.shared.mediaRepository.index?[selectedMediaItemID]
            }

            return selectedMediaItem
        }
        
        set {
            Globals.shared.mediaCategory.selectedInDetail = newValue?.id
        }
    }
}

class Search {
    var complete:Bool = true

    var active:Bool = false {
        willSet {
            
        }
        didSet {
            if !active {
                complete = true
            }
        }
    }
    
    var valid:Bool {
        get {
            return active && extant
        }
    }
    
    var extant:Bool {
        get {
            return (text != nil) && (text != Constants.EMPTY_STRING)
        }
    }
    
    var text:String? {
        willSet {
            
        }
        didSet {
            if (text != oldValue) && !Globals.shared.isLoading {
                if extant {
                    UserDefaults.standard.set(text, forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                } else {
                    UserDefaults.standard.removeObject(forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    var transcripts:Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.USER_SETTINGS.SEARCH_TRANSCRIPTS)
        }
        set {
            // Setting to nil can cause a crash.
            Globals.shared.media.toSearch?.searches = [String:MediaListGroupSort]()
            
            UserDefaults.standard.set(newValue, forKey: Constants.USER_SETTINGS.SEARCH_TRANSCRIPTS)
            UserDefaults.standard.synchronize()
        }
    }
}

//var globals:Globals!

class StreamEntry {
    init?(_ dict:[String:Any]?)
    {
        guard dict != nil else {
            return nil
        }
        
        self.dict = dict
    }
    
    var dict : [String:Any]?
    
    var id : Int? {
        get {
            return dict?["id"] as? Int
        }
    }
    
    var start : Int? {
        get {
            return dict?["start"] as? Int
        }
    }
    
    var startDate : Date? {
        get {
            if let start = start {
                return Date(timeIntervalSince1970: TimeInterval(start))
            } else {
                return nil
            }
        }
    }
    
    var end : Int? {
        get {
            return dict?["end"] as? Int
        }
    }
    
    var endDate : Date? {
        get {
            if let end = end {
                return Date(timeIntervalSince1970: TimeInterval(end))
            } else {
                return nil
            }
        }
    }
    
    var name : String? {
        get {
            return dict?["name"] as? String
        }
    }
    
    var date : String? {
        get {
            return dict?["date"] as? String
        }
    }
    
    var text : String? {
        get {
            if let name = name,let startDate = startDate?.mdyhm,let endDate = endDate?.mdyhm {
                return "\(name)\nStart: \(startDate)\nEnd: \(endDate)"
            } else {
                return nil
            }
        }
    }
}

class Globals : NSObject, AVPlayerViewControllerDelegate
{
    static var shared = Globals()
    
    var popoverNavCon: UINavigationController?

    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool
    {
        return true
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void)
    {
        completionHandler(true)
    }
    
    var loadSingles = true
    
    var allowSaveSettings = true
    
    let reachability = Reachability()!
    
    override init()
    {
        super.init()
        
        reachability.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            Thread.onMainThread { () -> (Void) in
                if reachability.isReachableViaWiFi {
                    print("Reachable via WiFi")
                } else {
                    print("Reachable via Cellular")
                }
            }
        }
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            Thread.onMainThread { () -> (Void) in
                print("Not reachable")
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            print("Unable to start notifier")
        }
    }

    var groupings = Constants.groupings
    var groupingTitles = Constants.GroupingTitles
    
    var grouping:String? = GROUPING.YEAR {
        willSet {
            
        }
        didSet {
            media.need.grouping = (grouping != oldValue)
            
            let defaults = UserDefaults.standard
            if (grouping != nil) {
                defaults.set(grouping,forKey: Constants.SETTINGS.KEY.GROUPING)
            } else {
                //Should not happen
                defaults.removeObject(forKey: Constants.SETTINGS.KEY.GROUPING)
            }
            defaults.synchronize()
        }
    }
    
    var sorting:String? = SORTING.REVERSE_CHRONOLOGICAL {
        willSet {
            
        }
        didSet {
            media.need.sorting = (sorting != oldValue)
            
            let defaults = UserDefaults.standard
            if (sorting != nil) {
                defaults.set(sorting,forKey: Constants.SETTINGS.KEY.SORTING)
            } else {
                //Should not happen
                defaults.removeObject(forKey: Constants.SETTINGS.KEY.SORTING)
            }
            defaults.synchronize()
        }
    }
    
    var autoAdvance:Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.USER_SETTINGS.AUTO_ADVANCE)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.USER_SETTINGS.AUTO_ADVANCE)
            UserDefaults.standard.synchronize()
        }
    }
    
    var cacheDownloads:Bool {
        get {
            if UserDefaults.standard.object(forKey: Constants.USER_SETTINGS.CACHE_DOWNLOADS) == nil {
                if #available(iOS 9.0, *) {
                    UserDefaults.standard.set(true, forKey: Constants.USER_SETTINGS.CACHE_DOWNLOADS)
                } else {
                    UserDefaults.standard.set(false, forKey: Constants.USER_SETTINGS.CACHE_DOWNLOADS)
                }
            }
            
            return UserDefaults.standard.bool(forKey: Constants.USER_SETTINGS.CACHE_DOWNLOADS)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.USER_SETTINGS.CACHE_DOWNLOADS)
            UserDefaults.standard.synchronize()
        }
    }
    
    var isLoading:Bool      = false
    var isSorting:Bool      = false
    var isGrouping:Bool     = false

    var search = Search()
    
    var contextTitle:String? {
        get {
            var string:String?
            
            if let mediaCategory = Globals.shared.mediaCategory.selected, !mediaCategory.isEmpty {
                string = mediaCategory
                
                if let tag = Globals.shared.media.tags.selected, string != nil {
                    string = string! + ", " + tag
                }
                
                if Globals.shared.search.valid, let search = Globals.shared.search.text, string != nil {
                    string = string! + ", \"\(search)\""
                }
            }
            
            return string
        }
    }
    
    func context() -> String? {
        return contextString
    }
    
    func searchText() -> String? {
        return Globals.shared.search.text
    }
    
    var contextString:String? {
        get {
            var string:String?
            
            if let mediaCategory = Globals.shared.mediaCategory.selected {
                string = mediaCategory
                
                if let tag = Globals.shared.media.tags.selected {
                    string = ((string != nil) ? string! + ":" : "") + tag
                }
                
                if Globals.shared.search.valid, let search = Globals.shared.search.text {
                    string = ((string != nil) ? string! + ":" : "") + search
                }
            }
            
            return string
        }
    }

    func contextOrder() -> String? {
        var string:String?
        
        if let context = contextString {
            string = ((string != nil) ? string! + ":" : "") + context
        }
        
        if let order = orderString {
            string = ((string != nil) ? string! + ":" : "") + order
        }
        
        return string
    }

    var orderString:String? {
        get {
            var string:String?
            
            if let sorting = Globals.shared.sorting {
                string = ((string != nil) ? string! + ":" : "") + sorting
            }
            
            if let grouping = Globals.shared.grouping {
                string = ((string != nil) ? string! + ":" : "") + grouping
            }
            
            return string
        }
    }
    
    var gotoPlayingPaused:Bool = false
    var showingAbout:Bool = false

    var mediaPlayer = MediaPlayer()

    var selectedMediaItem = SelectedMediaItem()
    
    var mediaCategory = MediaCategory()
    
    var streamEntries:[[String:Any]]?
    
    var streamStrings:[String]?
    {
        get {
            return streamEntries?.filter({ (dict:[String : Any]) -> Bool in
                return StreamEntry(dict)?.startDate > Date()
            }).map({ (dict:[String : Any]) -> String in
                if let string = StreamEntry(dict)?.text {
                    return string
                } else {
                    return "ERROR"
                }
            })
        }
    }
    
    var streamStringIndex:[String:[String]]?
    {
        get {
            var streamStringIndex = [String:[String]]()
            
            let now = Date().addHours(0) // For convenience in testing.
            
            if let streamEntries = streamEntries {
                for event in streamEntries {
                    let streamEntry = StreamEntry(event)
                    
                    if let start = streamEntry?.start, let end = streamEntry?.end, let text = streamEntry?.text {
                        // All streaming to start 10 minutes before and end 10 minutes after  the scheduled start time
                        if ((now.timeIntervalSince1970 + 10*60) >= Double(start)) && ((now.timeIntervalSince1970 - 10*60) <= Double(end)) {
                            if streamStringIndex["Playing"] == nil {
                                streamStringIndex["Playing"] = [String]()
                            }
                            streamStringIndex["Playing"]?.append(text)
                        } else {
                            if (now < streamEntry?.startDate) {
                                if streamStringIndex["Upcoming"] == nil {
                                    streamStringIndex["Upcoming"] = [String]()
                                }
                                streamStringIndex["Upcoming"]?.append(text)
                            }
                        }
                    }
                }
                
                if streamStringIndex["Playing"]?.count == 0 {
                    streamStringIndex["Playing"] = nil
                }
                
                return streamStringIndex.count > 0 ? streamStringIndex : nil
            } else {
                return nil
            }
        }
    }
    
    var streamEntryIndex:[String:[[String:Any]]]?
    {
        get {
            var streamEntryIndex = [String:[[String:Any]]]()
            
            let now = Date().addHours(0) // For convenience in testing.
            
            if let streamEntries = streamEntries {
                for event in streamEntries {
                    let streamEntry = StreamEntry(event)
                    
                    if let start = streamEntry?.start, let end = streamEntry?.end {
                        // All streaming to start 10 minutes before and end 10 minutes after the scheduled start time
                        if ((now.timeIntervalSince1970 + 10*60) >= Double(start)) && ((now.timeIntervalSince1970 - 10*60) <= Double(end)) {
                            if streamEntryIndex["Playing"] == nil {
                                streamEntryIndex["Playing"] = [[String:Any]]()
                            }
                            streamEntryIndex["Playing"]?.append(event)
                        } else {
                            if (now < streamEntry?.startDate) {
                                if streamEntryIndex["Upcoming"] == nil {
                                    streamEntryIndex["Upcoming"] = [[String:Any]]()
                                }
                                streamEntryIndex["Upcoming"]?.append(event)
                            }
                        }
                    }
                }
                
                if streamEntryIndex["Playing"]?.count == 0 {
                    streamEntryIndex["Playing"] = nil
                }
                
                return streamEntryIndex.count > 0 ? streamEntryIndex : nil
            } else {
                return nil
            }
        }
    }
    
    // Assumes there is ONLY one event streaming at a time.
    //    var streamNow:[String:Any]?
    //    {
    //        get {
    //            let now = Date() // .addHours(-21)
    //
    //            if let events = streamSchedule?[now.year]?[now.month]?[now.day] {
    //                for event in events {
    //                    let streamEntry = StreamEntry(event)
    //
    //                    if let start = streamEntry?.start {
    //                        // All streaming to start 5 minutes before the scheduled start time
    //                        if ((now.timeIntervalSince1970 + 5*60) >= Double(start)) && (now <= streamEntry?.endDate) {
    //                            return event
    //                        }
    //                    }
    //                }
    //            }
    //
    //            return nil // streamEntries?.first
    //        }
    //    }
    
    var streamSorted:[[String:Any]]?
    {
        get {
            return streamEntries?.sorted(by: { (firstDict: [String : Any], secondDict: [String : Any]) -> Bool in
                return StreamEntry(firstDict)?.startDate <= StreamEntry(secondDict)?.startDate
            })
        }
    }
    
    var streamCategories:[String:[[String:Any]]]?
    {
        get {
            var streamCategories = [String:[[String:Any]]]()
            
            if let streamEntries = streamEntries {
                for streamEntry in streamEntries {
                    if let name = StreamEntry(streamEntry)?.name {
                        if streamCategories[name] == nil {
                            streamCategories[name] = [[String:Any]]()
                        }
                        streamCategories[name]?.append(streamEntry)
                    }
                }
                
                return streamCategories.count > 0 ? streamCategories : nil
            } else {
                return nil
            }
        }
    }
    // Year // Month // Day // Event
    var streamSchedule:[String:[String:[String:[[String:Any]]]]]?
    {
        get {
            var streamSchedule = [String:[String:[String:[[String:Any]]]]]()
            
            if let streamEntries = streamEntries {
                for streamEntry in streamEntries {
                    if let startDate = StreamEntry(streamEntry)?.startDate {
                        if streamSchedule[startDate.year] == nil {
                            streamSchedule[startDate.year] = [String:[String:[[String:Any]]]]()
                        }
                        if streamSchedule[startDate.year]?[startDate.month] == nil {
                            streamSchedule[startDate.year]?[startDate.month] = [String:[[String:Any]]]()
                        }
                        if streamSchedule[startDate.year]?[startDate.month]?[startDate.day] == nil {
                            streamSchedule[startDate.year]?[startDate.month]?[startDate.day] = [[String:Any]]()
                        }
                        streamSchedule[startDate.year]?[startDate.month]?[startDate.day]?.append(streamEntry)
                    }
                }
                
                return streamSchedule.count > 0 ? streamSchedule : nil
            } else {
                return nil
            }
        }
    }
    
    // These are hidden behind custom accessors in MediaItem
    // May want to put into a struct Settings w/ multiPart an mediaItem as vars
    var multiPartSettings:[String:[String:String]]?
    var mediaItemSettings:[String:[String:String]]?
    
    var history:[String]?
    
    var relevantHistory:[String]? {
        get {
            return Globals.shared.history?.reversed().filter({ (string:String) -> Bool in
                if let range = string.range(of: Constants.TAGS_SEPARATOR) {
                    let mediaItemID = String(string[range.upperBound...])
                    return Globals.shared.mediaRepository.index?[mediaItemID] != nil
                } else {
                    return false
                }
            })
        }
    }
    
    var relevantHistoryList:[String]? {
        get {
            var list = [String]()
            
            if let historyList = relevantHistory {
                for history in historyList {
                    var mediaItemID:String
                    
                    if let range = history.range(of: Constants.TAGS_SEPARATOR) {
                        mediaItemID = String(history[range.upperBound...])
                        
                        if let mediaItem = Globals.shared.mediaRepository.index?[mediaItemID] {
                            if let text = mediaItem.text {
                                list.append(text)
                            } else {
                                print(mediaItem.text as Any)
                            }
                        } else {
                            print(mediaItemID)
                        }
                    } else {
                        print("no range")
                    }
                }
            } else {
                print("no historyList")
            }
            
            return list.count > 0 ? list : nil
        }
    }

    var mediaRepository = MediaRepository()
    
    var media = Media()
    
    var display = Display()
    
    func freeMemory()
    {
        // Free memory in classes
        Thread.onMainThread { () -> (Void) in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }

        URLCache.shared.removeAllCachedResponses()
    }
    
    func clearDisplay()
    {
        display.mediaItems = nil

        display.section.headerStrings = nil
        display.section.indexStrings = nil
        display.section.indexes = nil
        display.section.counts = nil
    }
    
    func setupDisplay(_ active:MediaListGroupSort?)
    {
//        print("setupDisplay")

        display.mediaItems = active?.mediaItems
        
        display.section.showHeaders = true
        
        display.section.headerStrings = active?.section?.headerStrings
        display.section.indexStrings = active?.section?.indexStrings
        display.section.indexes = active?.section?.indexes
        display.section.counts = active?.section?.counts
    }
    
    func saveSettingsBackground()
    {
        if allowSaveSettings {
            print("saveSettingsBackground")
            
            DispatchQueue.global(qos: .background).async {
                self.saveSettings()
            }
        }
    }
    
    func saveSettings()
    {
        if allowSaveSettings {
            print("saveSettings")
            let defaults = UserDefaults.standard
            //    print("\(settings)")
            defaults.set(mediaItemSettings,forKey: Constants.SETTINGS.KEY.MEDIA)
            //    print("\(seriesViewSplits)")
            defaults.set(multiPartSettings, forKey: Constants.SETTINGS.KEY.MULTI_PART_MEDIA)
            defaults.synchronize()
        }
    }
    
    func clearSettings()
    {
        let defaults = UserDefaults.standard
        //    print("\(settings)")
        defaults.removeObject(forKey: Constants.SETTINGS.KEY.MEDIA)
        defaults.removeObject(forKey: Constants.SETTINGS.KEY.MULTI_PART_MEDIA)
        defaults.removeObject(forKey: Constants.SETTINGS.KEY.CATEGORY)
        defaults.synchronize()
    }
    
    func loadSettings()
    {
        let defaults = UserDefaults.standard
        
        if let settingsVersion = defaults.string(forKey: Constants.SETTINGS.VERSION.KEY) {
            if settingsVersion == Constants.SETTINGS.VERSION.NUMBER {
                if let mediaItemSettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.MEDIA) {
                    //        print("\(settingsDictionary)")
                    mediaItemSettings = mediaItemSettingsDictionary as? [String:[String:String]]
                }
                
                if let seriesSettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.MULTI_PART_MEDIA) {
                    //        print("\(viewSplitsDictionary)")
                    multiPartSettings = seriesSettingsDictionary as? [String:[String:String]]
                }
                
                if let categorySettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.CATEGORY) {
                    //        print("\(viewSplitsDictionary)")
                    mediaCategory.settings = categorySettingsDictionary as? [String:[String:String]]
                }
                
                if let sortingString = defaults.string(forKey: Constants.SETTINGS.KEY.SORTING) {
                    sorting = sortingString
                } else {
                    sorting = SORTING.REVERSE_CHRONOLOGICAL
                }
                
                if let groupingString = defaults.string(forKey: Constants.SETTINGS.KEY.GROUPING) {
                    grouping = groupingString
                } else {
                    grouping = GROUPING.YEAR
                }
                
//                media.tags.selected = mediaCategory.tag

                if (media.tags.selected == Constants.New) {
                    media.tags.selected = nil
                }

                if let tag = mediaCategory.tag {
                    if media.tags.showing == Constants.TAGGED, media.tagged[tag] == nil {
                        if media.all == nil {
                            //This is filtering, i.e. searching all mediaItems => s/b in background
                            media.tagged[tag] = MediaListGroupSort(mediaItems: mediaItemsWithTag(mediaRepository.list, tag: media.tags.selected))
                        } else {
                            if let tag = stringWithoutPrefixes(media.tags.selected) {
                                media.tagged[tag] = MediaListGroupSort(mediaItems: media.all?.tagMediaItems?[tag])
                            }
                        }
                    }
                }
                
                search.text = defaults.string(forKey: Constants.SEARCH_TEXT) // ?.uppercased()
                search.active = search.text != nil

                if let playing = mediaCategory.playing {
                    mediaPlayer.mediaItem = mediaRepository.index?[playing]
                } else {
                    mediaPlayer.mediaItem = nil
                }

                if let historyArray = defaults.array(forKey: Constants.HISTORY) {
                    //        print("\(settingsDictionary)")
                    history = historyArray as? [String]
                }
            } else {
                //This is where we should map the old version on to the new one and preserve the user's information.
                defaults.set(Constants.SETTINGS.VERSION.NUMBER, forKey: Constants.SETTINGS.VERSION.KEY)
                defaults.synchronize()
            }
        } else {
            //This is where we should map the old version (if there is one) on to the new one and preserve the user's information.
            clearSettings()
            defaults.set(Constants.SETTINGS.VERSION.NUMBER, forKey: Constants.SETTINGS.VERSION.KEY)
            defaults.synchronize()
        }
        
        //    print("\(settings)")
    }
    
    func startAudio()
    {
        let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            print("failed to setCategory(AVAudioSessionCategoryPlayback)")
        }
        
//        do {
//            try audioSession.setActive(true)
//        } catch _ {
//            print("failed to audioSession.setActive(true)")
//        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    func stopAudio()
    {
        let audioSession: AVAudioSession  = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false)
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            print("failed to audioSession.setActive(false)")
        }
    }
    
    func addToHistory(_ mediaItem:MediaItem?)
    {
        guard let mediaItem = mediaItem else {
            print("mediaItem NIL!")
            return
        }
        
        guard let id = mediaItem.id else {
            print("mediaItem ID NIL!")
            return
        }
        
        let entry = "\(Date())" + Constants.TAGS_SEPARATOR + id

        if history == nil {
            history = [entry]
        } else {
            history?.append(entry)
        }
        
        //        print(history)
        
        let defaults = UserDefaults.standard
        defaults.set(history, forKey: Constants.HISTORY)
        defaults.synchronize()
    }

    func addAccessoryEvents()
    {
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlPlay")
            self.mediaPlayer.play()
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlPause")
            self.mediaPlayer.pause()
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlTogglePlayPause")
            if self.mediaPlayer.isPaused {
                self.mediaPlayer.play()
            } else {
                self.mediaPlayer.pause()
            }
            return MPRemoteCommandHandlerStatus.success
        })
        
        MPRemoteCommandCenter.shared().stopCommand.isEnabled = true
        MPRemoteCommandCenter.shared().stopCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlStop")
            self.mediaPlayer.pause()
            return MPRemoteCommandHandlerStatus.success
        })
        
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekBackwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        ////        self.mediaPlayer.player?.beginSeekingBackward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        //
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.enabled = true
        //    MPRemoteCommandCenter.sharedCommandCenter().seekForwardCommand.addTargetWithHandler { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
        ////        self.mediaPlayer.player?.beginSeekingForward()
        //        return MPRemoteCommandHandlerStatus.Success
        //    }
        
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlSkipBackward")
            if let seconds = self.mediaPlayer.currentTime?.seconds {
                self.mediaPlayer.seek(to: seconds - Constants.SKIP_TIME_INTERVAL)
                return MPRemoteCommandHandlerStatus.success
            } else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
        })
        
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            print("RemoteControlSkipForward")
            if let seconds = self.mediaPlayer.currentTime?.seconds {
                self.mediaPlayer.seek(to: seconds + Constants.SKIP_TIME_INTERVAL)
                return MPRemoteCommandHandlerStatus.success
            } else {
                return MPRemoteCommandHandlerStatus.commandFailed
            }
        })
        
        if #available(iOS 9.1, *) {
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
            MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget (handler: { (event:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
                print("MPChangePlaybackPositionCommand")
                if let positionTime = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime {
                    self.mediaPlayer.seek(to: positionTime)
                    return MPRemoteCommandHandlerStatus.success
                } else {
                    return MPRemoteCommandHandlerStatus.commandFailed
                }
            })
        } else {
            // Fallback on earlier versions
        }
        
        MPRemoteCommandCenter.shared().seekForwardCommand.isEnabled = false
        MPRemoteCommandCenter.shared().seekBackwardCommand.isEnabled = false
        
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = false
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = false
        
        MPRemoteCommandCenter.shared().changePlaybackRateCommand.isEnabled = false
        
        MPRemoteCommandCenter.shared().ratingCommand.isEnabled = false
        MPRemoteCommandCenter.shared().likeCommand.isEnabled = false
        MPRemoteCommandCenter.shared().dislikeCommand.isEnabled = false
        MPRemoteCommandCenter.shared().bookmarkCommand.isEnabled = false
    }
}

