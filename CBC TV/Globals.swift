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

class Display {
    var mediaItems:[MediaItem]?
    var section = Section()
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
            
            if let mediaCategory = mediaCategory.selected, !mediaCategory.isEmpty {
                string = mediaCategory
                
                if let tag = media.tags.selected, string != nil {
                    string = string! + ", " + tag
                }
                
                if search.valid, let search = search.text, string != nil {
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
        return search.text
    }
    
    var contextString:String? {
        get {
            var string:String?
            
            if let mediaCategory = mediaCategory.selected {
                string = mediaCategory
                
                if let tag = media.tags.selected {
                    string = ((string != nil) ? string! + ":" : "") + tag
                }
                
                if search.valid, let search = search.text {
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
            
            if let sorting = sorting {
                string = ((string != nil) ? string! + ":" : "") + sorting
            }
            
            if let grouping = grouping {
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
    
    var streaming = Streaming()
    
    // These are hidden behind custom accessors in MediaItem
    // May want to put into a struct Settings w/ multiPart an mediaItem as vars
    var multiPartSettings:[String:[String:String]]?
    var mediaItemSettings:[String:[String:String]]?
    
    var history:[String]?
    
    var relevantHistory:[String]? {
        get {
            return history?.reversed().filter({ (string:String) -> Bool in
                if let range = string.range(of: Constants.TAGS_SEPARATOR) {
                    let mediaItemID = String(string[range.upperBound...])
                    return mediaRepository.index?[mediaItemID] != nil
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
                        
                        if let mediaItem = mediaRepository.index?[mediaItemID] {
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
            
            // Should be an opQueue
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

            defaults.set(mediaItemSettings,forKey: Constants.SETTINGS.KEY.MEDIA)

            defaults.set(multiPartSettings, forKey: Constants.SETTINGS.KEY.MULTI_PART_MEDIA)
            defaults.synchronize()
        }
    }
    
    func clearSettings()
    {
        let defaults = UserDefaults.standard

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
                    mediaItemSettings = mediaItemSettingsDictionary as? [String:[String:String]]
                }
                
                if let seriesSettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.MULTI_PART_MEDIA) {
                    multiPartSettings = seriesSettingsDictionary as? [String:[String:String]]
                }
                
                if let categorySettingsDictionary = defaults.dictionary(forKey: Constants.SETTINGS.KEY.CATEGORY) {
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

                if (media.tags.selected == Constants.New) {
                    media.tags.selected = nil
                }

                if let tag = mediaCategory.tag {
                    if media.tags.showing == Constants.TAGGED, media.tagged[tag] == nil {
                        if media.all == nil {
                            //This is filtering, i.e. searching all mediaItems => s/b in background
                            media.tagged[tag] = MediaListGroupSort(mediaItems: mediaItemsWithTag(mediaRepository.list, tag: media.tags.selected))
                        } else {
                            if let tag = media.tags.selected?.withoutPrefixes {
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

