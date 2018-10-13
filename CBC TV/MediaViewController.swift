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

extension AVPlayerViewController
{
    func menuButtonAction(tap:UITapGestureRecognizer)
    {
        print("MVC menu button pressed")
        
        guard Thread.isMainThread else {
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MENU), object: nil)
    }
}

class MediaViewController: UIViewController, UIGestureRecognizerDelegate
{
    var pageImages:[UIImage]?
    // This may be too memory intensive - keeping all slides ever loaded during one run-time sesssion.
//    {
//        get {
//            return selectedMediaItem?.pageImages
//        }
//        set {
//            selectedMediaItem?.pageImages = newValue
//        }
//    }
    
    var pageNum:Int?
    {
        get {
            if let pageNum = selectedMediaItem?.pageNum {
                return pageNum
            } else {
                if pageImages?.count > 0 {
                    selectedMediaItem?.pageNum = 0
                    return 0
                }
            }
            
            return nil
        }
        set {
            selectedMediaItem?.pageNum = newValue
        }
    }

    func openPDF(url:URL) -> CGPDFDocument?
    {
        let url = CFBridgingRetain(url) as! CFURL
        
        guard let myDocument = CGPDFDocument.init(url) else {
            NSLog("can't open \(url)")
            return nil
        }
        
        if (myDocument.numberOfPages == 0) {
            return nil
        }
    
        return myDocument
    }
    
    func setupPageImages(pdfDocument:CGPDFDocument)
    {
        // Get the total number of pages for the whole PDF document
        let totalPages = pdfDocument.numberOfPages
    
        pageImages = []
        
        // Iterate through the pages and add each page image to an array
        for i in 1...totalPages {
            // Get the first page of the PDF document
            guard let page = pdfDocument.page(at: i) else {
                continue
            }
            
            let pageRect = page.getBoxRect(CGPDFBox.mediaBox)
    
            // Begin the image context with the page size
            // Also get the grapgics context that we will draw to
            UIGraphicsBeginImageContext(pageRect.size)
            guard let context = UIGraphicsGetCurrentContext() else {
                continue
            }
            
            // Rotate the page, so it displays correctly
            context.translateBy(x: 0.0, y: pageRect.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            
            context.concatenate(page.getDrawingTransform(CGPDFBox.mediaBox, rect: pageRect, rotate: 0, preserveAspectRatio: true))
    
            // Draw to the graphics context
            context.drawPDFPage(page)
    
            // Get an image of the graphics context
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()
                pageImages?.append(image)
            }
        }
    }
    
    func hidePageImage()
    {
        guard let pageImages = pageImages, pageImages.count > 0 else {
            return
        }
        
        var view = mediaItemNotesAndSlides
        
        if Globals.shared.mediaPlayer.isZoomed {
            view = splitViewController?.view
        }
        
        for subview in view!.subviews {
            if let subview = subview as? UIImageView, let image = subview.image, subview.classForCoder == UIImageView.classForCoder(), pageImages.contains(image) {
                subview.removeFromSuperview()
            }
        }
    }
    
    @objc func swipeNext(swipe:UISwipeGestureRecognizer)
    {
        guard Globals.shared.mediaPlayer.isZoomed else {
            return
        }
        
        nextSlide()
    }
    
    func nextSlide()
    {
        guard selectedMediaItem?.showing?.range(of: Showing.slides) != nil else {
            return
        }

        guard let pageNum = pageNum else {
            return
        }

        guard let pageImages = pageImages, pageImages.count > 0 else {
            return
        }

        guard pageNum < (pageImages.count - 1) else {
            nextSlidebutton.isEnabled = false
            preferredFocusView = prevSlideButton
            return
        }

        nextSlidebutton.isEnabled = true

        guard pageNum >= 0 else {
            prevSlideButton.isEnabled = false
            preferredFocusView = nextSlidebutton
            return
        }

        prevSlideButton.isEnabled = true

        self.pageNum = pageNum + 1
        showPageImage()
        
        guard self.pageNum < (pageImages.count - 1) else {
            nextSlidebutton.isEnabled = false
            preferredFocusView = prevSlideButton
            return
        }
    }
    
    @objc func swipePrev(swipe:UISwipeGestureRecognizer)
    {
        guard Globals.shared.mediaPlayer.isZoomed else {
            return
        }
        
        prevSlide()
    }
    
    func prevSlide()
    {
        guard selectedMediaItem?.showing?.range(of: Showing.slides) != nil else {
            return
        }

        guard let pageNum = pageNum else {
            return
        }

        guard let pageImages = pageImages, pageImages.count > 0 else {
            return
        }

        guard pageNum <= (pageImages.count - 1) else {
            nextSlidebutton.isEnabled = false
            preferredFocusView = prevSlideButton
            return
        }

        nextSlidebutton.isEnabled = true

        guard pageNum > 0 else {
            prevSlideButton.isEnabled = false
            preferredFocusView = nextSlidebutton
            return
        }

        prevSlideButton.isEnabled = true

        self.pageNum = pageNum - 1
        showPageImage()
        
        guard self.pageNum > 0 else {
            prevSlideButton.isEnabled = false
            preferredFocusView = nextSlidebutton
            return
        }
    }
    
    var swipeNextRecognizer:UISwipeGestureRecognizer?
    var swipePrevRecognizer:UISwipeGestureRecognizer?
    var longPressRecognizer:UILongPressGestureRecognizer?

    func showPageImage()
    {
        guard selectedMediaItem?.showing?.range(of: Showing.slides) != nil else {
            return
        }
        
        guard let pageNum = pageNum else {
            return
        }
        
        guard let pageImages = pageImages, pageImages.count > 0 else {
            return
        }
        
        if pageNum < 0 {
            self.pageNum = 0
        }
        
        if pageNum > (pageImages.count - 1) {
            self.pageNum = pageImages.count - 1
        }

        if pageNum <= 0 {
            prevSlideButton.isEnabled = false
        } else {
            prevSlideButton.isEnabled = true
        }

        if pageNum >= (pageImages.count - 1) {
            nextSlidebutton.isEnabled = false
        } else {
            nextSlidebutton.isEnabled = true
        }

        nextSlidebutton.isHidden = false
        prevSlideButton.isHidden = false
        
        if nextSlidebutton.isEnabled, !prevSlideButton.isEnabled {
            preferredFocusView = nextSlidebutton
        }
        
        if !nextSlidebutton.isEnabled, prevSlideButton.isEnabled {
            preferredFocusView = prevSlideButton
        }
        
        var view:UIView! = mediaItemNotesAndSlides

        if Globals.shared.mediaPlayer.isZoomed, let svcView = splitViewController?.view {
            view = svcView
        }
        
        if swipeNextRecognizer == nil {
            swipeNextRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeNext(swipe:)))
            swipeNextRecognizer?.direction = .left
            swipeNextRecognizer?.delegate = self
            if let swipeNextRecognizer = swipeNextRecognizer {
                splitViewController?.view.addGestureRecognizer(swipeNextRecognizer)
            }
        }
        
        if swipePrevRecognizer == nil {
            swipePrevRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipePrev(swipe:)))
            swipePrevRecognizer?.direction = .right
            swipePrevRecognizer?.delegate = self
            if let swipePrevRecognizer = swipePrevRecognizer {
                splitViewController?.view.addGestureRecognizer(swipePrevRecognizer)
            }
        }

        hidePageImage()
        
        let imgView = UIImageView()
        
        imgView.contentMode = .scaleAspectFit
        imgView.frame = view.bounds
        imgView.backgroundColor = UIColor.lightGray
        imgView.image = pageImages[pageNum]

        view.addSubview(imgView)
        view.bringSubview(toFront: imgView)

        view.bringSubview(toFront: slidesControlView)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)
    {
        if preferredFocusView == splitViewController?.viewControllers[0].view {
            preferredFocusView = nil
        }
    }
    
    var preferredFocusView:UIView?
    {
        didSet {
            guard (preferredFocusView != nil) else {
                return
            }
            
            Thread.onMainThread {
                self.setNeedsFocusUpdate()
            }
        }
    }
    
    override var preferredFocusEnvironments : [UIFocusEnvironment]
        {
        get {
            if let preferredFocusView = preferredFocusView {
                return [preferredFocusView]
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
//            showingSlides = selectedMediaItem?.showing == Showing.slides
            
            if oldValue != nil {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: oldValue)
            }
            
            if (selectedMediaItem != nil) && (selectedMediaItem != Globals.shared.mediaPlayer.mediaItem) {
                Globals.shared.mediaPlayer.stop()
                
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

                Globals.shared.selectedMediaItem.detail = selectedMediaItem
                
                setupTitle()
                
                Thread.onMainThread {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self.selectedMediaItem) //
                }
            } else {
                // We always select, never deselect, so this should not be done.  If we set this to nil it is for some other reason, like clearing the UI.
                //                defaults.removeObjectForKey(Constants.SELECTED_SERMON_DETAIL_KEY)
                mediaItems = nil
            }
            
            if (selectedMediaItem != nil) && (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) {
                removePlayerObserver()
            }
            
            if oldValue != selectedMediaItem {
                pageImages = nil
            }
        }
    }

    var mediaItems:[MediaItem]?

    @IBOutlet weak var slidesControlView: UIStackView!
    
    @IBOutlet weak var prevSlideButton: UIButton!
    {
        didSet {
            prevSlideButton.setTitle(Constants.FA.REWIND)
            prevSlideButton.backgroundColor = UIColor.clear
        }
    }
    @IBAction func prevSlideAction(_ sender: UIButton)
    {
        guard !Globals.shared.mediaPlayer.isZoomed else {
            return
        }
        
        prevSlide()
    }
    
    @IBOutlet weak var nextSlidebutton: UIButton!
    {
        didSet {
            nextSlidebutton.setTitle(Constants.FA.FF)
            nextSlidebutton.backgroundColor = UIColor.clear
        }
    }
    @IBAction func nextSlideAction(_ sender: UIButton)
    {
        guard !Globals.shared.mediaPlayer.isZoomed else {
            return
        }

        nextSlide()
    }
    
    @IBOutlet weak var slidesButton: UIButton!
    {
        didSet {
            slidesButton.setTitle(Constants.FA.SLIDES)
        }
    }
    @IBAction func slidesButtonAction(_ sender: UIButton)
    {
        guard !Globals.shared.mediaPlayer.isZoomed else {
            return
        }

        if selectedMediaItem?.showing?.range(of: Showing.slides) != nil {
            if selectedMediaItem?.playing == Playing.video, Globals.shared.mediaPlayer.mediaItem == selectedMediaItem {
                self.selectedMediaItem?.showing = Showing.video
            } else {
                self.selectedMediaItem?.showing = Showing.none
            }
        } else {
            if let hasSlides = selectedMediaItem?.hasSlides, hasSlides {
                selectedMediaItem?.showing = Showing.slides
            }
        }
        
        updateUI()
    }
    
    
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var audioOrVideoControl: UISegmentedControl!
    @IBOutlet weak var audioOrVideoWidthConstraint: NSLayoutConstraint!
    
    @IBAction func audioOrVideoSelection(sender: UISegmentedControl)
    {
        guard !Globals.shared.mediaPlayer.isZoomed else {
            return
        }
        
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
                    if (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
                        Globals.shared.mediaPlayer.stop() // IfPlaying
                        
                        Globals.shared.mediaPlayer.view?.isHidden = true
                        
                        setupSpinner()
                        
                        removeProgressObserver()
                        
                        setupPlayPauseButton()
                        setupProgressAndTimes()
                    }
                    
                    selectedMediaItem?.playing = Playing.audio // Must come before setupNoteAndSlides()
                    
                    // Unlike CBC on iOS, don't load the player.
//                    if (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
//                        Globals.shared.setupPlayer(selectedMediaItem, playOnLoad: false)
//                    }
                    
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
                    if (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
                        Globals.shared.mediaPlayer.stop() // IfPlaying
                        
                        setupSpinner()
                        
                        removeProgressObserver()
                        
                        setupPlayPauseButton()
                        setupProgressAndTimes()
                    }
                    
                    selectedMediaItem?.playing = Playing.video // Must come before setupNoteAndSlides()
                    
                    // Unlike CBC on iOS, don't load the player.
//                    if (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
//                        Globals.shared.setupPlayer(selectedMediaItem, playOnLoad: false)
//                    }
                    
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

    @IBOutlet weak var playPauseButton: UIButton!
    
    @IBOutlet weak var restartButton: UIButton!
    {
        didSet {
            restartButton.setTitle(Constants.FA.RESTART)
        }
    }
    @IBAction func restartButtonAction(_ sender: UIButton)
    {
        guard !Globals.shared.mediaPlayer.isZoomed else {
            return
        }
        
        guard Globals.shared.mediaPlayer.loaded else {
            return
        }
        
        Globals.shared.mediaPlayer.seek(to: 0)
    }
    
    @IBOutlet weak var skipBackwardButton: UIButton!
    {
        didSet {
            skipBackwardButton.setTitle(Constants.FA.REWIND)
        }
    }
    @IBAction func skipBackwardButtonAction(_ sender: UIButton)
    {
        guard !Globals.shared.mediaPlayer.isZoomed else {
            return
        }

        guard Globals.shared.mediaPlayer.loaded else {
            return
        }
        
        guard let currentTime = Globals.shared.mediaPlayer.currentTime else {
            return
        }
        
        Globals.shared.mediaPlayer.seek(to: currentTime.seconds - Constants.SKIP_TIME_INTERVAL)
    }
    
    @IBOutlet weak var skipForwardButton: UIButton!
    {
        didSet {
            skipForwardButton.setTitle(Constants.FA.FF)
        }
    }
    @IBAction func skipForwardButtonAction(_ sender: UIButton)
    {
        guard !Globals.shared.mediaPlayer.isZoomed else {
            return
        }
        
        guard Globals.shared.mediaPlayer.loaded else {
            return
        }
        
        guard let currentTime = Globals.shared.mediaPlayer.currentTime else {
            return
        }
        
        Globals.shared.mediaPlayer.seek(to: currentTime.seconds + Constants.SKIP_TIME_INTERVAL)
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?)
    {
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
        guard !Globals.shared.mediaPlayer.isZoomed else {
            return
        }
        
        guard (selectedMediaItem != nil) && (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) else {
            playNewMediaItem(selectedMediaItem)
            return
        }

        guard let state = Globals.shared.mediaPlayer.state else {
            return
        }
        
        func showState(_ state:String)
        {
            print(state)
        }
        
        switch state {
        case .none:
            showState("none")
            break
            
        case .playing:
            showState("playing")
            Globals.shared.mediaPlayer.pause()
            setupPlayPauseButton()
            setupSpinner()
            break
            
        case .paused:
            showState("paused")
            if Globals.shared.mediaPlayer.loaded && (Globals.shared.mediaPlayer.url == selectedMediaItem?.playingURL) {
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
            Globals.shared.mediaPlayer.pause()
            setupPlayPauseButton()
            break
            
        case .seekingBackward:
            showState("seekingBackward")
            Globals.shared.mediaPlayer.pause()
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
            result = !Globals.shared.mediaPlayer.loaded
            break
            
        default:
            result = true
            break
        }

        return result
    }

    @IBOutlet weak var elapsed: UILabel!
    @IBOutlet weak var remaining: UILabel!
    
    @IBOutlet weak var mediaItemNotesAndSlides: UIView!

    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    {
        didSet {
            tableView.mask = nil
            tableView.backgroundColor = UIColor.clear
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

        if Globals.shared.mediaPlayer.isZoomed {
            parentView = splitViewController.view
            
            if longPressRecognizer == nil, let selectedMediaItem = selectedMediaItem, selectedMediaItem.playing == Playing.video, Globals.shared.mediaPlayer.mediaItem == selectedMediaItem {
                longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(toggleSlidesPress(longPress:)))
                longPressRecognizer?.delegate = self
                
                if let longPressRecognizer = longPressRecognizer {
                    splitViewController.view.addGestureRecognizer(longPressRecognizer)
                }
            }
        } else {
            if let longPressRecognizer = longPressRecognizer {
                splitViewController.view.removeGestureRecognizer(longPressRecognizer)
                self.longPressRecognizer = nil
            }
        }
        
        view.isHidden = true
        view.removeFromSuperview()
        
        view.frame = parentView.bounds
        
        view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        
        if let contain = parentView?.subviews.contains(view), !contain {
            parentView.addSubview(view)
        }
        
        let centerX = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(centerX)
        
        let centerY = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(centerY)
        
        let width = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(width)
        
        let height = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
        view.superview?.addConstraint(height)
        
        view.superview?.setNeedsLayout()
        
        view.superview?.bringSubview(toFront: view)
    }
    
    @objc func readyToPlay()
    {
        guard Thread.isMainThread else {
            return
        }
        
        guard Globals.shared.mediaPlayer.loaded else {
            return
        }
        
        guard (selectedMediaItem != nil) else {
            return
        }
        
        guard (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) else {
            return
        }

        if Globals.shared.mediaPlayer.playOnLoad {
            if (selectedMediaItem?.playing == Playing.video) && (selectedMediaItem?.showing != Showing.video) {
                if selectedMediaItem?.showing?.range(of: Showing.slides) == nil {
                    selectedMediaItem?.showing = Showing.video
                }
            }
        }
        
        if (selectedMediaItem?.playing == Playing.video) && (selectedMediaItem?.showing == Showing.video) {
            Globals.shared.mediaPlayer.view?.isHidden = false
            
            if let view = Globals.shared.mediaPlayer.view {
                if Globals.shared.mediaPlayer.mediaItem?.showing?.range(of: Showing.slides) == nil {
                    mediaItemNotesAndSlides.bringSubview(toFront: view)
                }
            }
        }

        if Globals.shared.mediaPlayer.playOnLoad {
            if let atEnd = Globals.shared.mediaPlayer.mediaItem?.atEnd, atEnd {
                Globals.shared.mediaPlayer.mediaItem?.currentTime = Constants.ZERO
                Globals.shared.mediaPlayer.seek(to: 0)
                Globals.shared.mediaPlayer.mediaItem?.atEnd = false
            }
            Globals.shared.mediaPlayer.playOnLoad = false
            
            // Just for the delay
            DispatchQueue.global(qos: .background).async(execute: {
                Thread.onMainThread {
                    Globals.shared.mediaPlayer.play()
                }
            })
        }
        
        updateUI()
    }
    
    @objc func paused()
    {
        setupSpinner()
        setupProgressAndTimes()
        setupPlayPauseButton()
    }
    
    @objc func failedToLoad()
    {
        guard (selectedMediaItem != nil) else {
            return
        }
        
        if (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) {
            if (selectedMediaItem?.showing == Showing.video) {
                Globals.shared.mediaPlayer.stop()
            }
            
            updateUI()
        }
    }
    
    @objc func failedToPlay()
    {
        guard (selectedMediaItem != nil) else {
            return
        }
        
        if (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) {
            if (selectedMediaItem?.showing == Showing.video) {
                Globals.shared.mediaPlayer.stop()
            }
            
            updateUI()
        }
    }
    
    @objc func showPlaying()
    {
        guard Thread.isMainThread else {
            return
        }
        
        if let mediaItem = Globals.shared.mediaPlayer.mediaItem, (selectedMediaItem?.multiPartMediaItems?.index(of: mediaItem) != nil) {
            selectedMediaItem = Globals.shared.mediaPlayer.mediaItem
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
    
    @objc func updateView()
    {
        selectedMediaItem = Globals.shared.selectedMediaItem.detail
        
        tableView.isHidden = false
        tableView.reloadData()
        
        //Without this background/main dispatching there isn't time to scroll correctly after a reload.
        
        DispatchQueue.global(qos: .background).async {
            Thread.onMainThread {
                self.scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
            }
        }

        updateUI()
    }
    
    @objc func clearView()
    {
        Thread.onMainThread {
            self.selectedMediaItem = nil
            
            self.tableView.reloadData()
            
            self.updateUI()
        }
    }
    
    @objc func menuButtonAction(tap:UITapGestureRecognizer)
    {
        print("MVC menu button pressed")
        
        guard Thread.isMainThread else {
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MENU), object: nil)
    }
    
    @objc func playPauseButtonAction(tap:UITapGestureRecognizer)
    {
        print("play pause button pressed")
        
        if let state = Globals.shared.mediaPlayer.state {
            switch state {
            case .playing:
                Globals.shared.mediaPlayer.pause()
                
            case .paused:
                Globals.shared.mediaPlayer.play()
                
            case .stopped:
                if (selectedMediaItem != nil) && (Globals.shared.mediaPlayer.mediaItem != selectedMediaItem) {
                    playNewMediaItem(selectedMediaItem)
                }

            default:
                break
            }
        } else {
            if (selectedMediaItem != nil) && (Globals.shared.mediaPlayer.mediaItem != selectedMediaItem) {
                playNewMediaItem(selectedMediaItem)
            }
        }
    }
    
    override func viewDidLoad()
    {
        // Do any additional setup after loading the view.
        super.viewDidLoad()

        let menuPressRecognizer = UITapGestureRecognizer(target: self, action: #selector(menuButtonAction(tap:)))
        menuPressRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        view.addGestureRecognizer(menuPressRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(playPauseButtonAction(tap:)))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue)];
        view.addGestureRecognizer(tapRecognizer)
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true

        if (selectedMediaItem == nil) {
            //Will only happen on an iPad
            selectedMediaItem = Globals.shared.selectedMediaItem.detail
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
            Globals.shared.mediaPlayer.view?.isHidden = true
            return
        }
        
        activityIndicator.isHidden = true

        // Check whether they can or should show what they claim to show!
        
        switch showing {
        case Showing.video:
            if !selectedMediaItem.hasVideo {
                selectedMediaItem.showing = Showing.none
            }
            break

        default:
            if selectedMediaItem.showing?.range(of: Showing.slides) == nil {
                selectedMediaItem.showing = Showing.none
            }
            break
        }
        
        switch showing {
        case Showing.notes:
            // Should never happen
            break
            
        case Showing.video:
            //This should not happen unless it is playing video.
            switch playing {
            case Playing.audio:
                setupPoster()
                break

            case Playing.video:
                if (Globals.shared.mediaPlayer.mediaItem != nil) && (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
                    // Video is in the player
                    logo.isHidden = Globals.shared.mediaPlayer.loaded
                    Globals.shared.mediaPlayer.view?.isHidden = !Globals.shared.mediaPlayer.loaded
                    
                    if selectedMediaItem.showing?.range(of: Showing.slides) == nil {
                        selectedMediaItem.showing = Showing.video
                    }
                    
                    if (Globals.shared.mediaPlayer.player != nil) {
                        // Why is this commented out?
//                        if let view = lobals.mediaPlayer.view {
//                            mediaItemNotesAndSlides.bringSubview(toFront: view)
//                        }
                    } else {
                        setupPoster()
                    }
                } else {
                    // Video is NOT in the player
                    setupPoster()
                }
                break
                
            default:
                if (selectedMediaItem.showing?.range(of: Showing.slides) == nil) {
                    setupPoster()
                }
                break
            }
            break
            
        case Showing.none:
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            
            switch playing {
            case Playing.audio:
                setupPoster()
                break
                
            case Playing.video:
                if (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
                    if let hasVideo = Globals.shared.mediaPlayer.mediaItem?.hasVideo, hasVideo, Globals.shared.mediaPlayer.mediaItem?.playing == Playing.video {
                        if Globals.shared.mediaPlayer.loaded {
                            Globals.shared.mediaPlayer.view?.isHidden = false
                        }
                        if selectedMediaItem.showing?.range(of: Showing.slides) == nil {
                            selectedMediaItem.showing = Showing.video
                            if let view = Globals.shared.mediaPlayer.view {
                                mediaItemNotesAndSlides.bringSubview(toFront: view)
                            }
                        }
                    } else {
                        selectedMediaItem.showing = Showing.none
                        Globals.shared.mediaPlayer.view?.isHidden = true
                        setupPoster()
                    }
                } else {
                    Globals.shared.mediaPlayer.view?.isHidden = true
                    setupPoster()
                }
                break
                
            default:
                break
            }
            break
            
        default:
            if !loadingSlides, (selectedMediaItem.showing?.range(of: Showing.slides) == nil) || (pageImages == nil) {
                setupPoster()
            }
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
    
    @objc func setupPlayPauseButton()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaViewController:setupPlayPauseButton")
            return
        }
        
        guard let selectedMediaItem = selectedMediaItem else  {
            playPauseButton.isEnabled = false
            playPauseButton.isHidden = true
            
            skipForwardButton.isEnabled = playPauseButton.isEnabled
            skipForwardButton.isHidden = playPauseButton.isHidden
            
            skipBackwardButton.isEnabled = playPauseButton.isEnabled
            skipBackwardButton.isHidden = playPauseButton.isHidden
            
            restartButton.isEnabled = playPauseButton.isEnabled
            restartButton.isHidden = playPauseButton.isHidden
            
            return
        }

        func showState(_ state:String)
        {
//            print(state)
        }

        if (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) {
            playPauseButton.isEnabled = Globals.shared.mediaPlayer.loaded || Globals.shared.mediaPlayer.loadFailed
            
            if let state = Globals.shared.mediaPlayer.state {
                switch state {
                case .playing:
                    showState("Playing -> Pause")
                    
                    playPauseButton.setTitle(Constants.FA.PAUSE)
                    break
                    
                case .paused:
                    showState("Paused -> Play")
                  
                    playPauseButton.setTitle(Constants.FA.PLAY)
                    break
                    
                default:
                    break
                }
            }
        } else {
            showState("Global not selected")
            playPauseButton.isEnabled = true

            playPauseButton.setTitle(Constants.FA.PLAY)
        }
        
//        playPauseButton.isEnabled = playPauseButton.isEnabled && (selectedMediaItem.showing?.range(of: Showing.slides) == nil)
        playPauseButton.isHidden = false
        
        skipForwardButton.isEnabled = playPauseButton.isEnabled && Globals.shared.mediaPlayer.loaded
        skipForwardButton.isHidden = playPauseButton.isHidden && Globals.shared.mediaPlayer.loaded
        
        skipBackwardButton.isEnabled = playPauseButton.isEnabled && Globals.shared.mediaPlayer.loaded
        skipBackwardButton.isHidden = playPauseButton.isHidden && Globals.shared.mediaPlayer.loaded
        
        restartButton.isEnabled = playPauseButton.isEnabled && Globals.shared.mediaPlayer.loaded
        restartButton.isHidden = playPauseButton.isHidden && Globals.shared.mediaPlayer.loaded
    }
    
    fileprivate func setupTitle()
    {
        let titleString:String?

        let attrTitleString = NSMutableAttributedString()

        attrTitleString.append(NSAttributedString(string: Constants.CBC.LONG,   attributes: Constants.Fonts.Attributes.title3)) // Grey

        if !Globals.shared.mediaPlayer.isZoomed {
            if let title = selectedMediaItem?.title {
                titleString = title
            } else {
                titleString = Constants.CBC.LONG
            }
        } else {
            titleString = nil
        }

        if titleView != nil, let titleString = titleString {
            for view in titleView.subviews {
                view.removeFromSuperview()
            }
            
            let labelWidth = titleView.bounds.width - 110 // navBar
            
            let label = UILabel(frame: CGRect(x:(titleView.bounds.width/2) - (labelWidth/2), y:0, width:labelWidth, height:titleView.bounds.height)) // navBar
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

                attrTitleString.append(NSAttributedString(string: "\n",   attributes: Constants.Fonts.Attributes.body))
                attrTitleString.append(NSAttributedString(string: titleString,   attributes: Constants.Fonts.Attributes.headline)) // Grey
                label.attributedText = attrTitleString
            }
            
            titleView.addSubview(label)
            
//            navigationItem.titleView = label
        }
    }
    
    fileprivate func setupAudioOrVideo()
    {
        guard let selectedMediaItem = selectedMediaItem else {
            audioOrVideoControl.isEnabled = false
            audioOrVideoControl.isHidden = true
            return
        }
        
        guard selectedMediaItem.hasAudio, selectedMediaItem.hasVideo else {
            audioOrVideoControl.isEnabled = false
            audioOrVideoControl.isHidden = true
            audioOrVideoWidthConstraint.constant = 0
            view.setNeedsLayout()
            return
        }
        
        audioOrVideoControl.isEnabled = true
        audioOrVideoControl.isHidden = false
        audioOrVideoWidthConstraint.constant = Constants.AUDIO_VIDEO_MAX_WIDTH
        view.setNeedsLayout()

        audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.AV_SEGMENT_INDEX.AUDIO)
        audioOrVideoControl.setEnabled(true, forSegmentAt: Constants.AV_SEGMENT_INDEX.VIDEO)
        
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

        if let font = UIFont(name: "FontAwesome", size: 28.0) {
            audioOrVideoControl.setTitleTextAttributes([ NSAttributedStringKey.font: font ], for: .disabled) // Constants.FA.Fonts.Attributes.icons
        }
        if let font = UIFont(name: "FontAwesome", size: 28.0) {
            audioOrVideoControl.setTitleTextAttributes([ NSAttributedStringKey.font: font ], for: .normal) // Constants.FA.Fonts.Attributes.icons
        }
        if let font = UIFont(name: "FontAwesome", size: 34.0) {
            audioOrVideoControl.setTitleTextAttributes([ NSAttributedStringKey.font: font ], for: .selected) // Constants.FA.Fonts.Attributes.icons
        }
        if let font = UIFont(name: "FontAwesome", size: 40.0) {
            audioOrVideoControl.setTitleTextAttributes([ NSAttributedStringKey.font: font ], for: .focused) // Constants.FA.Fonts.Attributes.icons
        }
        if let font = UIFont(name: "FontAwesome", size: 34.0) {
            audioOrVideoControl.setTitleTextAttributes([ NSAttributedStringKey.font: font ], for: .highlighted) // Constants.FA.Fonts.Attributes.icons
        }

        audioOrVideoControl.setTitle(Constants.FA.AUDIO, forSegmentAt: Constants.AV_SEGMENT_INDEX.AUDIO) // Audio
        audioOrVideoControl.setTitle(Constants.FA.VIDEO, forSegmentAt: Constants.AV_SEGMENT_INDEX.VIDEO) // Video
    }
    
    func setupPoster()
    {
        guard let imageView = imageView else {
            logo.isHidden = false
            mediaItemNotesAndSlides.bringSubview(toFront: logo)
            return
        }
        
        if self.selectedMediaItem?.showing != Showing.slides, self.selectedMediaItem?.playing != Playing.video, Globals.shared.mediaPlayer.mediaItem != self.selectedMediaItem {
            startAnimating()
        }

        DispatchQueue.global(qos: .userInitiated).async {
            if let posterImage = self.selectedMediaItem?.posterImage { // (image:UIImage?) in
                Thread.onMainThread {
                    imageView.image = posterImage
                    
                    if self.selectedMediaItem?.showing != Showing.slides, self.selectedMediaItem?.playing != Playing.video, Globals.shared.mediaPlayer.mediaItem != self.selectedMediaItem {
                        self.stopAnimating()
                        self.mediaItemNotesAndSlides.bringSubview(toFront: imageView)
                    }
                    
                    if self.selectedMediaItem?.showing == Showing.slides, self.loadingSlides {
                        self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                    }
                }
            } else {
                Thread.onMainThread {
                    if let showing = self.selectedMediaItem?.showing {
                        switch showing {
                        case Showing.slides:
                            if self.loadingSlides {
                                self.logo.isHidden = false
                                self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                                self.startAnimating()
                            }
                            break
                            
                        case Showing.video:
                            if (Globals.shared.mediaPlayer.mediaItem != self.selectedMediaItem) || !Globals.shared.mediaPlayer.loaded {
                                self.stopAnimating()
                                self.logo.isHidden = false
                                self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                            }
                            break
                            
                        default:
                            self.stopAnimating()
                            self.logo.isHidden = false
                            self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                            break
                        }
                    } else {
                        self.stopAnimating()
                        self.logo.isHidden = false
                        self.mediaItemNotesAndSlides.bringSubview(toFront: self.logo)
                    }
                }
            }
        }
    }
    
    @objc func updateUI()
    {
        if (selectedMediaItem != nil) && (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) {
            if (Globals.shared.mediaPlayer.url != selectedMediaItem?.playingURL) {
                Globals.shared.mediaPlayer.pause()
                Globals.shared.mediaPlayer.setup(selectedMediaItem,playOnLoad:false)
            } else {
                if Globals.shared.mediaPlayer.loadFailed {
                    setupPoster()
                }
            }
        }
        
        //These are being added here for the case when this view is opened and the mediaItem selected is playing already
        addProgressObserver()
        
        setupTitle()
        setupAudioOrVideo()
        setupPlayPauseButton()
        setupSpinner()
        setupProgressAndTimes()

        // From here on the order is critical
        
        setupPoster()
        
        setupPlayerView(Globals.shared.mediaPlayer.view)
        
        setupVideo()
        setupSlides()
    }
    
    @objc func doneSeeking()
    {
        print("DONE SEEKING")
        
        Globals.shared.mediaPlayer.checkDidPlayToEnd()
    }
    
    var loadingSlides = false
    {
        didSet {
            
        }
    }
    
    func setupSlides()
    {
        guard let selectedMediaItem = selectedMediaItem, selectedMediaItem.hasSlides else {
            slidesControlView.isHidden = true
            return
        }
        
        guard selectedMediaItem.showing?.range(of: Showing.slides) != nil else {
            slidesControlView.isHidden = !selectedMediaItem.hasSlides
            mediaItemNotesAndSlides.bringSubview(toFront: slidesControlView)
            nextSlidebutton.isHidden = true
            prevSlideButton.isHidden = true
            hidePageImage()
            return
        }

        slidesControlView.isHidden = false

        if let pageNum = pageNum {
            if pageNum < 0 {
                prevSlideButton.isEnabled = false
            }

            if let pageImages = pageImages {
                if pageNum > (pageImages.count - 1) {
                    nextSlidebutton.isEnabled = false
                }
            }
        }

        if loadingSlides {
            Thread.onMainThread {
                self.startAnimating()
            }
        }
        
        if !loadingSlides, pageImages == nil {
            nextSlidebutton.isHidden = true
            prevSlideButton.isHidden = true
            
            loadingSlides = true
            
            Thread.onMainThread {
                self.startAnimating()
            }
            
            DispatchQueue.global(qos: .background).async {
                let filename = selectedMediaItem.id + "." + "slides"
                
                if let fileSystemURL = cachesURL()?.appendingPathComponent(filename) {
                    let fileManager = FileManager.default

                    if (fileManager.fileExists(atPath: fileSystemURL.path)){
                        if let pdfDocument = self.openPDF(url: fileSystemURL) {
                            self.setupPageImages(pdfDocument: pdfDocument)

                            Thread.onMainThread {
                                if self.selectedMediaItem?.showing?.range(of: Showing.slides) != nil {
                                    self.showPageImage()
                                }

                                self.loadingSlides = false
                                self.stopAnimating()
                            }
                        }
                    } else {
                        if let url = self.selectedMediaItem?.slidesURL {
                            do {
                                let data = try Data(contentsOf: url) // , options: NSData.ReadingOptions.mappedIfSafe
                                print("able to read slides from the URL.")
                                
                                do {
                                    try data.write(to: fileSystemURL)
                                } catch let error as NSError {
                                    print("slides could not be read from the file system.")
                                    NSLog(error.localizedDescription)
                                }

                                if let pdfDocument = self.openPDF(url: fileSystemURL) {
                                    self.setupPageImages(pdfDocument: pdfDocument)

                                    Thread.onMainThread {
                                        if self.selectedMediaItem?.showing?.range(of: Showing.slides) != nil {
                                            self.showPageImage()
                                        }
                                        
                                        self.loadingSlides = false
                                        self.stopAnimating()
                                    }
                                }
                            } catch let error as NSError {
                                print("slides could not be read from the url.")
                                NSLog(error.localizedDescription)
                            }
                        }
                    }
                }
            }
        } else {
            if selectedMediaItem.showing?.range(of: Showing.slides) != nil {
                showPageImage()
            }
        }
    }
    
    func hideSlides()
    {
        if selectedMediaItem?.playing == Playing.video, Globals.shared.mediaPlayer.mediaItem == selectedMediaItem {
            self.selectedMediaItem?.showing = Showing.video
        } else {
            self.selectedMediaItem?.showing = Showing.none
        }
        
        hidePageImage()
    }
    
    @objc func toggleSlidesPress(longPress:UILongPressGestureRecognizer)
    {
        switch longPress.state {
        case .began:
            if selectedMediaItem?.showing?.range(of: Showing.slides) != nil {
                if selectedMediaItem?.playing == Playing.video, Globals.shared.mediaPlayer.mediaItem == selectedMediaItem {
                    self.selectedMediaItem?.showing = Showing.video
                } else {
                    self.selectedMediaItem?.showing = Showing.none
                }
            } else {
                if let hasSlides = selectedMediaItem?.hasSlides, hasSlides {
                    selectedMediaItem?.showing = Showing.slides
                }
            }
            
            toggleSlides()
            
            updateUI()
            break
            
        case .ended:
            break
            
        case .changed:
            break
            
        default:
            break
        }
    }
    
    @objc func toggleSlides()
    {
        if selectedMediaItem?.showing?.range(of: Showing.slides) == nil {
            if let swipeNextRecognizer = swipeNextRecognizer {
                splitViewController?.view.removeGestureRecognizer(swipeNextRecognizer)
            }
            if let swipePrevRecognizer = swipePrevRecognizer {
                splitViewController?.view.removeGestureRecognizer(swipePrevRecognizer)
            }
            swipeNextRecognizer = nil
            swipePrevRecognizer = nil
        }
    }
    
    func addNotifications()
    {
        // Shouldn't some or all of these have object values of selectedMediaItem?

        NotificationCenter.default.addObserver(self, selector: #selector(toggleSlides), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_SLIDES), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleSlides), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.HIDE_SLIDES), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(playPause(_:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PLAY_PAUSE), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(doneSeeking), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DONE_SEEKING), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(showPlaying), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.SHOW_PLAYING), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paused), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PAUSED), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(failedToLoad), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_LOAD), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(failedToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_PLAY), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(readyToPlay), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.READY_TO_PLAY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupPlayPauseButton), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_PLAY_PAUSE), object: nil)
        
        if (splitViewController != nil) {
            NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        logo.isHidden = true
        
        if mediaItems == nil {
            tableView.isHidden = true
        }

        guard Thread.isMainThread else {
            return
        }

        addNotifications()

        if selectedMediaItem != nil, Globals.shared.mediaPlayer.mediaItem == selectedMediaItem, Globals.shared.mediaPlayer.isPaused,
            let hasCurrentTime = Globals.shared.mediaPlayer.mediaItem?.hasCurrentTime, hasCurrentTime,
            let currentTime = Globals.shared.mediaPlayer.mediaItem?.currentTime {
            Globals.shared.mediaPlayer.seek(to: Double(currentTime))
        }

        updateUI()
        
        scrollToMediaItem(self.selectedMediaItem, select: true, position: UITableViewScrollPosition.none)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        setNeedsFocusUpdate()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        removeProgressObserver()
        removePlayerObserver()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        print("didReceiveMemoryWarning: \(String(describing: selectedMediaItem?.title))")
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
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
        if let navCon = destination as? UINavigationController, let visibleViewController = navCon.visibleViewController {
            destination = visibleViewController
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
        guard let state = Globals.shared.mediaPlayer.state else {
            return
        }
        
        guard let length = Globals.shared.mediaPlayer.duration?.seconds, length > 0 else {
            return
        }
        
        guard let playerCurrentTime = Globals.shared.mediaPlayer.currentTime?.seconds, playerCurrentTime >= 0, playerCurrentTime <= length else {
            return
        }

        guard let mediaItemCurrentTime = Globals.shared.mediaPlayer.mediaItem?.currentTime, let playingCurrentTime = Double(mediaItemCurrentTime), playingCurrentTime >= 0, playingCurrentTime <= length else {
            return
        }

        //Crashes if currentPlaybackTime is not a number (NaN) or infinite!  I.e. when nothing has been playing.  This is only a problem on the iPad, I think.
        
        var progress:Double = -1.0
        
        switch state {
        case .playing:
            progress = playerCurrentTime / length
            
            if Globals.shared.mediaPlayer.loaded {
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
            
            progressView.progress = Float(progress)
            setTimes(timeNow: playingCurrentTime,length: length)
            
            elapsed.isHidden = false
            remaining.isHidden = false
            progressView.isHidden = false
            break
            
        case .stopped:
            progress = playingCurrentTime / length
            
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
        
        if (Globals.shared.mediaPlayer.state != .stopped) && (Globals.shared.mediaPlayer.mediaItem == selectedMediaItem) {
            if !Globals.shared.mediaPlayer.loadFailed {
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
    
    @objc func progressTimer()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaViewController:progressTimer")
            return
        }
        
        guard (selectedMediaItem != nil) else {
            return
        }
    
        guard (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) else {
            return
        }
        
        guard let state = Globals.shared.mediaPlayer.state else {
            return
        }
        
        setupPlayPauseButton()
        setupSpinner()
        
        func showState(_ state:String)
        {
//            print(state)
        }
        
        switch state {
        case .none:
            showState("none")
            break
            
        case .playing:
            showState("playing")
            
            setupSpinner()
            
            if Globals.shared.mediaPlayer.loaded {
                setProgressAndTimesToAudio()
                setupPlayPauseButton()
            }
            break
            
        case .paused:
            showState("paused")
            
            setupSpinner()
            
            if Globals.shared.mediaPlayer.loaded {
                setProgressAndTimesToAudio()
                setupPlayPauseButton()
            }
            break
            
        case .stopped:
            showState("stopped")
            break
            
        case .seekingForward:
            showState("seekingForward")
            break
            
        case .seekingBackward:
            showState("seekingBackward")
            break
        }
    }
    
    func removeProgressObserver()
    {
        progressObserver?.invalidate()
        progressObserver = nil
        
        if Globals.shared.mediaPlayer.progressTimerReturn != nil {
            Globals.shared.mediaPlayer.player?.removeTimeObserver(Globals.shared.mediaPlayer.progressTimerReturn!)
            Globals.shared.mediaPlayer.progressTimerReturn = nil
        }
    }
    
    func addProgressObserver()
    {
        removeProgressObserver()
        
        Thread.onMainThread {
            self.progressObserver = Timer.scheduledTimer(timeInterval: Constants.TIMER_INTERVAL.PROGRESS, target: self, selector: #selector(self.progressTimer), userInfo: nil, repeats: true)
        }
    }

    func playCurrentMediaItem(_ mediaItem:MediaItem?)
    {
        guard let mediaItem = mediaItem else {
            return
        }
        
        assert(Globals.shared.mediaPlayer.mediaItem == mediaItem)
        
        var seekToTime:CMTime?

        if mediaItem.hasCurrentTime {
            if mediaItem.atEnd {
                print("playPause Globals.shared.mediaPlayer.currentTime and Globals.shared.player.playing!.currentTime reset to 0!")
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
            let loadedTimeRanges = (Globals.shared.mediaPlayer.player?.currentItem?.loadedTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                if let seekToTime = seekToTime {
                    return cmTimeRange.containsTime(seekToTime)
                } else {
                    return false
                }
            })

            let seekableTimeRanges = (Globals.shared.mediaPlayer.player?.currentItem?.seekableTimeRanges as? [CMTimeRange])?.filter({ (cmTimeRange:CMTimeRange) -> Bool in
                if let seekToTime = seekToTime {
                    return cmTimeRange.containsTime(seekToTime)
                } else {
                    return false
                }
            })

            if (loadedTimeRanges != nil) || (seekableTimeRanges != nil) {
                Globals.shared.mediaPlayer.seek(to: seekToTime?.seconds)

                Globals.shared.mediaPlayer.play()
                
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
        
        Globals.shared.mediaPlayer.stop() // IfPlaying
        
        Globals.shared.mediaPlayer.view?.removeFromSuperview()
        
        Globals.shared.mediaPlayer.mediaItem = mediaItem
        
        Globals.shared.mediaPlayer.unload()
        
        setupSpinner()
        
        removeProgressObserver()
        
        //This guarantees a fresh start.
        Globals.shared.mediaPlayer.setup(mediaItem, playOnLoad: true)
        
        if (mediaItem.hasVideo && (mediaItem.playing == Playing.video)) {
            setupPlayerView(Globals.shared.mediaPlayer.view)
        }
        
        addProgressObserver()
        
        if (view.window != nil) {
            setupProgressAndTimes()
            setupPlayPauseButton()
        }
    }
    
    func stopAnimating()
    {
        guard container != nil else {
            return
        }
        
        guard loadingView != nil else {
            return
        }
        
        guard actInd != nil else {
            return
        }
        
        Thread.onMainThread {
            self.actInd.stopAnimating()
            self.loadingView.isHidden = true
            self.container.isHidden = true
        }
    }
    
    func startAnimating()
    {
        if container == nil {
            setupLoadingView()
        }
        
        guard loadingView != nil else {
            return
        }
        
        guard actInd != nil else {
            return
        }
        
        Thread.onMainThread {
            self.mediaItemNotesAndSlides.bringSubview(toFront: self.container)
            self.container.isHidden = false
            self.loadingView.isHidden = false
            self.actInd.startAnimating()
        }
    }
    
    var container:UIView!
    var loadingView:UIView!
    var actInd:UIActivityIndicatorView!
    
    func setupLoadingView()
    {
        guard (loadingView == nil) else {
            return
        }
        
        guard let loadingViewController = self.storyboard?.instantiateViewController(withIdentifier: "Loading View Controller") else {
            return
        }
        
        guard let containerView = loadingViewController.view else {
            return
        }
        
        container = containerView
        
        loadingView = containerView.subviews[0]
        
        guard let activityIndicator = loadingView.subviews[0] as? UIActivityIndicatorView else {
            container = nil
            loadingView = nil
            return
        }
        
        container.backgroundColor = UIColor.clear
        
        container.frame = mediaItemNotesAndSlides.frame
        container.center = CGPoint(x: mediaItemNotesAndSlides.bounds.width / 2, y: mediaItemNotesAndSlides.bounds.height / 2)
        
        container.isUserInteractionEnabled = false
        
        loadingView.isUserInteractionEnabled = false
        
        actInd = activityIndicator
        
        actInd.isUserInteractionEnabled = false
        
        mediaItemNotesAndSlides.addSubview(container)
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
        
        guard (selectedMediaItem == Globals.shared.mediaPlayer.mediaItem) else {
            if spinner.isAnimating {
                spinner.stopAnimating()
                spinner.isHidden = true
            }
            return
        }
        
        if !Globals.shared.mediaPlayer.loaded && !Globals.shared.mediaPlayer.loadFailed {
            if !spinner.isAnimating {
                spinner.isHidden = false
                spinner.startAnimating()
            }
        } else {
            if Globals.shared.mediaPlayer.isPlaying {
                if let currentTime = Globals.shared.mediaPlayer.mediaItem?.currentTime, let seconds = Double(currentTime), Globals.shared.mediaPlayer.currentTime?.seconds > seconds {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.MULTIPART_MEDIAITEM, for: indexPath) as? MediaTableViewCell ?? MediaTableViewCell()
        
        cell.hideUI()
        
        cell.mediaItem = mediaItems?[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return false
    }
}

extension MediaViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard !Globals.shared.mediaPlayer.isZoomed else {
            return
        }
        
        guard (Globals.shared.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) else {
            print("Player is LIVE STREAMING.")
            return
        }
        
        if let mediaItem = mediaItems?[indexPath.row], (selectedMediaItem != mediaItem) || (Globals.shared.history == nil) {
            Globals.shared.addToHistory(mediaItem)
        }
        
        selectedMediaItem = mediaItems?[indexPath.row]
        
        preferredFocusView = playPauseButton

        updateUI()
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
