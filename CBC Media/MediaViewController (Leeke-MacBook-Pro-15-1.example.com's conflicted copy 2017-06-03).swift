
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

extension MediaViewController : UIAdaptivePresentationControllerDelegate
{
    // MARK: UIAdaptivePresentationControllerDelegate
    
    // Specifically for Plus size iPhones.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

//extension MediaViewController : PopoverTableViewControllerDelegate
//{
//    // MARK: PopoverTableViewControllerDelegate
//    
//    func actionMenu(action:String?,mediaItem:MediaItem?)
//    {
//        guard let action = action else {
//            return
//        }
//        
//        switch action {
//        case Constants.Swap_Video_Location:
//            swapVideoLocation()
//            break
//            
//        case Constants.Print_Slides:
//            fallthrough
//        case Constants.Print_Transcript:
//            printDocument(viewController: self, documentURL: selectedMediaItem?.downloadURL)
//            break
//            
//        case Constants.Add_to_Favorites:
//            selectedMediaItem?.addTag(Constants.Favorites)
//            break
//            
//        case Constants.Add_All_to_Favorites:
//            for mediaItem in mediaItems! {
//                mediaItem.addTag(Constants.Favorites)
//            }
//            break
//            
//        case Constants.Remove_From_Favorites:
//            selectedMediaItem?.removeTag(Constants.Favorites)
//            break
//            
//        case Constants.Remove_All_From_Favorites:
//            for mediaItem in mediaItems! {
//                mediaItem.removeTag(Constants.Favorites)
//            }
//            break
//            
//        case Constants.Open_on_CBC_Website:
//            if selectedMediaItem?.websiteURL != nil {
//                if (UIApplication.shared.canOpenURL(selectedMediaItem!.websiteURL!)) { // Reachability.isConnectedToNetwork() &&
//                    UIApplication.shared.openURL(selectedMediaItem!.websiteURL!)
//                } else {
//                    networkUnavailable("Unable to open transcript in browser at: \(String(describing: selectedMediaItem?.websiteURL))")
//                }
//            }
//            break
//            
//        case Constants.Open_in_Browser:
//            if selectedMediaItem?.downloadURL != nil {
//                if (UIApplication.shared.canOpenURL(selectedMediaItem!.downloadURL!)) { // Reachability.isConnectedToNetwork() &&
//                    UIApplication.shared.openURL(selectedMediaItem!.downloadURL!)
//                } else {
//                    networkUnavailable("Unable to open transcript in browser at: \(String(describing: selectedMediaItem?.downloadURL))")
//                }
//            }
//            break
//            
//        case Constants.Scripture_Viewer:
//            if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: "Scripture View") as? UINavigationController,
//                let popover = navigationController.viewControllers[0] as? ScriptureViewController  {
//                
//                popover.scripture = self.scripture
//                
//                popover.vc = self
//                
//                navigationController.modalPresentationStyle = .popover
//                
//                navigationController.popoverPresentationController?.permittedArrowDirections = .up
//                navigationController.popoverPresentationController?.delegate = self
//                
//                navigationController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
//                
//                //                    popover.navigationItem.title = title
//                
//                popover.navigationController?.isNavigationBarHidden = false
//                
//                present(navigationController, animated: true, completion: nil)
//            }
//            break
//            
//        case Constants.Scripture_in_Browser:
//            openMediaItemScripture(selectedMediaItem)
//            break
//            
//        case Constants.Download_Audio:
//            selectedMediaItem?.audioDownload?.download()
//            break
//            
//        case Constants.Download_All_Audio:
//            for mediaItem in mediaItems! {
//                mediaItem.audioDownload?.download()
//            }
//            break
//            
//        case Constants.Cancel_Audio_Download:
//            selectedMediaItem?.audioDownload?.cancelOrDelete()
//            break
//            
//        case Constants.Cancel_All_Audio_Downloads:
//            for mediaItem in mediaItems! {
//                mediaItem.audioDownload?.cancel()
//            }
//            break
//            
//        case Constants.Delete_Audio_Download:
//            selectedMediaItem?.audioDownload?.delete()
//            break
//            
//        case Constants.Delete_All_Audio_Downloads:
//            for mediaItem in mediaItems! {
//                mediaItem.audioDownload?.delete()
//            }
//            break
//            
//        case Constants.Print:
//            process(viewController: self, work: {
//                return setupMediaItemsHTML(self.mediaItems,includeURLs:false,includeColumns:true)
//            }, completion: { (data:Any?) in
//                printHTML(viewController: self, htmlString: data as? String)
//            })
//            break
//            
//        case Constants.Share:
//            shareHTML(viewController: self, htmlString: mediaItem?.webLink)
//            break
//            
//        case Constants.Share_All:
//            shareMediaItems(viewController: self, mediaItems: mediaItems, stringFunction: setupMediaItemsHTML)
//            break
//            
//        case Constants.Refresh_Document:
//            fallthrough
//        case Constants.Refresh_Transcript:
//            fallthrough
//        case Constants.Refresh_Slides:
//            // This only refreshes the visible document.
//            download?.cancelOrDelete()
//            document?.loaded = false
//            setupDocumentsAndVideo()
//            break
//            
//        default:
//            break
//        }
//    }
//    
//    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose, mediaItem:MediaItem?)
//    {
//        guard Thread.isMainThread else {
//            userAlert(title: "Not Main Thread", message: "MediaViewController:rowClickedAtIndex")
//            return
//        }
//        
//        dismiss(animated: true, completion: nil)
//        
//        guard let strings = strings else {
//            return
//        }
//        
//        switch purpose {
//        case .selectingCellAction:
//            switch strings[index] {
//            case Constants.Download_Audio:
//                mediaItem?.audioDownload?.download()
//                break
//                
//            case Constants.Delete_Audio_Download:
//                mediaItem?.audioDownload?.delete()
//                break
//                
//            case Constants.Cancel_Audio_Download:
//                mediaItem?.audioDownload?.cancelOrDelete()
//                break
//                
//            default:
//                break
//            }
//            break
//            
//        case .selectingAction:
//            actionMenu(action:strings[index],mediaItem:mediaItem)
//            break
//            
//        default:
//            break
//        }
//    }
//}


class MediaViewController: UIViewController
{
    override var preferredFocusEnvironments : [UIFocusEnvironment]
    {
        return [playPauseButton]
    }
    
    var observerActive = false
    var observedItem:AVPlayerItem?

    private var PlayerContext = 0
    
    var player:AVPlayer?
    
    var sliderObserver:Timer?
    
    override var canBecomeFirstResponder : Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (splitViewController == nil) {
            globals.motionEnded(motion,event: event)
        }
    }
    
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
        removePlayerObserver()
        
        if url != nil {
            player = AVPlayer(url: url!)
            
            addPlayerObserver()
        }
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
            } else {
                removePlayerObserver()
//                addSliderObserver() // Crashes because it uses UI and this is done before viewWillAppear when the mediaItemSelected is set in prepareForSegue, but it only happens on an iPhone because the MVC isn't setup already.
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
            switch selectedMediaItem!.playing! {
            case Playing.audio:
                //Do nothing, already selected
                break
                
            case Playing.video:
                if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                    globals.mediaPlayer.stop() // IfPlaying
                    
                    globals.mediaPlayer.view?.isHidden = true
                    
                    setupSpinner()
                    
                    removeSliderObserver()
                    
                    setupPlayPauseButton()
                    setupProgressAndTimes()
                }
                
                selectedMediaItem?.playing = Playing.audio // Must come before setupNoteAndSlides()
                
//                if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
//                    globals.setupPlayer(selectedMediaItem, playOnLoad: false)
//                }
                
                playerURL(url: selectedMediaItem?.playingURL)
                
                setupProgressAndTimes()
                
                // If video was playing we need to show slides or transcript and adjust the STV control to hide the video segment and show the other(s).
                setupVideo() // Calls setupSTVControl()
                break
                
            default:
                break
            }
            break
            
        case Constants.AV_SEGMENT_INDEX.VIDEO:
            switch selectedMediaItem!.playing! {
            case Playing.audio:
                if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                    globals.mediaPlayer.stop() // IfPlaying
                    
                    setupSpinner()
                    
                    removeSliderObserver()
                    
                    setupPlayPauseButton()
                    setupProgressAndTimes()
                }
                
                selectedMediaItem?.playing = Playing.video // Must come before setupNoteAndSlides()
                
//                if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
//                    globals.setupPlayer(selectedMediaItem, playOnLoad: false)
//                }

                playerURL(url: selectedMediaItem?.playingURL)
                
                setupProgressAndTimes()
                
                // Don't need to change the documents (they are already showing) or hte STV control as that will change when the video starts playing.
                break
                
            case Playing.video:
                //Do nothing, already selected
                break
                
            default:
                break
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
        
        globals.mediaPlayer.seek(to: globals.mediaPlayer.currentTime!.seconds - 15)
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
        
        globals.mediaPlayer.seek(to: globals.mediaPlayer.currentTime!.seconds + 15)
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
//        guard (globals.mediaPlayer.state != nil) && (globals.mediaPlayer.mediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) else {
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
//            result = progressIndicator.isHidden // ((wkWebView == nil) || (wkWebView!.isHidden == true)) &&
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
        guard (view != nil) else {
            return
        }
        
        guard (mediaItemNotesAndSlides != nil) else {
            return
        }
        
        guard (tableView != nil) else {
            return
        }
        
        var parentView : UIView!

        parentView = mediaItemNotesAndSlides!
        tableView.isScrollEnabled = true

        if splitViewController?.preferredDisplayMode == .primaryHidden {
            parentView = self.view
        }
        
        view?.isHidden = true
        view?.removeFromSuperview()
        
        view?.frame = parentView.bounds
        
        view?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        if let contain = parentView?.subviews.contains(view!), !contain {
            parentView.addSubview(view!)
        }
        
        //            print(view)
        //            print(view?.superview)
        
        let centerX = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        view?.superview?.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
        view?.superview?.addConstraint(centerY)
        
        let width = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
        view?.superview?.addConstraint(width)
        
        let height = NSLayoutConstraint(item: view!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: view!.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
        view?.superview?.addConstraint(height)
        
        view?.superview?.setNeedsLayout()
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
            
            mediaItemNotesAndSlides.bringSubview(toFront: globals.mediaPlayer.view!)
        }

        if globals.mediaPlayer.playOnLoad {
            if globals.mediaPlayer.mediaItem!.atEnd {
                globals.mediaPlayer.mediaItem!.currentTime = Constants.ZERO
                globals.mediaPlayer.seek(to: 0)
                globals.mediaPlayer.mediaItem?.atEnd = false
            }
            globals.mediaPlayer.playOnLoad = false
            
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
    
    func failedToPlay()
    {
        guard (selectedMediaItem != nil) else {
            return
        }
        
        if (selectedMediaItem == globals.mediaPlayer.mediaItem) {
            if (selectedMediaItem?.showing == Showing.video) {
                globals.mediaPlayer.view?.isHidden = true
                logo.isHidden = false
                mediaItemNotesAndSlides.bringSubview(toFront: logo)
            }
            
            setupSpinner()
            setupProgressAndTimes()
            setupPlayPauseButton()
        }
    }
    
    func showPlaying()
    {
        if (globals.mediaPlayer.mediaItem != nil) && (selectedMediaItem?.multiPartMediaItems?.index(of: globals.mediaPlayer.mediaItem!) != nil) {
            selectedMediaItem = globals.mediaPlayer.mediaItem
            
            tableView.reloadData()
            
            //Without this background/main dispatching there isn't time to scroll correctly after a reload.
            
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
                })
            }
            
            updateUI()
        }
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
        print("menu button pressed")
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MENU), object: nil)
        })
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
    
//    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?)
//    {
//        for press in presses {
//            switch press.type {
//                
//            default:
//                super.pressesEnded(presses, with: event)
//            }
//        }
//    }
    
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
            userAlert(title: "Not Main Thread", message: "MediaViewController:setupDocumentsAndVideo")
            return
        }
        
        guard activityIndicator != nil else {
            return
        }
        
        guard (selectedMediaItem != nil) else {
            globals.mediaPlayer.view?.isHidden = true
            
            logo.isHidden = !shouldShowLogo() // && roomForLogo()
            
            if !logo.isHidden {
                mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
            }
            
//            setupSTVControl()
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
        
        switch selectedMediaItem!.showing! {
        case Showing.video:
            if !selectedMediaItem!.hasVideo {
                selectedMediaItem!.showing = Showing.none
            }
            break
            
        default:
            selectedMediaItem!.showing = Showing.none
            break
        }
        
        switch selectedMediaItem!.showing! {
        case Showing.notes:
            // Should never happen
            break
            
        case Showing.slides:
            // Should never happen
            break
            
        case Showing.video:
            //This should not happen unless it is playing video.
            switch selectedMediaItem!.playing! {
            case Playing.audio:
                logo.isHidden = false
                break

            case Playing.video:
                if (globals.mediaPlayer.mediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                    logo.isHidden = globals.mediaPlayer.loaded
                    globals.mediaPlayer.view?.isHidden = !globals.mediaPlayer.loaded
                    
                    selectedMediaItem?.showing = Showing.video
                    
                    if (globals.mediaPlayer.player != nil) {
//                            mediaItemNotesAndSlides.bringSubview(toFront: globals.mediaPlayer.view!)
                    } else {
                        logo.isHidden = false
                    }
                } else {
                    //This should never happen.
                    logo.isHidden = false
                }
                break
                
            default:
                logo.isHidden = false
                break
            }
            break
            
        case Showing.none:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            
            switch selectedMediaItem!.playing! {
            case Playing.audio:
                globals.mediaPlayer.view?.isHidden = true
                logo.isHidden = false
                break
                
            case Playing.video:
                if (globals.mediaPlayer.mediaItem == selectedMediaItem) {
                    if (globals.mediaPlayer.mediaItem!.hasVideo && (globals.mediaPlayer.mediaItem!.playing == Playing.video)) {
                        if globals.mediaPlayer.loaded {
                            globals.mediaPlayer.view?.isHidden = false
                        }
                        mediaItemNotesAndSlides.bringSubview(toFront: globals.mediaPlayer.view!)
                        selectedMediaItem?.showing = Showing.video
                    } else {
                        globals.mediaPlayer.view?.isHidden = true
                        self.logo.isHidden = false
                        selectedMediaItem?.showing = Showing.none
                        self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                    }
                } else {
                    globals.mediaPlayer.view?.isHidden = true
                    logo.isHidden = false
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
        guard (mediaItem != nil) else {
            return
        }

        var indexPath = IndexPath(row: 0, section: 0)
        
        if mediaItems?.count > 0, let mediaItemIndex = mediaItems?.index(of: mediaItem!) {
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
    
//    func tags(_ object:AnyObject?)
//    {
//        //Present a modal dialog (iPhone) or a popover w/ tableview list of globals.filters
//        //And when the user chooses one, scroll to the first time in that section.
//        
//        //In case we have one already showing
//        dismiss(animated: true, completion: nil)
//        
//        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
//            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
//            let button = object as? UIBarButtonItem
//            
//            navigationController.modalPresentationStyle = .popover
//            
//            navigationController.popoverPresentationController?.permittedArrowDirections = .up
//
//            navigationController.popoverPresentationController?.delegate = self
//            
//            navigationController.popoverPresentationController?.barButtonItem = button
//            
//            popover.navigationItem.title = Constants.Tags
//            
//            popover.delegate = self
//            
//            popover.purpose = .showingTags
//            popover.section.strings = selectedMediaItem?.tagsArray
//            
//            popover.section.showIndex = false
//            popover.section.showHeaders = false
//            
//            popover.allowsSelection = false
//            popover.selectedMediaItem = selectedMediaItem
//            
//            popover.vc = self
//            
//            present(navigationController, animated: true, completion: nil)
//        }
//    }
    
//    func setupActionAndTagsButtons()
//    {
//        guard (selectedMediaItem != nil) else {
//            actionButton = nil
//            tagsButton = nil
//            self.navigationItem.setRightBarButtonItems(nil, animated: true)
//            return
//        }
//
//        var barButtons = [UIBarButtonItem]()
//        
//        actionButton = UIBarButtonItem(title: Constants.FA.ACTION, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.actions))
//        actionButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.show, for: UIControlState.normal)
//
//        barButtons.append(actionButton!)
//    
//        if (selectedMediaItem!.hasTags) {
//            if (selectedMediaItem?.tagsSet?.count > 1) {
//                tagsButton = UIBarButtonItem(title: Constants.FA.TAGS, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.tags(_:)))
//            } else {
//                tagsButton = UIBarButtonItem(title: Constants.FA.TAG, style: UIBarButtonItemStyle.plain, target: self, action: #selector(MediaViewController.tags(_:)))
//            }
//            
//            tagsButton?.setTitleTextAttributes(Constants.FA.Fonts.Attributes.tags, for: UIControlState.normal)
//            
//            barButtons.append(tagsButton!)
//        } else {
//            
//        }
//
//        self.navigationItem.setRightBarButtonItems(barButtons, animated: true)
//    }

    fileprivate func setupTitle()
    {
        let titleString:String?
        
        if splitViewController?.preferredDisplayMode != .primaryHidden {
            if let title = selectedMediaItem?.title {
                titleString = title
            } else {
                titleString = Constants.CBC.LONG
            }
        } else {
            titleString = nil
        }

        if let navBar = navigationController?.navigationBar {
            let labelWidth = navBar.bounds.width - 110
            
            let label = UILabel(frame: CGRect(x:(navBar.bounds.width/2) - (labelWidth/2), y:0, width:labelWidth, height:navBar.bounds.height))
            label.backgroundColor = UIColor.clear
            label.numberOfLines = 0
            label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
            label.textAlignment = .center
            label.textColor = UIColor.black
            label.lineBreakMode = .byWordWrapping
            
            label.text = titleString
            navigationItem.titleView = label
        }
    }
    
    fileprivate func setupAudioOrVideo()
    {
        guard (selectedMediaItem != nil) else {
            audioOrVideoControl.isEnabled = false
            audioOrVideoControl.isHidden = true
            return
        }
        
        if (selectedMediaItem!.hasAudio && selectedMediaItem!.hasVideo) {
            audioOrVideoControl.isEnabled = true
            audioOrVideoControl.isHidden = false
            audioOrVideoWidthConstraint.constant = Constants.AUDIO_VIDEO_MAX_WIDTH
            view.setNeedsLayout()

            audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.AV_SEGMENT_INDEX.AUDIO)
            audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.AV_SEGMENT_INDEX.VIDEO)
            
//                print(selectedMediaItem!.playing!)
            
            switch selectedMediaItem!.playing! {
            case Playing.audio:
                audioOrVideoControl.selectedSegmentIndex = Constants.AV_SEGMENT_INDEX.AUDIO
                break
                
            case Playing.video:
                audioOrVideoControl.selectedSegmentIndex = Constants.AV_SEGMENT_INDEX.VIDEO
                break
                
            default:
                break
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
                //            ((globals.mediaPlayer.url != selectedMediaItem?.videoURL) && (globals.mediaPlayer.url != selectedMediaItem?.audioURL)) {
//                globals.mediaPlayer.killPIP = true
                globals.mediaPlayer.pause()
                globals.setupPlayer(selectedMediaItem,playOnLoad:false)
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
        addSliderObserver()
        
        setupTitle()
        setupAudioOrVideo()
        setupPlayPauseButton()
        setupSpinner()
        setupProgressAndTimes()
        setupVideo()
//        setupActionAndTagsButtons()
    }
    
    func doneSeeking()
    {
//        controlView.sliding = false
        print("DONE SEEKING")
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.failedToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.readyToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.setupPlayPauseButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
        
        if (self.splitViewController != nil) {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.updateView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MediaViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        }

        if (selectedMediaItem != nil) && (globals.mediaPlayer.mediaItem == selectedMediaItem) && globals.mediaPlayer.isPaused && globals.mediaPlayer.mediaItem!.hasCurrentTime() {
            globals.mediaPlayer.seek(to: Double(globals.mediaPlayer.mediaItem!.currentTime!))
        }

        // Forces MasterViewController to show.  App MUST start in preferredDisplayMode == .automatic or the MVC can't be dragged out after it is hidden!
        if (splitViewController?.preferredDisplayMode == .automatic) { // UIDeviceOrientationIsPortrait(UIDevice.current.orientation) &&
            splitViewController?.preferredDisplayMode = .allVisible //iPad only
        }

        updateUI()
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            })
        })
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationItem.rightBarButtonItem = nil
        
        removeSliderObserver()
        removePlayerObserver()

        NotificationCenter.default.removeObserver(self) // Catch-all.
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

//        if let wvc = destination as? WebViewController, let identifier = segue.identifier {
//            switch identifier {
//            case Constants.SEGUE.SHOW_FULL_SCREEN:
//                splitViewController?.preferredDisplayMode = .primaryHidden
//                setupWKContentOffsets()
//                wvc.selectedMediaItem = sender as? MediaItem
////                    wvc.showScripture = showScripture
//                break
//            default:
//                break
//            }
//        }
    }

    fileprivate func setTimes(timeNow:Double, length:Double)
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaViewController:setTimes")
            return
        }
        
//        print("timeNow:",timeNow,"length:",length)
        
        let elapsedHours = Int(timeNow / (60*60))
        let elapsedMins = Int((timeNow - (Double(elapsedHours) * 60*60)) / 60)
        let elapsedSec = Int(timeNow.truncatingRemainder(dividingBy: 60))
        
        var elapsed:String
        
        if (elapsedHours > 0) {
            elapsed = "\(String(format: "%d",elapsedHours)):"
        } else {
            elapsed = Constants.EMPTY_STRING
        }
        
        elapsed = elapsed + "\(String(format: "%02d",elapsedMins)):\(String(format: "%02d",elapsedSec))"
        
        self.elapsed.text = elapsed
        
        let timeRemaining = length - timeNow
        let remainingHours = Int(timeRemaining / (60*60))
        let remainingMins = Int((timeRemaining - (Double(remainingHours) * 60*60)) / 60)
        let remainingSec = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
        
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
                //                            print("slider.value",slider.value)
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
            userAlert(title: "Not Main Thread", message: "MediaViewController:setupSliderAndTimes")
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
            if (player?.currentItem?.status == .readyToPlay) {
                if let length = player?.currentItem?.duration.seconds {
                    let timeNow = Double(selectedMediaItem!.currentTime!)!
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
            } else {
                elapsed.isHidden = true
                remaining.isHidden = true
                progressView.isHidden = true
            }
        }
    }
    
    func sliderTimer()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaViewController:sliderTimer")
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
//                    print("sliderTimer.Interrupted")
//                    break
//                    
//                case .Paused:
//                    print("sliderTimer.Paused")
//                    break
//                    
//                case .Playing:
//                    print("sliderTimer.Playing")
//                    break
//                    
//                case .SeekingBackward:
//                    print("sliderTimer.SeekingBackward")
//                    break
//                    
//                case .SeekingForward:
//                    print("sliderTimer.SeekingForward")
//                    break
//                    
//                case .Stopped:
//                    print("sliderTimer.Stopped")
//                    break
//                }
//            }
    }
    
    func removeSliderObserver()
    {
        sliderObserver?.invalidate()
        sliderObserver = nil
        
        if globals.mediaPlayer.sliderTimerReturn != nil {
            globals.mediaPlayer.player?.removeTimeObserver(globals.mediaPlayer.sliderTimerReturn!)
            globals.mediaPlayer.sliderTimerReturn = nil
        }
    }
    
    func addSliderObserver()
    {
        removeSliderObserver()
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.sliderObserver = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.SLIDER, target: self, selector: #selector(MediaViewController.sliderTimer), userInfo: nil, repeats: true)
        })

//        globals.mediaPlayer.sliderTimerReturn = globals.mediaPlayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1,Constants.CMTime_Resolution), queue: DispatchQueue.main, using: { [weak self] (time:CMTime) in
//            self?.sliderTimer()
//        })
    }

    func playCurrentMediaItem(_ mediaItem:MediaItem?)
    {
        assert(globals.mediaPlayer.mediaItem == mediaItem)
        
        var seekToTime:CMTime?

        if mediaItem!.hasCurrentTime() {
            if mediaItem!.atEnd {
                print("playPause globals.mediaPlayer.currentTime and globals.player.playing!.currentTime reset to 0!")
                mediaItem?.currentTime = Constants.ZERO
                seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
                mediaItem?.atEnd = false
            } else {
                seekToTime = CMTimeMakeWithSeconds(Double(mediaItem!.currentTime!)!,Constants.CMTime_Resolution)
            }
        } else {
            print("playPause selectedMediaItem has NO currentTime!")
            mediaItem!.currentTime = Constants.ZERO
            seekToTime = CMTimeMakeWithSeconds(0,Constants.CMTime_Resolution)
        }

        if seekToTime != nil {
            let loadedTimeRanges = (globals.mediaPlayer.player?.currentItem?.loadedTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime!)
            })

            let seekableTimeRanges = (globals.mediaPlayer.player?.currentItem?.seekableTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                return cmTimeRange.containsTime(seekToTime!)
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

    fileprivate func reloadCurrentMediaItem(_ mediaItem:MediaItem?)
    {
        //This guarantees a fresh start.
        globals.mediaPlayer.playOnLoad = true
        globals.reloadPlayer()
        addSliderObserver()
        setupPlayPauseButton()
    }
    
    fileprivate func playNewMediaItem(_ mediaItem:MediaItem?)
    {
        globals.mediaPlayer.stop() // IfPlaying
        
        globals.mediaPlayer.view?.removeFromSuperview()
        
        guard (mediaItem != nil) && (mediaItem!.hasVideo || mediaItem!.hasAudio) else {
            return
        }
        
        globals.mediaPlayer.mediaItem = mediaItem
        
        globals.mediaPlayer.unload()
        
        setupSpinner()
        
        removeSliderObserver()
        
        //This guarantees a fresh start.
        globals.setupPlayer(mediaItem, playOnLoad: true)
        
        if (mediaItem!.hasVideo && (mediaItem!.playing == Playing.video)) {
            setupPlayerView(globals.mediaPlayer.view)
        }
        
        addSliderObserver()
        
        if (view.window != nil) {
//            setupSTVControl()
            setupProgressAndTimes()
            setupPlayPauseButton()
//            setupActionAndTagsButtons()
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
                if (globals.mediaPlayer.currentTime!.seconds > Double(globals.mediaPlayer.mediaItem!.currentTime!)!) {
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return selectedMediaItem != nil ? (mediaItems != nil ? mediaItems!.count : 0) : 0
    }
    
    /*
     */
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
    
    func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath?
    {
        return tableView.indexPathForSelectedRow
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if (selectedMediaItem != mediaItems![indexPath.row]) || (globals.history == nil) {
            globals.addToHistory(mediaItems![indexPath.row])
        }
        selectedMediaItem = mediaItems![indexPath.row]
        
        setupSpinner()
        setupAudioOrVideo()
        setupPlayPauseButton()
        setupProgressAndTimes()
        setupVideo()
//        setupActionAndTagsButtons()
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
