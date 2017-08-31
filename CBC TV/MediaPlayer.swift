//
//  MediaPlayer.swift
//  CBC
//
//  Created by Steve Leeke on 12/14/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import Foundation
import MediaPlayer
import AVKit

enum PlayerState {
    case none
    
    case paused
    case playing
    case stopped
    
    case seekingForward
    case seekingBackward
}

class PlayerStateTime {
    var mediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            startTime = mediaItem?.currentTime
        }
    }
    
    var state:PlayerState = .none {
        willSet {
            
        }
        didSet {
            if (state != oldValue) {
                dateEntered = Date()
            }
        }
    }
    
    var startTime:String?
    
    var dateEntered:Date?
    var timeElapsed:TimeInterval {
        get {
            return Date().timeIntervalSince(dateEntered!)
        }
    }
    
    init(state: PlayerState)
    {
        dateEntered = Date()
        self.state = state
    }
    
    convenience init(state:PlayerState,mediaItem:MediaItem?)
    {
        self.init(state:state)
        self.mediaItem = mediaItem
        self.startTime = mediaItem?.currentTime
    }
    
    func log()
    {
        var stateName:String?
        
        switch state {
        case .none:
            stateName = "none"
            break
            
        case .paused:
            stateName = "paused"
            break
            
        case .playing:
            stateName = "playing"
            break
            
        case .seekingForward:
            stateName = "seekingForward"
            break
            
        case .seekingBackward:
            stateName = "seekingBackward"
            break
            
        case .stopped:
            stateName = "stopped"
            break
        }
        
        if stateName != nil {
            print(stateName!)
        }
    }
}

enum PIP {
    case started
    case stopped
}

class MediaPlayer : NSObject {
    var progressTimerReturn:Any? = nil
    var playerTimerReturn:Any? = nil
    
    var observerActive = false
    var observedItem:AVPlayerItem?
    
    var playerObserverTimer:Timer?
    
    var isZoomed = false
    
    var url : URL? {
        get {
            return (currentItem?.asset as? AVURLAsset)?.url
        }
    }
    
    var controller:AVPlayerViewController? // = AVPlayerViewController()
    
    var stateTime:PlayerStateTime?
    
    var showsPlaybackControls:Bool{
        get {
            return controller != nil ? controller!.showsPlaybackControls : false
        }
        set {
            controller?.showsPlaybackControls = newValue
        }
    }

    func updateCurrentTimeForPlaying()
    {
        assert(player != nil,"player should not be nil if we're trying to update the currentTime in userDefaults")
        
        if loaded && (duration != nil) {
            var timeNow = 0.0
            
            if (currentTime!.seconds > 0) && (currentTime!.seconds <= duration!.seconds) {
                timeNow = currentTime!.seconds
            }
            
            if ((timeNow > 0) && (Int(timeNow) % 10) == 0) {
                if Int(Float(mediaItem!.currentTime!)!) != Int(currentTime!.seconds) {
                    mediaItem?.currentTime = currentTime!.seconds.description
                }
            }
        }
    }
    
    //    private var GlobalPlayerContext = 0
    
    func setup(url:URL?,playOnLoad:Bool)
    {
        guard (url != nil) else {
            return
        }
        
        unload()
        
        unobserve()
        
        controller = AVPlayerViewController()
        
        let menuPressRecognizer = UITapGestureRecognizer(target: controller, action: #selector(AVPlayerViewController.menuButtonAction(tap:)))
        menuPressRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        controller?.view.addGestureRecognizer(menuPressRecognizer)
        
        controller?.delegate = globals
        
        controller?.showsPlaybackControls = false
        
        //        if #available(iOS 10.0, *) {
        //            controller?.updatesNowPlayingInfoCenter = false
        //        } else {
        //            // Fallback on earlier versions
        //        }
        
        //        if #available(iOS 9.0, *) {
        //            controller?.allowsPictureInPicturePlayback = true
        //        } else {
        //            // Fallback on earlier versions
        //        }
        
        // Just replacing the item will not cause a timeout when the player can't load.
        //            if player == nil {
        //                player = AVPlayer(url: url!)
        //            } else {
        //                player?.replaceCurrentItem(with: AVPlayerItem(url: url!))
        //            }
        
        player = AVPlayer(url: url!)
        
        if #available(iOS 10.0, *) {
            player?.automaticallyWaitsToMinimizeStalling = (mediaItem?.playing != Playing.audio) // || !globals.reachability.isReachableViaWiFi
        } else {
            // Fallback on earlier versions
        }
        
        player?.actionAtItemEnd = .pause
        
        observe()
        
        pause() // affects playOnLoad
        self.playOnLoad = playOnLoad
        
        MPRemoteCommandCenter.shared().playCommand.isEnabled = (player != nil) && (url != URL(string: Constants.URL.LIVE_STREAM))
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = (player != nil) && (url != URL(string: Constants.URL.LIVE_STREAM))
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = (player != nil) && (url != URL(string: Constants.URL.LIVE_STREAM))
    }
    
    func setup(_ mediaItem:MediaItem?,playOnLoad:Bool)
    {
        guard (mediaItem != nil) else {
            return
        }
        
        setup(url: mediaItem!.playingURL,playOnLoad: playOnLoad)
    }
    
    func reload()
    {
        guard (mediaItem != nil) else {
            return
        }
        
        unobserve()
        
        unload()
        
        player?.replaceCurrentItem(with: AVPlayerItem(url: url!))
        
        pause() // To reset playOnLoad and set state to .paused
        
        observe()
    }
    
    func setupPlayerAtEnd(_ mediaItem:MediaItem?)
    {
        setup(mediaItem,playOnLoad:false)
        
        if (duration != nil) {
            pause()
            seek(to: duration?.seconds)
            mediaItem?.currentTime = Float(duration!.seconds).description
            mediaItem?.atEnd = true
        }
    }

    func failedToLoad()
    {
        loadFailed = true
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_LOAD), object: nil)
        })
        
        if (UIApplication.shared.applicationState == UIApplicationState.active) {
            alert(title: "Failed to Load Content", message: "Please check your network connection and try again.")
        }
    }
    
    func failedToPlay()
    {
        loadFailed = true
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
        })
        
        if (UIApplication.shared.applicationState == UIApplicationState.active) {
            alert(title: "Unable to Play Content", message: "Please check your network connection and try again.")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?)
    {
        // Only handle observations for the playerItemContext
        //        guard context == &GlobalPlayerContext else {
        //            super.observeValue(forKeyPath: keyPath,
        //                               of: object,
        //                               change: change,
        //                               context: context)
        //            return
        //        }
        
        if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            if  let statusNumber = change?[.newKey] as? NSNumber,
                let status = AVPlayerTimeControlStatus(rawValue: statusNumber.intValue) {
                switch status {
                case .waitingToPlayAtSpecifiedRate:
                    print("KVO:waitingToPlayAtSpecifiedRate")
                    
                    if let reason = player?.reasonForWaitingToPlay {
                        print("waitingToPlayAtSpecifiedRate: ",reason)
                    } else {
                        print("waitingToPlayAtSpecifiedRate: no reason")
                    }
                    break
                    
                case .paused:
                    print("KVO:paused")
                    if let state = state {
                        switch state {
                        case .none:
                            break
                            
                        case .paused:
                            break
                            
                        case .playing:
                            pause()
                            checkDidPlayToEnd()
                            break
                            
                        case .seekingBackward:
                            //                                pause()
                            break
                            
                        case .seekingForward:
                            //                                pause()
                            break
                            
                        case .stopped:
                            break
                        }
                    } else {
                        print("WHAT???")
                    }
                    break
                    
                case .playing:
                    print("KVO:playing")
                    if let state = state {
                        switch state {
                        case .none:
                            break
                            
                        case .paused:
                            play()
                            break
                            
                        case .playing:
                            break
                            
                        case .seekingBackward:
                            //                                play()
                            break
                            
                        case .seekingForward:
                            //                                play()
                            break
                            
                        case .stopped:
                            break
                        }
                    } else {
                        print("WHAT???")
                    }
                    break
                }
            }
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                //                print(player?.currentItem?.duration.value)
                //                print(player?.currentItem?.duration.timescale)
                //                print(player?.currentItem?.duration.seconds)
                if !loaded && (mediaItem != nil) && (url != URL(string: Constants.URL.LIVE_STREAM)) {
                    loaded = true
                    
                    if (mediaItem?.playing == Playing.video) {
                        if mediaItem?.showing == Showing.none {
                            mediaItem?.showing = Showing.video
                        }
                    }
                    
                    if mediaItem!.hasCurrentTime() {
                        if mediaItem!.atEnd {
                            seek(to: duration!.seconds)
                        } else {
                            seek(to: Double(mediaItem!.currentTime!)!)
                        }
                    } else {
                        mediaItem?.currentTime = Constants.ZERO
                        seek(to: 0)
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
                    })
                }
                //
                //                if (url != nil) {
                //                    switch url!.absoluteString {
                //                    case Constants.URL.LIVE_STREAM:
                //                        setupLivePlayingInfoCenter()
                //                        break
                //
                //                    default:
                //                        setupPlayingInfoCenter()
                //                        break
                //                    }
                //                }
                
                setupPlayingInfoCenter()
                break
                
            case .failed:
                // Player item failed. See error.
                failedToLoad()
                break
                
            case .unknown:
                // Player item is not yet ready.
                if #available(iOS 10.0, *) {
                    print(player!.reasonForWaitingToPlay!)
                } else {
                    // Fallback on earlier versions
                }
                break
            }
        }
    }

    func checkDidPlayToEnd()
    {
        // didPlayToEnd observer doesn't always work.  This seemds to catch the cases where it doesn't.
        if let currentTime = currentTime?.seconds,
            let duration = duration?.seconds,
            Int(currentTime) >= Int(duration) {
            didPlayToEnd()
        }
    }
    
    @objc func didPlayToEnd()
    {
        guard let duration = duration?.seconds, let currentTime = currentTime?.seconds, currentTime >= (duration - 1) else {
            return
        }
        
        //        print("didPlayToEnd",mediaItem)
        
        //        print(currentTime?.seconds)
        //        print(duration?.seconds)
        
        pause()
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        })
        
        //        if (mediaItem != nil) && !mediaItem!.atEnd {
        //            reloadPlayer(mediaItem)
        //        }
        
        mediaItem?.atEnd = true
        
        if globals.autoAdvance, mediaItem != nil, mediaItem?.playing == Playing.audio, mediaItem!.atEnd, mediaItem?.multiPartMediaItems?.count > 1,
            let mediaItems = mediaItem?.multiPartMediaItems, let index = mediaItems.index(of: mediaItem!), index < (mediaItems.count - 1) {
            let nextMediaItem = mediaItems[index + 1]
            
            nextMediaItem.playing = Playing.audio
            nextMediaItem.currentTime = Constants.ZERO
            
            mediaItem = nextMediaItem
            
            setup(nextMediaItem,playOnLoad:true)
        } else {
            stop()
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
        })
    }
    
    @objc func playerObserver()
    {
        guard (url != URL(string:Constants.URL.LIVE_STREAM)) else {
            return
        }
        
        //        logPlayerState()
        
        guard let state = state,
            let startTime = stateTime?.startTime,
            let start = Double(startTime),
            let timeElapsed = stateTime?.timeElapsed,
            let currentTime = currentTime?.seconds else {
                return
        }
        
        print("startTime",startTime)
        print("start",start)
        print("currentTime",currentTime)
        print("timeElapsed",timeElapsed)
        
        switch state {
        case .none:
            break
            
        case .playing:
            if loaded && !loadFailed {
                // This causes too many problems if it fires at the wrong time during skip forwar or backward.
                // The whole thing can be commented out because the minimum tvOS is 10.0
                
                //                if Int(currentTime) <= Int(start) {
                //                    if (timeElapsed > Constants.MIN_LOAD_TIME) {
                //                        pause()
                //                        loadFailed = true
                //
                //                        DispatchQueue.main.async(execute: { () -> Void in
                //                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
                //                        })
                //
                //                        if (UIApplication.shared.applicationState == UIApplicationState.active) {
                //                            alert(title: "Unable to Play Content", message: "Please check your network connection and try again.")
                //                        }
                //                    } else {
                //                        // Kick the player in the pants to get it going (audio primarily requiring this when the network is poor)
                //                        print("KICK")
                //                        player?.play()
                //                    }
                //                } else {
                //                    if #available(iOS 10.0, *) {
                //                    } else {
                //                        // Was playing normally and the system paused it.
                //                        // This is redundant to KVO monitoring of AVPlayer.timeControlStatus but that is only available in 10.0 and later.
                //                        if (rate == 0) {
                //                            pause()
                //                        }
                //                    }
                //                }
            } else {
                // If it isn't loaded then it shouldn't be playing.
            }
            break
            
        case .paused:
            if loaded {
                // What would cause this?
                //                if (rate != 0) {
                //                    pause()
                //                }
            } else {
                if !loadFailed {
                    if Int(currentTime) <= Int(start) {
                        if (timeElapsed > Constants.MIN_LOAD_TIME) {
                            pause() // To reset playOnLoad
                            failedToLoad()
                        } else {
                            // Wait
                        }
                    } else {
                        // Paused normally
                    }
                } else {
                    // Load failed.
                }
            }
            break
            
        case .stopped:
            break
            
        case .seekingForward:
            break
            
        case .seekingBackward:
            break
        }
    }
    
    func playerTimer()
    {
        if (state != nil) && (url != URL(string: Constants.URL.LIVE_STREAM)) {
            if (rate > 0) {
                updateCurrentTimeForPlaying()
            }
            
            //            logPlayerState()
        }
    }
    
    func observe()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.playerObserverTimer = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PLAYER, target: self, selector: #selector(MediaPlayer.playerObserver), userInfo: nil, repeats: true)
        })
        
        unobserve()
        
        guard (url != URL(string:Constants.URL.LIVE_STREAM)) else {
            return
        }
        
        player?.addObserver( self,
                             forKeyPath: #keyPath(AVPlayer.timeControlStatus),
                             options: [.old, .new],
                             context: nil) // &GlobalPlayerContext
        
        currentItem?.addObserver(self,
                                 forKeyPath: #keyPath(AVPlayerItem.status),
                                 options: [.old, .new],
                                 context: nil) // &GlobalPlayerContext
        observerActive = true
        observedItem = currentItem
        
        playerTimerReturn = player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { (time:CMTime) in // [weak self]
            self.playerTimer()
        })
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaPlayer.didPlayToEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        }
        //
        //        // Why was this put here?  To set the initial state.
        //        pause()
    }
    
    func unobserve()
    {
        playerObserverTimer?.invalidate()
        playerObserverTimer = nil
        
        if playerTimerReturn != nil {
            player?.removeTimeObserver(playerTimerReturn!)
            playerTimerReturn = nil
        }
        
        if observerActive {
            if observedItem != currentItem {
                print("observedItem != currentPlayer!")
            }
            if observedItem != nil {
                print("GLOBAL removeObserver: ",observedItem?.observationInfo as Any)
                
                player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), context: nil) // &GlobalPlayerContext
                
                observedItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil) // &GlobalPlayerContext
                
                observedItem = nil
                
                observerActive = false
            } else {
                print("observedItem == nil!")
            }
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }

    func play()
    {
        guard (url != nil) else {
            return
        }
        
//        guard (player?.status == .readyToPlay) && (currentItem?.status == .readyToPlay) else {
//            playOnLoad = true
//            globals.reloadPlayer()
//            return
//        }
        
        switch url!.absoluteString {
        case Constants.URL.LIVE_STREAM:
            stateTime = PlayerStateTime(state:.playing)
            player?.play()
            break
            
        default:
            if loaded {
                updateCurrentTimeExact()
                stateTime = PlayerStateTime(state:.playing,mediaItem:mediaItem)
                player?.play()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                })
            }
            break
        }
        
//        controller?.allowsPictureInPicturePlayback = true
        
        setupPlayingInfoCenter()
    }
    
    func pause()
    {
        guard (url != nil) else {
            return
        }
        
        updateCurrentTimeExact()
        stateTime = PlayerStateTime(state:.paused,mediaItem:mediaItem)
        player?.pause()
        playOnLoad = false

        switch url!.absoluteString {
        case Constants.URL.LIVE_STREAM:
            break
            
        default:
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
            })
            break
        }

       setupPlayingInfoCenter()
    }
    
    func stop()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaPlayer:stop")
            return
        }

        guard (url != nil) else {
            return
        }

        stateTime = PlayerStateTime(state:.stopped,mediaItem:mediaItem)
        player?.pause()
        playOnLoad = false
        isZoomed = false

        switch url!.absoluteString {
        case Constants.URL.LIVE_STREAM:
            break
            
        default:
//            killPIP = true
            
            updateCurrentTimeExact()
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
            
            break
        }
        
        // This is unique to stop()
        unload()
        player = nil
        let old = mediaItem
        mediaItem = nil
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: old)
        
        setupPlayingInfoCenter()
    }
    
    func updateCurrentTimeExactWhilePlaying()
    {
        if isPlaying {
            updateCurrentTimeExact()
        }
    }
    
    func updateCurrentTimeExact()
    {
        guard (url != nil) else {
            print("Player has no URL.")
            return
        }
        
        guard (url != URL(string:Constants.URL.LIVE_STREAM)) else {
            print("Player is LIVE STREAMING.")
            return
        }
        
        guard loaded else {
            print("Player NOT loaded.")
            return
        }
        
        guard (currentTime != nil) else {
            print("Player has no currentTime.")
            return
        }
        
        print(currentTime!.seconds)
        var time = currentTime!.seconds
        
        if time >= duration!.seconds {
            time = duration!.seconds
        }
        
        if time < 0 {
            time = 0
        }
        
        updateCurrentTimeExact(time)
    }
    
    func updateCurrentTimeExact(_ seekToTime:TimeInterval)
    {
        if (seekToTime == 0) {
            print("seekToTime == 0")
        }
        
        //    print(seekToTime)
        //    print(seekToTime.description)
        
        if (seekToTime >= 0) {
            mediaItem?.currentTime = seekToTime.description
        } else {
            print("seekeToTime < 0")
        }
    }
    
    func seek(to: Double?)
    {
        guard let to = to else {
            return
        }
        
        guard let url = url else {
            return
        }
        
        guard let length = currentItem?.duration.seconds else {
            return
        }
        
        switch url.absoluteString {
        case Constants.URL.LIVE_STREAM:
            break
            
        default:
            if loaded {
                var seek = to
                
                if seek > length {
                    seek = length
                }
                
                if seek < 0 {
                    seek = 0
                }
                
                player?.seek(to: CMTimeMakeWithSeconds(seek,Constants.CMTime_Resolution), toleranceBefore: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution), toleranceAfter: CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution),
                             completionHandler: { (finished:Bool) in
                                if finished {
                                    DispatchQueue.main.async(execute: { () -> Void in
                                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DONE_SEEKING), object: nil)
                                    })
                                }
                })
                
                mediaItem?.currentTime = seek.description
                stateTime?.startTime = seek.description
                
                setupPlayingInfoCenter()
            }
            break
        }
    }
    
    var currentTime:CMTime? {
        get {
            return player?.currentTime()
        }
    }
    
    var currentItem:AVPlayerItem? {
        get {
            return player?.currentItem
        }
    }
    
    var player:AVPlayer? {
        get {
            return controller?.player
        }
        set {
            unobserve()
            
            if self.progressTimerReturn != nil {
                self.player?.removeTimeObserver(self.progressTimerReturn!)
                self.progressTimerReturn = nil
            }
            
            // This seems to be lethal if newValue is nil
            controller?.player = newValue
        }
    }
    
    var duration:CMTime? {
        get {
            return currentItem?.duration
        }
    }
    
    var state:PlayerState? {
        get {
            return stateTime?.state
        }
    }
    
    var startTime:String? {
        get {
            return stateTime?.startTime
        }
        set {
            stateTime?.startTime = newValue
        }
    }
    
    var rate:Float? {
        get {
            return player?.rate
        }
    }
    
    var view:UIView? {
        get {
            return controller?.view
        }
    }
    
    var isPlaying:Bool {
        get {
            return stateTime?.state == .playing
        }
    }
    
    var isPaused:Bool {
        get {
            return stateTime?.state == .paused
        }
    }
    
    var playOnLoad:Bool = true
    var loaded:Bool = false
    var loadFailed:Bool = false
    
    func unload()
    {
        loaded = false
        loadFailed = false
    }
    
    //    var observer: Timer?
    
    var mediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            globals.mediaCategory.playing = mediaItem?.id

            if oldValue != nil {
                // Remove playing icon if the previous mediaItem was playing.
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: oldValue)
                })
            }
            
            if mediaItem == nil {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                
                // For some reason setting player to nil is LETHAL.
//                player = nil
//                stateTime = nil
            }
        }
    }
    
    func logPlayerState()
    {
        stateTime?.log()
    }
    
    func setupPlayingInfoCenter()
    {
        guard url != URL(string: Constants.URL.LIVE_STREAM) else {
            var nowPlayingInfo = [String:Any]()
            
            nowPlayingInfo[MPMediaItemPropertyTitle]         = "Live Broadcast"
            
            nowPlayingInfo[MPMediaItemPropertyArtist]        = "Countryside Bible Church"
            
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle]    = "Live Broadcast"
            
            nowPlayingInfo[MPMediaItemPropertyAlbumArtist]   = "Countryside Bible Church"
            
            if let image = UIImage(named:Constants.COVER_ART_IMAGE) {
                nowPlayingInfo[MPMediaItemPropertyArtwork]   = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (CGSize) -> UIImage in
                    return image
                })
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            })
            return
        }

        if let mediaItem = self.mediaItem {
            var nowPlayingInfo = [String:Any]()
            
            nowPlayingInfo[MPMediaItemPropertyTitle]     = mediaItem.title
            nowPlayingInfo[MPMediaItemPropertyArtist]    = mediaItem.speaker
            
            if let image = UIImage(named:Constants.COVER_ART_IMAGE) {
                nowPlayingInfo[MPMediaItemPropertyArtwork]   = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (CGSize) -> UIImage in
                    return image
                })
            } else {
                print("no artwork!")
            }
            
            if mediaItem.hasMultipleParts {
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = mediaItem.multiPartName
                nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = mediaItem.speaker
                
                if let index = mediaItem.multiPartMediaItems?.index(of: mediaItem) {
                    nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber]  = index + 1
                } else {
                    print(mediaItem as Any," not found in ",mediaItem.multiPartMediaItems as Any)
                }
                
                nowPlayingInfo[MPMediaItemPropertyAlbumTrackCount]   = mediaItem.multiPartMediaItems?.count
            }
            
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration]          = duration?.seconds
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime]  = currentTime?.seconds
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate]         = rate
            
            //    print("\(mediaItemInfo.count)")
            
            //                print(nowPlayingInfo)
            
            DispatchQueue.main.async(execute: { () -> Void in
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            })
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            })
        }
    }
}

