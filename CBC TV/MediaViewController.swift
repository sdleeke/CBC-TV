//
//  MediaViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/31/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MediaPlayer

extension AVPlayerViewController {
    func menuButtonAction(tap:UITapGestureRecognizer)
    {
        print("MVC menu button pressed")
        
        guard Thread.isMainThread else {
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MENU), object: nil)
    }
}

class MediaViewController: UIViewController
{
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)
    {
        if preferredFocusView == splitViewController?.viewControllers[0].view {
            preferredFocusView = nil
        }
    }
    
    var preferredFocusView:UIView?
    {
        didSet {
            if (preferredFocusView != nil) {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setNeedsFocusUpdate()
                })
            }
        }
    }
    
    override var preferredFocusEnvironments : [UIFocusEnvironment]
        {
        get {
            if preferredFocusView != nil {
                return [preferredFocusView!]
            } else {
                return [playPauseButton]
            }
        }
    }
    
    var observerActive = false
    var observedItem:AVPlayerItem?

    private var PlayerContext = 0
    
    var player:AVPlayer?
    
    var progressObserver:Timer?
    
    func removePlayerObserver()
    {
        if observerActive {
            if observedItem != player?.currentItem {
                print("observedItem != player?.currentItem")
            }
            if observedItem != nil {
                print("MVC removeObserver: ",player?.currentItem?.observationInfo as Any)
                
                observedItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &PlayerContext)
                observedItem = nil
                observerActive = false
            } else {
                print("observedItem == nil!")
            }
        }
    }
    
    func addPlayerObserver()
    {
        player?.currentItem?.addObserver(self,
                                         forKeyPath: #keyPath(AVPlayerItem.status),
                                         options: [.old, .new],
                                         context: &PlayerContext)
        observerActive = true
        observedItem = player?.currentItem
    }
    
    func playerURL(url: URL?)
    {
        guard let url = url else {
            return
        }
        
        removePlayerObserver()
        
        player = AVPlayer(url: url)
        
        addPlayerObserver()
    }
    
    var selectedMediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: oldValue)
            }
            
            if (selectedMediaItem != nil) && (selectedMediaItem != globals.mediaPlayer.mediaItem) {
                globals.mediaPlayer.stop()
                
                setupVideo()
                
                if let url = selectedMediaItem?.playingURL {
                    playerURL(url: url)
                } else {
                    print(selectedMediaItem?.dict as Any)
                    networkUnavailable("Media Not Available")
                }
            }
            
            if (selectedMediaItem != nil) {
                mediaItems = selectedMediaItem?.multiPartMediaItems // mediaItemsInMediaItemSeries(selectedMediaItem)

                globals.selectedMediaItem.detail = selectedMediaItem
                
                setupTitle()
                
                DispatchQueue.main.async {
                    NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self.selectedMediaItem) //
                }
            } else {
                // We always select, never deselect, so this should not be done.  If we set this to nil it is for some other reason, like clearing the UI.
                //                defaults.removeObjectForKey(Constants.SELECTED_SERMON_DETAIL_KEY)
                mediaItems = nil
            }
            
            if (selectedMediaItem != nil) && (selectedMediaItem == globals.mediaPlayer.mediaItem) {
                removePlayerObserver()
                
//                if globals.mediaPlayer.url != selectedMediaItem?.playingURL {
//                    updateUI()
//                }
                
                // Crashes because it uses UI and this is done before viewWillAppear when the mediaItemSelected is set in prepareForSegue, but it only happens on an iPhone because the MVC isn't setup already.
                //                addProgressObserver()
            }
        }
    }

    var mediaItems:[MediaItem]?

    @IBOutlet weak var audioOrVideoControl: UISegmentedControl!
    @IBOutlet weak var audioOrVideoWidthConstraint: NSLayoutConstraint!
    
    @IBAction func audioOrVideoSelection(sender: UISegmentedControl)
    {
//        print(selectedMediaItem!.playing!)
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaViewController:audioOrVideoSelection")
            return
        }
        
        switch sender.selectedSegmentIndex {
        case Constants.AV_SEGMENT_INDEX.AUDIO:
            if let playing = selectedMediaItem?.playing {
                switch playing {
                case Playing.audio:
                    //Do nothing, already selected
                    break
                    
                case Playing.video:
                    if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                        globals.mediaPlayer.stop() // IfPlaying
                        
                        globals.mediaPlayer.view?.isHidden = true
                        
                        setupSpinner()
                        
                        removeProgressObserver()
                        
                        setupPlayPauseButton()
                        setupProgressAndTimes()
                    }
                    
                    selectedMediaItem?.playing = Playing.audio // Must come before setupNoteAndSlides()
                    
                    // Unlike CBC on iOS, don't load the player.
                    //                if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                    //                    globals.setupPlayer(selectedMediaItem, playOnLoad: false)
                    //                }
                    
                    playerURL(url: selectedMediaItem?.playingURL)
                    
                    setupProgressAndTimes()
                    
                    setupVideo()
                    break
                    
                default:
                    break
                }
            }
            break
            
        case Constants.AV_SEGMENT_INDEX.VIDEO:
            if let playing = selectedMediaItem?.playing {
                switch playing {
                case Playing.audio:
                    if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                        globals.mediaPlayer.stop() // IfPlaying
                        
                        setupSpinner()
                        
                        removeProgressObserver()
                        
                        setupPlayPauseButton()
                        setupProgressAndTimes()
                    }
                    
                    selectedMediaItem?.playing = Playing.video // Must come before setupNoteAndSlides()
                    
                    // Unlike CBC on iOS, don't load the player.
                    //                if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                    //                    globals.setupPlayer(selectedMediaItem, playOnLoad: false)
                    //                }
                    
                    playerURL(url: selectedMediaItem?.playingURL)
                    
                    setupProgressAndTimes()
                    break
                    
                case Playing.video:
                    //Do nothing, already selected
                    break
                    
                default:
                    break
                }
            }
            break
            
        default:
            print("oops!")
            break
        }
    }

    @IBOutlet weak var playPauseButton: UIButton! // UIButton!
    
    @IBOutlet weak var restartButton: UIButton!
    {
        didSet {
            restartButton.setTitle(Constants.FA.RESTART, for: UIControlState.normal)
        }
    }
    @IBAction func restartButtonAction(_ sender: UIButton)
    {
        guard globals.mediaPlayer.loaded else {
            return
        }
        
        globals.mediaPlayer.seek(to: 0)
    }
    
    @IBOutlet weak var rewindButton: UIButton!
    {
        didSet {
            rewindButton.setTitle(Constants.FA.REWIND, for: UIControlState.normal)
        }
    }
    @IBAction func rewindButtonAction(_ sender: UIButton)
    {
        guard globals.mediaPlayer.loaded else {
            return
        }
        
        guard let currentTime = globals.mediaPlayer.currentTime else {
            return
        }
        
        globals.mediaPlayer.seek(to: currentTime.seconds - Constants.SKIP_TIME_INTERVAL)
    }
    
    @IBOutlet weak var fastForwardButton: UIButton!
    {
        didSet {
            fastForwardButton.setTitle(Constants.FA.FF, for: UIControlState.normal)
        }
    }
    @IBAction func fastForwardButtonAction(_ sender: UIButton)
    {
        guard globals.mediaPlayer.loaded else {
            return
        }
        
        guard let currentTime = globals.mediaPlayer.currentTime else {
            return
        }
        
        globals.mediaPlayer.seek(to: currentTime.seconds + Constants.SKIP_TIME_INTERVAL)
    }
    
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext

        if keyPath == #keyPath(AVPlayerItem.status) {
            guard (context == &PlayerContext) else {
                super.observeValue(forKeyPath: keyPath,
                                   of: object,
                                   change: change,
                                   context: context)
                return
            }
            
            setupProgressAndTimes()
        }
    }

    @IBAction func playPause(_ sender: UIButton)
    {
        guard (selectedMediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) else {
            playNewMediaItem(selectedMediaItem)
            return
        }

        func showState(_ state:String)
        {
            print(state)
        }
        
        switch globals.mediaPlayer.state! {
        case .none:
            showState("none")
            break
            
        case .playing:
            showState("playing")
            globals.mediaPlayer.pause()
            setupPlayPauseButton()
            setupSpinner()
            break
            
        case .paused:
            showState("paused")
            if globals.mediaPlayer.loaded && (globals.mediaPlayer.url == selectedMediaItem?.playingURL) {
                playCurrentMediaItem(selectedMediaItem)
            } else {
                playNewMediaItem(selectedMediaItem)
            }
            break
            
        case .stopped:
            showState("stopped")
            break
            
        case .seekingForward:
            showState("seekingForward")
            globals.mediaPlayer.pause()
            setupPlayPauseButton()
            break
            
        case .seekingBackward:
            showState("seekingBackward")
            globals.mediaPlayer.pause()
            setupPlayPauseButton()
            break
        }
    }
    
    fileprivate func shouldShowLogo() -> Bool
    {
        guard selectedMediaItem != nil, let showing = selectedMediaItem?.showing else {
            return true
        }
        
        var result = false
        
        switch showing {
        case Showing.slides:
            fallthrough
        case Showing.notes:
            break
        
        case Showing.video:
            result = !globals.mediaPlayer.loaded
            break
            
        default:
            result = true
            break
        }
        
//        print(result)

        return result
    }

    @IBOutlet weak var elapsed: UILabel!
    @IBOutlet weak var remaining: UILabel!
    
    @IBOutlet weak var mediaItemNotesAndSlides: UIView!

    @IBOutlet weak var logo: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    {
        didSet {
            tableView.mask = nil
        }
    }
    
    @IBOutlet weak var progressView: UIProgressView!
    
    var actionButton:UIBarButtonItem?
    var tagsButton:UIBarButtonItem?

    fileprivate func setupPlayerView(_ view:UIView?)
    {
        guard let view = view else {
            return
        }
        
        guard let mediaItemNotesAndSlides = mediaItemNotesAndSlides else {
            return
        }
        
        guard (tableView != nil) else {
            return
        }
        
        guard let splitViewController = splitViewController else {
            return
        }
        
        var parentView : UIView!

        parentView = mediaItemNotesAndSlides
        tableView.isScrollEnabled = true

        if globals.mediaPlayer.isZoomed {
            parentView = splitViewController.view
        }
        
        view.isHidden = true
        view.removeFromSuperview()
        
        view.frame = parentView.bounds
        
        view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        if let contain = parentView?.subviews.contains(view), !contain {
            parentView.addSubview(view)
        }
        
        //            print(view)
        //            print(view?.superview)
        
        let centerX = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(centerY)
        
        let width = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(width)
        
        let height = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(height)
        
        view.superview?.setNeedsLayout()
    }
    
    func readyToPlay()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard globals.mediaPlayer.loaded else {
            return
        }
        
        guard (selectedMediaItem != nil) else {
            return
        }
        
        guard (selectedMediaItem == globals.mediaPlayer.mediaItem) else {
            return
        }

        if globals.mediaPlayer.playOnLoad {
            if (selectedMediaItem?.playing == Playing.video) && (selectedMediaItem?.showing != Showing.video) {
                selectedMediaItem?.showing = Showing.video
            }
        }
        
        if (selectedMediaItem?.playing == Playing.video) && (selectedMediaItem?.showing == Showing.video) {
            globals.mediaPlayer.view?.isHidden = false
            
            if let view = globals.mediaPlayer.view {
                mediaItemNotesAndSlides.bringSubview(toFront: view)
            }
        }

        if globals.mediaPlayer.playOnLoad {
            if let atEnd = globals.mediaPlayer.mediaItem?.atEnd, atEnd {
                globals.mediaPlayer.mediaItem?.currentTime = Constants.ZERO
                globals.mediaPlayer.seek(to: 0)
                globals.mediaPlayer.mediaItem?.atEnd = false
            }
            globals.mediaPlayer.playOnLoad = false
            
            // Just for the delay
            DispatchQueue.global(qos: .background).async(execute: {
                DispatchQueue.main.async(execute: { () -> Void in
                    globals.mediaPlayer.play()
                })
            })
        }
        
        setupSpinner()
        setupProgressAndTimes()
        setupPlayPauseButton()
    }
    
    func paused()
    {
        setupSpinner()
        setupProgressAndTimes()
        setupPlayPauseButton()
    }
    
    func failedToLoad()
    {
        guard (selectedMediaItem != nil) else {
            return
        }
        
        if (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            if (selectedMediaItem?.showing == Showing.video) {
                globals.mediaPlayer.stop()
            }
            
            updateUI()
        }
    }
    
    func failedToPlay()
    {
        guard (selectedMediaItem != nil) else {
            return
        }
        
        if (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            if (selectedMediaItem?.showing == Showing.video) {
                globals.mediaPlayer.stop()
            }
            
            updateUI()
        }
    }
    
    func showPlaying()
    {
        guard Thread.isMainThread else {
            return
        }
        
        if let mediaItem = globals.mediaPlayer.mediaItem, (selectedMediaItem?.multiPartMediaItems?.index(of: mediaItem) != nil) {
            selectedMediaItem = globals.mediaPlayer.mediaItem
            scrollToMediaItem(selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
        } else {
            removeProgressObserver()
            if let url = selectedMediaItem?.playingURL {
                playerURL(url: url)
            }
            preferredFocusView = playPauseButton
        }
        
        updateUI()
    }
    
    func updateView()
    {
        selectedMediaItem = globals.selectedMediaItem.detail
        
        tableView.reloadData()
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async(execute: { () -> Void in
                self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            })
        }

        updateUI()
    }
    
    func clearView()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.selectedMediaItem = nil
            
            self.tableView.reloadData()
            
            self.updateUI()
        })
    }
    
    func menuButtonAction(tap:UITapGestureRecognizer)
    {
        print("MVC menu button pressed")
        
        guard Thread.isMainThread else {
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MENU), object: nil)
    }
    
    func playPauseButtonAction(tap:UITapGestureRecognizer)
    {
        print("play pause button pressed")
        
        if let state = globals.mediaPlayer.state {
            switch state {
            case .playing:
                globals.mediaPlayer.pause()
                
            case .paused:
                globals.mediaPlayer.play()
                
            case .stopped:
                if (selectedMediaItem != nil) && (globals.mediaPlayer.mediaItem != selectedMediaItem) {
                    playNewMediaItem(selectedMediaItem)
                }

            default:
                break
            }
        } else {
            if (selectedMediaItem != nil) && (globals.mediaPlayer.mediaItem != selectedMediaItem) {
                playNewMediaItem(selectedMediaItem)
            }
        }
    }
    
    override func viewDidLoad()
    {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        let menuPressRecognizer = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.menuButtonAction(tap:)))
        menuPressRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        view.addGestureRecognizer(menuPressRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MediaViewController.playPauseButtonAction(tap:)))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue)];
        view.addGestureRecognizer(tapRecognizer)
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true

        if (selectedMediaItem == nil) {
            //Will only happen on an iPad
            selectedMediaItem = globals.selectedMediaItem.detail
        }
    }

    fileprivate func setupVideo()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaViewController:setupVideo")
            return
        }
        
        guard activityIndicator != nil else {
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem, let showing = selectedMediaItem.showing, let playing = selectedMediaItem.playing else {
            globals.mediaPlayer.view?.isHidden = true
            
            logo.isHidden = !shouldShowLogo() // && roomForLogo()
            
            if !logo.isHidden {
                mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
            }
            return
        }
        
        activityIndicator.isHidden = true

//        print("setupNotesAndSlides")
//        print("Selected: \(globals.mediaItemSelected?.title)")
//        print("Last Selected: \(globals.mediaItemLastSelected?.title)")
//        print("Playing: \(globals.player.playing?.title)")
        
//        print("notes hidden \(mediaItemNotes.hidden)")
//        print("slides hidden \(mediaItemSlides.hidden)")
        
        // Check whether they can or should show what they claim to show!
        
        switch showing {
        case Showing.video:
            if !selectedMediaItem.hasVideo {
                selectedMediaItem.showing = Showing.none
            }
            break
            
        default:
            selectedMediaItem.showing = Showing.none
            break
        }
        
        switch showing {
        case Showing.notes:
            // Should never happen
            break
            
        case Showing.slides:
            // Should never happen
            break
            
        case Showing.video:
            //This should not happen unless it is playing video.
            switch playing {
            case Playing.audio:
                logo.isHidden = false
                mediaItemNotesAndSlides.bringSubview(toFront: logo)
                break

            case Playing.video:
                if (globals.mediaPlayer.mediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                    // Video is in the player
                    logo.isHidden = globals.mediaPlayer.loaded
                    globals.mediaPlayer.view?.isHidden = !globals.mediaPlayer.loaded
                    
                    selectedMediaItem.showing = Showing.video
                    
                    if (globals.mediaPlayer.player != nil) {
                        // Why is this commented out?
//                            mediaItemNotesAndSlides.bringSubview(toFront: globals.mediaPlayer.view!)
                    } else {
                        logo.isHidden = false
                        mediaItemNotesAndSlides.bringSubview(toFront: logo)
                    }
                } else {
                    // Video is NOT in the player
                    logo.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: logo)
                }
                break
                
            default:
                logo.isHidden = false
                mediaItemNotesAndSlides.bringSubview(toFront: logo)
                break
            }
            break
            
        case Showing.none:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            
            switch playing {
            case Playing.audio:
                globals.mediaPlayer.view?.isHidden = true
                logo.isHidden = false
                break
                
            case Playing.video:
                if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                    if let hasVideo = globals.mediaPlayer.mediaItem?.hasVideo, hasVideo, globals.mediaPlayer.mediaItem?.playing == Playing.video {
                        if globals.mediaPlayer.loaded {
                            globals.mediaPlayer.view?.isHidden = false
                        }
                        if let view = globals.mediaPlayer.view {
                            mediaItemNotesAndSlides.bringSubview(toFront: view)
                        }
                        selectedMediaItem.showing = Showing.video
                    } else {
                        selectedMediaItem.showing = Showing.none
                        globals.mediaPlayer.view?.isHidden = true
                        logo.isHidden = false
                        mediaItemNotesAndSlides.bringSubview(toFront: logo)
                    }
                } else {
                    globals.mediaPlayer.view?.isHidden = true
                    logo.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: logo)
                }
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
    
    func scrollToMediaItem(_ mediaItem:MediaItem?,select:Bool,position:UITableViewScrollPosition)
    {
        guard let mediaItem = mediaItem else {
            return
        }

        var indexPath = IndexPath(row: 0, section: 0)
        
        if mediaItems?.count > 0, let mediaItemIndex = mediaItems?.index(of: mediaItem) {
            //                    print("\(mediaItemIndex)")
            indexPath = IndexPath(row: mediaItemIndex, section: 0)
        }
        
        //            print("\(tableView.bounds)")
        
        guard (indexPath.section < tableView.numberOfSections) else {
            NSLog("indexPath section ERROR in scrollToMediaItem")
            NSLog("Section: \(indexPath.section)")
            NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
            return
        }
        
        guard indexPath.row < tableView.numberOfRows(inSection: indexPath.section) else {
            NSLog("indexPath row ERROR in scrollToMediaItem")
            NSLog("Section: \(indexPath.section)")
            NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
            NSLog("Row: \(indexPath.row)")
            NSLog("TableView Number of Rows in Section: \(tableView.numberOfRows(inSection: indexPath.section))")
            return
        }
        
        if select {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: position)
        }

        tableView.scrollToRow(at: indexPath, at: position, animated: false)
    }
    
    func setupPlayPauseButton()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaViewController:setupPlayPauseButton")
            return
        }
        
        guard (selectedMediaItem != nil) else  {
            playPauseButton.isEnabled = false
            playPauseButton.isHidden = true
            
            fastForwardButton.isEnabled = playPauseButton.isEnabled
            fastForwardButton.isHidden = playPauseButton.isHidden
            
            rewindButton.isEnabled = playPauseButton.isEnabled
            rewindButton.isHidden = playPauseButton.isHidden
            
            restartButton.isEnabled = playPauseButton.isEnabled
            restartButton.isHidden = playPauseButton.isHidden
            
            return
        }

        func showState(_ state:String)
        {
//            print(state)
        }

        if (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            playPauseButton.isEnabled = globals.mediaPlayer.loaded || globals.mediaPlayer.loadFailed
            
            if let state = globals.mediaPlayer.state {
                switch state {
                case .playing:
                    showState("Playing -> Pause")
                    
                    playPauseButton.setTitle(Constants.FA.PAUSE, for: UIControlState.normal)
                    break
                    
                case .paused:
                    showState("Paused -> Play")
                  
                    playPauseButton.setTitle(Constants.FA.PLAY, for: UIControlState.normal)
                    break
                    
                default:
                    break
                }
            }
        } else {
            showState("Global not selected")
            playPauseButton.isEnabled = true

            playPauseButton.setTitle(Constants.FA.PLAY, for: UIControlState.normal)
        }

        playPauseButton.isHidden = false
        
        fastForwardButton.isEnabled = playPauseButton.isEnabled && globals.mediaPlayer.loaded
        fastForwardButton.isHidden = playPauseButton.isHidden && globals.mediaPlayer.loaded
        
        rewindButton.isEnabled = playPauseButton.isEnabled && globals.mediaPlayer.loaded
        rewindButton.isHidden = playPauseButton.isHidden && globals.mediaPlayer.loaded
        
        restartButton.isEnabled = playPauseButton.isEnabled && globals.mediaPlayer.loaded
        restartButton.isHidden = playPauseButton.isHidden && globals.mediaPlayer.loaded
    }
    
    fileprivate func setupTitle()
    {
        let titleString:String?

        let attrTitleString = NSMutableAttributedString()

        attrTitleString.append(NSAttributedString(string: Constants.CBC.LONG,   attributes: Constants.Fonts.Attributes.titleGrey))

        if !globals.mediaPlayer.isZoomed {
            if let title = selectedMediaItem?.title {
                titleString = title
            } else {
                titleString = Constants.CBC.LONG
            }
        } else {
            titleString = nil
        }

        if let navBar = navigationController?.navigationBar, let titleString = titleString {
            let labelWidth = navBar.bounds.width - 110
            
            let label = UILabel(frame: CGRect(x:(navBar.bounds.width/2) - (labelWidth/2), y:0, width:labelWidth, height:navBar.bounds.height))
            label.backgroundColor = UIColor.clear
            label.numberOfLines = 2
            label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
            label.textAlignment = .center
            label.textColor = UIColor.black
            label.lineBreakMode = .byTruncatingTail
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
            
            label.text = Constants.CBC.LONG
            label.attributedText = attrTitleString
            
            if titleString != Constants.CBC.LONG, let text = label.text {
                label.text = text + "\n" + titleString

                attrTitleString.append(NSAttributedString(string: "\n",   attributes: Constants.Fonts.Attributes.normal))
                attrTitleString.append(NSAttributedString(string: titleString,   attributes: Constants.Fonts.Attributes.boldGrey))
                label.attributedText = attrTitleString
            }
            
            navigationItem.titleView = label
        }
    }
    
    fileprivate func setupAudioOrVideo()
    {
        guard let selectedMediaItem = selectedMediaItem else {
            audioOrVideoControl.isEnabled = false
            audioOrVideoControl.isHidden = true
            return
        }
        
        if (selectedMediaItem.hasAudio && selectedMediaItem.hasVideo) {
            audioOrVideoControl.isEnabled = true
            audioOrVideoControl.isHidden = false
            audioOrVideoWidthConstraint.constant = Constants.AUDIO_VIDEO_MAX_WIDTH
            view.setNeedsLayout()

            audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.AV_SEGMENT_INDEX.AUDIO)
            audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.AV_SEGMENT_INDEX.VIDEO)
            
//                print(selectedMediaItem!.playing!)
            
            if let playing = selectedMediaItem.playing {
                switch playing {
                case Playing.audio:
                    audioOrVideoControl.selectedSegmentIndex = Constants.AV_SEGMENT_INDEX.AUDIO
                    break
                    
                case Playing.video:
                    audioOrVideoControl.selectedSegmentIndex = Constants.AV_SEGMENT_INDEX.VIDEO
                    break
                    
                default:
                    break
                }
            }

            audioOrVideoControl.setTitleTextAttributes([ NSFontAttributeName: UIFont(name: "FontAwesome", size: 24.0)! ], for: .normal) // Constants.FA.Fonts.Attributes.icons
            audioOrVideoControl.setTitleTextAttributes([ NSFontAttributeName: UIFont(name: "FontAwesome", size: 32.0)! ], for: .selected) // Constants.FA.Fonts.Attributes.icons
            audioOrVideoControl.setTitleTextAttributes([ NSFontAttributeName: UIFont(name: "FontAwesome", size: 40.0)! ], for: .focused) // Constants.FA.Fonts.Attributes.icons
            
            audioOrVideoControl.setTitle(Constants.FA.AUDIO, forSegmentAt: Constants.AV_SEGMENT_INDEX.AUDIO) // Audio

            audioOrVideoControl.setTitle(Constants.FA.VIDEO, forSegmentAt: Constants.AV_SEGMENT_INDEX.VIDEO) // Video
        } else {
            audioOrVideoControl.isEnabled = false
            audioOrVideoControl.isHidden = true
            audioOrVideoWidthConstraint.constant = 0
            view.setNeedsLayout()
        }
    }
    
    func updateUI()
    {
        if (selectedMediaItem != nil) && (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            if (globals.mediaPlayer.url != selectedMediaItem?.playingURL) {
//                globals.mediaPlayer.killPIP = true
                globals.mediaPlayer.pause()
                globals.mediaPlayer.setup(selectedMediaItem,playOnLoad:false)
            } else {
                if globals.mediaPlayer.loadFailed {
                    logo.isHidden = false
                    mediaItemNotesAndSlides.bringSubview(toFront: logo)
                }
            }
        }
        
        setupPlayerView(globals.mediaPlayer.view)

        //        print("viewWillAppear 1 mediaItemNotesAndSlides.bounds: \(mediaItemNotesAndSlides.bounds)")
        //        print("viewWillAppear 1 tableView.bounds: \(tableView.bounds)")
        
        //        print("viewWillAppear 2 mediaItemNotesAndSlides.bounds: \(mediaItemNotesAndSlides.bounds)")
        //        print("viewWillAppear 2 tableView.bounds: \(tableView.bounds)")
        
        //These are being added here for the case when this view is opened and the mediaItem selected is playing already
        addProgressObserver()
        
        setupTitle()
        setupAudioOrVideo()
        setupPlayPauseButton()
        setupSpinner()
        setupProgressAndTimes()
        setupVideo()
    }
    
    func doneSeeking()
    {
        print("DONE SEEKING")
        
        globals.mediaPlayer.checkDidPlayToEnd()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        guard Thread.isMainThread else {
            return
        }
        
        // Shouldn't some or all of these have object values of selectedMediaItem?
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.playPause(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PLAY_PAUSE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.doneSeeking), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DONE_SEEKING), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.showPlaying), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.paused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.failedToLoad), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_LOAD), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.failedToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.readyToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.setupPlayPauseButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
        
        if (splitViewController != nil) {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        }

        if selectedMediaItem != nil, globals.mediaPlayer.mediaItem == selectedMediaItem, globals.mediaPlayer.isPaused,
            let hasCurrentTime = globals.mediaPlayer.mediaItem?.hasCurrentTime, hasCurrentTime,
            let currentTime = globals.mediaPlayer.mediaItem?.currentTime {
            globals.mediaPlayer.seek(to: Double(currentTime))
        }

        updateUI()

        scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        if globals.isLoading && (navigationController?.visibleViewController == self) && (splitViewController?.viewControllers.count == 1) {
            if let navigationController = splitViewController?.viewControllers[0] as? UINavigationController {
                navigationController.popToRootViewController(animated: false)
            }
        }
        
        setNeedsFocusUpdate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationItem.rightBarButtonItem = nil
        
        removeProgressObserver()
        removePlayerObserver()

//        NotificationCenter.default.removeObserver(self) // Catch-all.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("didReceiveMemoryWarning: \(String(describing: selectedMediaItem?.title))")
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var destination = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController!
        }

        switch segue.identifier {
            
        default:
            break
        }
    }

    fileprivate func setTimes(timeNow:Double, length:Double)
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaViewController:setTimes")
            return
        }

        guard !timeNow.isNaN && !length.isNaN else {
            self.elapsed.text = nil
            self.remaining.text = nil
            return
        }

        let timeRemaining = max(length - timeNow,0)
        
        guard !timeRemaining.isNaN else {
            self.elapsed.text = nil
            self.remaining.text = nil
            return
        }

//        print("timeNow:",timeNow,"length:",length)
        
        let elapsedHours = max(Int(timeNow / (60*60)),0)
        let elapsedMins = max(Int((timeNow - (Double(elapsedHours) * 60*60)) / 60),0)
        let elapsedSec = max(Int(timeNow.truncatingRemainder(dividingBy: 60)),0)
        
        var elapsed:String
        
        if (elapsedHours > 0) {
            elapsed = "\(String(format: "%d",elapsedHours)):"
        } else {
            elapsed = Constants.EMPTY_STRING
        }
        
        elapsed = elapsed + "\(String(format: "%02d",elapsedMins)):\(String(format: "%02d",elapsedSec))"
        
        self.elapsed.text = elapsed
        
        let remainingHours = max(Int(timeRemaining / (60*60)),0)
        let remainingMins = max(Int((timeRemaining - (Double(remainingHours) * 60*60)) / 60),0)
        let remainingSec = max(Int(timeRemaining.truncatingRemainder(dividingBy: 60)),0)
        
        var remaining:String
        
        if (remainingHours > 0) {
            remaining = "\(String(format: "%d",remainingHours)):"
        } else {
            remaining = Constants.EMPTY_STRING
        }
        
        remaining = remaining + "\(String(format: "%02d",remainingMins)):\(String(format: "%02d",remainingSec))"
        
        self.remaining.text = remaining
    }
    
    
    fileprivate func setProgressAndTimesToAudio()
    {
        guard let state = globals.mediaPlayer.state else {
            return
        }
        
        guard let length = globals.mediaPlayer.duration?.seconds, length > 0 else {
            return
        }
        
        guard let playerCurrentTime = globals.mediaPlayer.currentTime?.seconds, playerCurrentTime >= 0, playerCurrentTime <= length else {
            return
        }

        guard let mediaItemCurrentTime = globals.mediaPlayer.mediaItem?.currentTime, let playingCurrentTime = Double(mediaItemCurrentTime), playingCurrentTime >= 0, playingCurrentTime <= length else {
            return
        }

//            print(length)
        
        //Crashes if currentPlaybackTime is not a number (NaN) or infinite!  I.e. when nothing has been playing.  This is only a problem on the iPad, I think.
        
        var progress:Double = -1.0

//            print("currentTime",selectedMediaItem?.currentTime)
//            print("timeNow",timeNow)
//            print("length",length)
//            print("progress",progress)
        
        switch state {
        case .playing:
            progress = playerCurrentTime / length
            
            if globals.mediaPlayer.loaded {
                //                            print("playing")
                //                            print("progress.value",progress.value)
                //                            print("progress",progress)
                //                            print("length",length)
                
                if playerCurrentTime == 0 {
                    progress = playingCurrentTime / length
                    progressView.progress = Float(progress)
                    setTimes(timeNow: playingCurrentTime,length: length)
                } else {
                    progressView.progress = Float(progress)
                    setTimes(timeNow: playerCurrentTime,length: length)
                }
            } else {
                print("not loaded")
            }
            
            elapsed.isHidden = false
            remaining.isHidden = false
            progressView.isHidden = false
            break
            
        case .paused:
            progress = playingCurrentTime / length
            
            //                        print("paused")
            //                        print("timeNow",timeNow)
            //                        print("progress",progress)
            //                        print("length",length)
            
            progressView.progress = Float(progress)
            setTimes(timeNow: playingCurrentTime,length: length)
            
            elapsed.isHidden = false
            remaining.isHidden = false
            progressView.isHidden = false
            break
            
        case .stopped:
            progress = playingCurrentTime / length
            
            //                        print("stopped")
            //                        print("timeNow",timeNow)
            //                        print("progress",progress)
            //                        print("length",length)
            
            progressView.progress = Float(progress)

            setTimes(timeNow: playingCurrentTime,length: length)
            
            elapsed.isHidden = false
            remaining.isHidden = false
            progressView.isHidden = false
            break
            
        default:
            break
        }
    }
    
    fileprivate func setupProgressAndTimes()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaViewController:setupProgressAndTimes")
            return
        }
        
        guard progressView != nil else {
            return
        }
        
        guard (selectedMediaItem != nil) else {
            elapsed.isHidden = true
            remaining.isHidden = true
            progressView.isHidden = true
            return
        }
        
        if (globals.mediaPlayer.state != .stopped) && (globals.mediaPlayer.mediaItem == selectedMediaItem) {
            if !globals.mediaPlayer.loadFailed {
                setProgressAndTimesToAudio()
            } else {
                elapsed.isHidden = true
                remaining.isHidden = true
                progressView.isHidden = true
            }
        } else {
            if  (player?.currentItem?.status == .readyToPlay),
                let length = player?.currentItem?.duration.seconds,
                let currentTime = selectedMediaItem?.currentTime,
                let timeNow = Double(currentTime) {
                let progress = timeNow / length

                progressView.progress = Float(progress)
                
                //                        print("timeNow",timeNow)
                //                        print("progress",progress)
                //                        print("length",length)
                
                setTimes(timeNow: timeNow,length: length)
                
                elapsed.isHidden = false
                remaining.isHidden = false
                progressView.isHidden = false
            } else {
                elapsed.isHidden = true
                remaining.isHidden = true
                progressView.isHidden = true
            }
        }
    }
    
    func progressTimer()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaViewController:progressTimer")
            return
        }
        
        guard (selectedMediaItem != nil) else {
            return
        }
    
        guard (selectedMediaItem == globals.mediaPlayer.mediaItem) else {
            return
        }
        
        guard (globals.mediaPlayer.state != nil) else {
            return
        }
        
        setupPlayPauseButton()
        setupSpinner()
        
        func showState(_ state:String)
        {
//            print(state)
        }
        
        switch globals.mediaPlayer.state! {
        case .none:
            showState("none")
            break
            
        case .playing:
            showState("playing")
            
            setupSpinner()
            
            if globals.mediaPlayer.loaded {
                setProgressAndTimesToAudio()
                setupPlayPauseButton()
            }
            break
            
        case .paused:
            showState("paused")
            
            setupSpinner()
            
            if globals.mediaPlayer.loaded {
                setProgressAndTimesToAudio()
                setupPlayPauseButton()
            }
            break
            
        case .stopped:
            showState("stopped")
            break
            
        case .seekingForward:
            showState("seekingForward")
            //            setupSpinner()  // Already done above.
            break
            
        case .seekingBackward:
            showState("seekingBackward")
            //            setupSpinner()  // Already done above.
            break
        }
        
//            if (globals.mediaPlayer.player != nil) {
//                switch globals.mediaPlayer.player!.playbackState {
//                case .Interrupted:
//                    print("progressTimer.Interrupted")
//                    break
//                    
//                case .Paused:
//                    print("progressTimer.Paused")
//                    break
//                    
//                case .Playing:
//                    print("progressTimer.Playing")
//                    break
//                    
//                case .SeekingBackward:
//                    print("progressTimer.SeekingBackward")
//                    break
//                    
//                case .SeekingForward:
//                    print("progressTimer.SeekingForward")
//                    break
//                    
//                case .Stopped:
//                    print("progressTimer.Stopped")
//                    break
//                }
//            }
    }
    
    func removeProgressObserver()
    {
        progressObserver?.invalidate()
        progressObserver = nil
        
        if globals.mediaPlayer.progressTimerReturn != nil {
            globals.mediaPlayer.player?.removeTimeObserver(globals.mediaPlayer.progressTimerReturn!)
            globals.mediaPlayer.progressTimerReturn = nil
        }
    }
    
    func addProgressObserver()
    {
        removeProgressObserver()
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.progressObserver = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PROGRESS, target: self, selector: #selector(MediaViewController.progressTimer), userInfo: nil, repeats: true)
        })

//        globals.mediaPlayer.progressTimerReturn = globals.mediaPlayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { [weak self] (time:CMTime) in
//            self?.progressTimer()
//        })
    }

    func playCurrentMediaItem(_ mediaItem:MediaItem?)
    {
        guard let mediaItem = mediaItem else {
            return
        }
        
        assert(globals.mediaPlayer.mediaItem == mediaItem)
        
        var seekToTime:CMTime?

        if mediaItem.hasCurrentTime {
            if mediaItem.atEnd {
                print("playPause globals.mediaPlayer.currentTime and globals.player.playing!.currentTime reset to 0!")
                mediaItem.currentTime = Constants.ZERO
                seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
                mediaItem.atEnd = false
            } else {
                if let currentTime = mediaItem.currentTime, let seconds = Double(currentTime) {
                    seekToTime = CMTimeMakeWithSeconds(seconds,Constants.CMTime_Resolution)
                }
            }
        } else {
            print("playPause selectedMediaItem has NO currentTime!")
            mediaItem.currentTime = Constants.ZERO
            seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
        }

        if seekToTime != nil {
            let loadedTimeRanges = (globals.mediaPlayer.player?.currentItem?.loadedTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                if let seekToTime = seekToTime {
                    return cmTimeRange.containsTime(seekToTime)
                } else {
                    return false
                }
            })

            let seekableTimeRanges = (globals.mediaPlayer.player?.currentItem?.seekableTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                if let seekToTime = seekToTime {
                    return cmTimeRange.containsTime(seekToTime)
                } else {
                    return false
                }
            })

            if (loadedTimeRanges != nil) || (seekableTimeRanges != nil) {
                globals.mediaPlayer.seek(to: seekToTime?.seconds)

                globals.mediaPlayer.play()
                
                setupPlayPauseButton()
            } else {
                playNewMediaItem(mediaItem)
            }
        }
    }

    fileprivate func playNewMediaItem(_ mediaItem:MediaItem?)
    {
        guard let mediaItem = mediaItem, mediaItem.hasVideo || mediaItem.hasAudio else {
            return
        }
        
        globals.mediaPlayer.stop() // IfPlaying
        
        globals.mediaPlayer.view?.removeFromSuperview()
        
        globals.mediaPlayer.mediaItem = mediaItem
        
        globals.mediaPlayer.unload()
        
        setupSpinner()
        
        removeProgressObserver()
        
        //This guarantees a fresh start.
        globals.mediaPlayer.setup(mediaItem, playOnLoad: true)
        
        if (mediaItem.hasVideo && (mediaItem.playing == Playing.video)) {
            setupPlayerView(globals.mediaPlayer.view)
        }
        
        addProgressObserver()
        
        if (view.window != nil) {
            setupProgressAndTimes()
            setupPlayPauseButton()
        }
    }
    
    func setupSpinner()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaViewController:setupSpinner")
            return
        }
        
        guard (selectedMediaItem != nil) else {
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
            return
        }
        
        guard (selectedMediaItem == globals.mediaPlayer.mediaItem) else {
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
            return
        }
        
        if !globals.mediaPlayer.loaded && !globals.mediaPlayer.loadFailed {
            if !spinner.isAnimating {
                spinner.isHidden = false
                spinner.startAnimating()
            }
        } else {
            if globals.mediaPlayer.isPlaying {
                if let currentTime = globals.mediaPlayer.mediaItem?.currentTime, let seconds = Double(currentTime), globals.mediaPlayer.currentTime?.seconds > seconds {
                    if spinner.isAnimating {
                        spinner.isHidden = true
                        spinner.stopAnimating()
                    }
                } else {
                    if !spinner.isAnimating {
                        spinner.isHidden = false
                        spinner.startAnimating()
                    }
                }
            } else {
                if spinner.isAnimating {
                    spinner.isHidden = true
                    spinner.stopAnimating()
                }
            }
        }
    }
}

extension MediaViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        guard selectedMediaItem != nil else {
            return 0
        }
        
        guard let mediaItems = mediaItems else {
            return 0
        }
        
        return mediaItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.MULTIPART_MEDIAITEM, for: indexPath) as! MediaTableViewCell
        
        cell.hideUI()
        
        cell.mediaItem = mediaItems?[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return false // editActionsAtIndexPath(tableView,indexPath:indexPath) != nil
    }

    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
}

extension MediaViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard !globals.mediaPlayer.isZoomed else {
            return
        }
        
        guard (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) else {
            print("Player is LIVE STREAMING.")
            return
        }
        
        if (selectedMediaItem != mediaItems![indexPath.row]) || (globals.history == nil) {
            globals.addToHistory(mediaItems![indexPath.row])
        }
        selectedMediaItem = mediaItems![indexPath.row]
        
        preferredFocusView = playPauseButton
        
        setupSpinner()
        setupAudioOrVideo()
        setupPlayPauseButton()
        setupProgressAndTimes()
        setupVideo()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    {
        //        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MediaTableViewCell {
        //
        //        }
    }
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return NO if you do not want the item to be re-orderable.
     return true
     }
     */
}
