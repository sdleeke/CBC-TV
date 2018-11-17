//
//  MediaTableViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation

enum JSONSource
{
    case direct
    case download
}

extension MediaTableViewController : PopoverTableViewControllerDelegate
{
    func handleRefresh()
    {
        setupListActivityIndicator()
        
        Globals.shared.mediaPlayer.unobserve()
        
        Globals.shared.mediaPlayer.pause() // IfPlaying
        
        Globals.shared.clearDisplay()
        
        Globals.shared.search.active = false
        
        tableView?.reloadData()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        
        setupBarButtons()
        
        // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
        Globals.shared.media = Media()
        
        switch jsonSource {
        case .download:
            break
            
        case .direct:
            loadMediaItems()
            {
                    self.loadCompletion()
            }
            break
        }
    }

    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose)
    {
        if !Thread.isMainThread {
            print("NOT MAIN THREAD")
        }
        
        dismiss(animated: true, completion: nil)
        
        guard let string = strings?[index] else {
            return
        }

        switch purpose {
        case .selectingMenu:
            switch string {
            case "Refresh Media":
                handleRefresh()
                break
                
            case "About":
                Globals.shared.mediaPlayer.isZoomed = false
                performSegue(withIdentifier: Constants.SEGUE.SHOW_ABOUT2, sender: self)
                break
                
            case "Search":
                searchAction()
                break
                
            case "Clear Slide Cache":
                removeCacheFiles(fileExtension: "slides")
                break
                
            case "Current Selection":
                Globals.shared.gotoPlayingPaused = true
                Globals.shared.mediaPlayer.isZoomed = false
                
                performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: self)
                break
                
            case "Category":
                mediaCategoryAction()
                break

            case "Series":
                tagAction()
                break
                
            case "Library":
                if (Globals.shared.mediaPlayer.url == URL(string:Constants.URL.LIVE_STREAM)) {
                    Globals.shared.mediaPlayer.view?.removeFromSuperview()
                }

                Globals.shared.gotoPlayingPaused = true
                performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: self)
                break
                
            case "Show Slides":
                if let selectedMediaItem = Globals.shared.selectedMediaItem.detail {
                    selectedMediaItem.showing = Showing.slides
                }

                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.SHOW_SLIDES), object: nil)
                }
                break
                
            case "Previous Slide":
                if let selectedMediaItem = Globals.shared.selectedMediaItem.detail {
                    if let pageNum = selectedMediaItem.pageNum {
                        selectedMediaItem.pageNum = pageNum - 1
                    }
                }
                break
                
            case "Next Slide":
                if let selectedMediaItem = Globals.shared.selectedMediaItem.detail {
                    if let pageNum = selectedMediaItem.pageNum {
                        selectedMediaItem.pageNum = pageNum + 1
                    }
                }
                break
                
            case "Hide Slides":
                if let selectedMediaItem = Globals.shared.selectedMediaItem.detail {
                    if selectedMediaItem.playing == Playing.video, Globals.shared.mediaPlayer.mediaItem == selectedMediaItem {
                        selectedMediaItem.showing = Showing.video
                    } else {
                        selectedMediaItem.showing = Showing.none
                    }
                }
                
                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.HIDE_SLIDES), object: nil)
                }
                break
                
            case "Toggle Zoom":
                if Globals.shared.mediaPlayer.isZoomed {
                    Globals.shared.mediaPlayer.showsPlaybackControls = false
                    Globals.shared.mediaPlayer.controller?.isSkipForwardEnabled = false
                    Globals.shared.mediaPlayer.controller?.isSkipBackwardEnabled = false
                } else {
                    Globals.shared.mediaPlayer.showsPlaybackControls = true
                    Globals.shared.mediaPlayer.controller?.isSkipForwardEnabled = true
                    Globals.shared.mediaPlayer.controller?.isSkipBackwardEnabled = true
                }
                Globals.shared.mediaPlayer.isZoomed = !Globals.shared.mediaPlayer.isZoomed

                if !Globals.shared.mediaPlayer.isZoomed, let subviews = splitViewController?.view.subviews {
                    for view in subviews {
                        if view.classForCoder == UIImageView.classForCoder() {
                            view.removeFromSuperview()
                        }
                    }
                }
                
                setupViews()
                break
                
            case Constants.Strings.Sort:
                sortAction()
                break
                
            case Constants.Strings.Group:
                groupAction()
                break
                
            case Constants.Strings.Index:
                indexAction()
                break

            case Constants.Strings.Live:
                preferredFocusView = nil
                
                if  Globals.shared.streaming.entries?.count > 0, Globals.shared.reachability.isReachable,
                    let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.modalPresentationStyle = .fullScreen
                    
                    popover.navigationItem.title = "Live Events"

                    popover.allowsSelection = true
                    
                    // An enhancement to selectively highlight (select)
                    popover.shouldSelect = { (indexPath:IndexPath) -> Bool in
                        if let keys = popover.section.stringIndex?.keys {
                            let sortedKeys = [String](keys).sorted()
                            return sortedKeys[indexPath.section] == "Playing"
                        }

                        return false
                    }
                    
                    // An alternative to rowClickedAt
                    popover.didSelect = { (indexPath:IndexPath) -> Void in
                        if let keys = popover.section.stringIndex?.keys {
                            let sortedKeys = [String](keys).sorted()
                            
                            let key = sortedKeys[indexPath.section]
                            
                            if key == "Playing" {
                                self.dismiss(animated: true, completion: nil)
                                
                                if let streamEntry = StreamEntry(Globals.shared.streaming.entryIndex?[key]?[indexPath.row]) {
                                    self.performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: streamEntry)
                                }
                            }
                        }
                    }
                    
                    // Makes no sense w/o section.showIndex also being true - UNLESS you're using section.stringIndex
                    popover.section.showHeaders = true
                    
                    present(navigationController, animated: true, completion: {
                        popover.startAnimating()

                        self.loadLive() {
                            popover.section.stringIndex = Globals.shared.streaming.stringIndex
                            popover.tableView.reloadData()

                            popover.stopAnimating()

                            popover.setPreferredContentSize()
                        }
                    })
                }

                break
                
            default:
                break
            }
            break
            
        case .selectingCategory:
            guard (Globals.shared.mediaCategory.selected != string) || (Globals.shared.mediaRepository.list == nil) else {
                return
            }
            
            Globals.shared.mediaCategory.selected = string
            
            Globals.shared.mediaPlayer.unobserve()
            
            let liveStream = Globals.shared.mediaPlayer.url == URL(string: Constants.URL.LIVE_STREAM)
            
            Globals.shared.mediaPlayer.pause() // IfPlaying
            
            Globals.shared.clearDisplay()
            
            tableView.reloadData()
            
            if splitViewController != nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
            }
            
            //                    tagLabel.text = nil
            
            // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
            Globals.shared.media = Media()
            
            loadMediaItems()
                {
                    if liveStream {
                        Thread.onMainThread {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
                        }
                    }
                    
                    if Globals.shared.mediaRepository.list == nil {
                        let alert = UIAlertController(title: "No media available.",
                                                      message: "Please check your network connection and try again.",
                                                      preferredStyle: UIAlertControllerStyle.alert)

                        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                            self.setupListActivityIndicator()
                        })
                        alert.addAction(action)

                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.selectedMediaItem = Globals.shared.selectedMediaItem.master
                        
                        if Globals.shared.search.active && !Globals.shared.search.complete {
                            self.updateSearchResults(Globals.shared.search.text,completion: {
                                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                    Thread.onMainThread {
                                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                                    }
                                })
                            })
                        } else {
                            // Reload the table
                            self.tableView.reloadData()
                            
                            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                Thread.onMainThread {
                                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                                }
                            })
                        }
                    }
                    
                    self.tableView.isHidden = false
            }
            break
            
        case .selectingSorting:
            if let sorting = Constants.SortingTitles.index(of: string) {
                Globals.shared.sorting = Constants.sortings[sorting]
            }
            
            if (Globals.shared.media.need.sorting) {
                Globals.shared.isSorting = true
                
                Globals.shared.clearDisplay()
                
                Thread.onMainThread {
                    self.tableView.reloadData()
                    
                    self.startAnimating()
                    
                    self.disableBarButtons()
                    
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                        Globals.shared.setupDisplay(Globals.shared.media.active)
                        
                        Thread.onMainThread {
                            Globals.shared.isSorting = false
                            
                            self.tableView.reloadData()
                            
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top) // was Middle
                            
                            self.stopAnimating()
                            
                            self.enableBarButtons()
                            
                            self.preferredFocusView = self.tableView
                        }
                    })
                }
            }
            break
            
        case .selectingGrouping:
            if let grouping = Globals.shared.groupingTitles.index(of: string) {
                Globals.shared.grouping = Globals.shared.groupings[grouping]
            }
            
            if Globals.shared.media.need.grouping {
                Globals.shared.isGrouping = true
                
                Globals.shared.clearDisplay()
                
                self.tableView.reloadData()
                
                self.startAnimating()
                
                self.disableBarButtons()
                
                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                    Globals.shared.setupDisplay(Globals.shared.media.active)
                    
                    Thread.onMainThread {
                        Globals.shared.isGrouping = false
                        
                        self.tableView.reloadData()
                        
                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                        
                        self.stopAnimating()
                        
                        self.enableBarButtons()
                        
                        self.preferredFocusView = self.tableView
                    }
                })
            }
            break
            
        case .selectingSection:
            let indexPath = IndexPath(row: 0, section: index)
            
            if !(indexPath.section < self.tableView.numberOfSections) {
                NSLog("indexPath section ERROR in MTVC .selectingSection")
                NSLog("Section: \(indexPath.section)")
                NSLog("TableView Number of Sections: \(self.tableView.numberOfSections)")
            }
            
            if !(indexPath.row < self.tableView.numberOfRows(inSection: indexPath.section)) {
                NSLog("indexPath row ERROR in MTVC .selectingSection")
                NSLog("Section: \(indexPath.section)")
                NSLog("TableView Number of Sections: \(self.tableView.numberOfSections)")
                NSLog("Row: \(indexPath.row)")
                NSLog("TableView Number of Rows in Section: \(self.tableView.numberOfRows(inSection: indexPath.section))")
            }
            
            self.tableView.setEditing(false, animated: true)
            
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.top)
            self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: true)
            
            self.preferredFocusView = self.tableView
            break
            
        case .selectingTags:
            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                var new:Bool = false
                
                switch string {
                case Constants.All:
                    if (Globals.shared.media.tags.showing != Constants.ALL) {
                        new = true
                        Globals.shared.media.tags.selected = nil
                    }
                    break
                    
                default:
                    //Tagged
                    
                    let tagSelected = string
                    
                    new = (Globals.shared.media.tags.showing != Constants.TAGGED) || (Globals.shared.media.tags.selected != tagSelected)
                    
                    if (new) {
                        Globals.shared.media.tags.selected = tagSelected
                    }
                    break
                }
                
                if (new) {
                    Thread.onMainThread {
                        Globals.shared.clearDisplay()
                        
                        self.tableView.reloadData()
                        
                        self.startAnimating()
                        
                        self.disableBarButtons()
                    }
                    
                    if (Globals.shared.search.active) {
                        self.updateSearchResults(Globals.shared.search.text,completion: nil)
                    }
                    
                    Thread.onMainThread {
                        Globals.shared.setupDisplay(Globals.shared.media.active)
                        
                        self.tableView.reloadData()
                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                        
                        self.stopAnimating()
                        
                        self.enableBarButtons()
                        
                        self.setupTag()
                    }
                }
            })
            break
        }
    }
}

class MediaTableViewControllerHeaderView : UITableViewHeaderFooterView
{
    var label : UILabel?
}

class MediaTableViewController : UIViewController
{
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)
    {
        if preferredFocusView == splitViewController?.viewControllers[1].view {
            preferredFocusView = nil
        }
    }
    
    var changesPending = false
    
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
                return [tableView]
            }
        }
    }
    
    var jsonSource:JSONSource = .direct
    
    @IBOutlet weak var mediaCategoryLabel: UILabel!
    
    @IBOutlet weak var tagLabel: UILabel!
    
    func mediaCategoryAction()
    {
        print("categoryButtonAction")
        
        if !Thread.isMainThread {
            print("NOT MAIN THREAD")
        }
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .fullScreen
            
            popover.navigationItem.title = "Categories"
            
            popover.delegate = self
            
            popover.purpose = .selectingCategory
            
            popover.section.strings = Globals.shared.mediaCategory.names
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            present(navigationController, animated: true, completion: nil )
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    {
        didSet {
            tableView.register(MediaTableViewControllerHeaderView.self, forHeaderFooterViewReuseIdentifier: "MediaTableViewController")

            tableView.mask = nil
            tableView.backgroundColor = UIColor.clear
        }
    }
    
    func sortAction()
    {
        if !Thread.isMainThread {
            print("NOT MAIN THREAD")
        }
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .fullScreen
            
            popover.navigationItem.title = "Sort By"
            
            popover.delegate = self
            
            popover.purpose = .selectingSorting
            
            popover.section.strings = Constants.SortingTitles
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            present(navigationController, animated: true, completion: nil )
        }
    }
    
    func groupAction()
    {
        if !Thread.isMainThread {
            print("NOT MAIN THREAD")
        }
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .fullScreen
            
            popover.navigationItem.title = "Group By"
            
            popover.delegate = self
            
            popover.purpose = .selectingGrouping
            
            popover.section.strings = Globals.shared.groupingTitles
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            present(navigationController, animated: true, completion: nil )
        }
    }
    
    func indexAction()
    {
        if !Thread.isMainThread {
            print("NOT MAIN THREAD")
        }
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .fullScreen
            
            popover.navigationItem.title = "Index"
            
            popover.delegate = self
            
            popover.purpose = .selectingSection
            
            popover.section.strings = Globals.shared.media.active?.section?.headerStrings
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            present(navigationController, animated: true, completion: nil )
        }
    }
    
    var selectedMediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            Globals.shared.selectedMediaItem.master = selectedMediaItem
        }
    }
    
    func disableBarButtons()
    {
        Thread.onMainThread {
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    func enableBarButtons()
    {
        Thread.onMainThread {
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    func setupViews()
    {
        Thread.onMainThread {
            self.tableView.reloadData()
        }
        
        setupTitle()
        
        selectedMediaItem = Globals.shared.selectedMediaItem.master
        
        //Without this background/main dispatching there isn't time to scroll after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            Thread.onMainThread {
                self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle) // was Middle

                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                    Thread.onMainThread {
                        self.preferredFocusView = self.tableView
                    }
                })
            }
        })
        
        if (splitViewController != nil) {
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            }
        }
    }

    func jsonAlert(title:String,message:String)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) {
            Thread.onMainThread {
                let alert = UIAlertController(title:title,
                                              message:message,
                                              preferredStyle: UIAlertControllerStyle.alert)
                
                let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                    
                })
                alert.addAction(action)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func loadJSONDictsFromCachesDirectory(key:String) -> [[String:String]]?
    {
        var mediaItemDicts = [[String:String]]()
        
        //  jsonDataFromCachesDirectory()
        if let json = Globals.shared.mediaCategory.filename?.fileSystemURL?.data?.json as? [String:Any] {
            if let mediaItems = json[key] as? [[String:String]] {
                for i in 0..<mediaItems.count {
                    
                    var dict = [String:String]()
                    
                    for (key,value) in mediaItems[i] {
                        dict[key] = "\(value)"
                    }
                    
                    mediaItemDicts.append(dict)
                }
                
                return mediaItemDicts.count > 0 ? mediaItemDicts : nil
            }
        } else {
            print("could not get json from file, make sure that file contains valid json.")
        }
        
        return nil
    }
    
    lazy var jsonQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "JSON"
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    func jsonFromURL(urlString:String?,filename:String?) -> Any?
    {
        guard Globals.shared.reachability.isReachable else {
            return nil
        }
        
        guard let json = filename?.fileSystemURL?.data?.json else {
            // BLOCKS
            let data = urlString?.url?.data
            
            jsonQueue.addOperation {
                data?.save(to: filename?.fileSystemURL)
            }
            
            return data?.json
        }
        
        jsonQueue.addOperation {
            urlString?.url?.data?.save(to: filename?.fileSystemURL)
        }
        
        return json
    }
    
    func loadJSONDictsFromURL(urlString:String,key:String,filename:String) -> [[String:String]]?
    {
        var mediaItemDicts = [[String:String]]()
        
        if let json = jsonFromURL(urlString: urlString, filename: filename) as? [String:Any] {
            if let mediaItems = json[key] as? [[String:String]] {
                for i in 0..<mediaItems.count {
                    
                    var dict = [String:String]()
                    
                    for (key,value) in mediaItems[i] {
                        dict[key] = "\(value)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    }
                    
                    mediaItemDicts.append(dict)
                }
                
                //            print(mediaItemDicts)
                
                return mediaItemDicts.count > 0 ? mediaItemDicts : nil
            }
        } else {
            print("could not get json from URL, make sure that URL contains valid json.")
        }
        
        return nil
    }
    
    func mediaItemsFromMediaItemDicts(_ mediaItemDicts:[[String:String]]?) -> [MediaItem]?
    {
        if (mediaItemDicts != nil) {
            return mediaItemDicts?.map({ (mediaItemDict:[String : String]) -> MediaItem in
                MediaItem(storage: mediaItemDict)
            })
        }
        
        return nil
    }
    
    var liveEvents:[String:Any]?
    {
        get {
            return Constants.URL.LIVE_EVENTS.url?.data?.json as? [String:Any]
        }
    }
    
    func loadLive(completion:(()->(Void))?)
    {
        DispatchQueue.global(qos: .background).async() {
            Thread.sleep(forTimeInterval: 0.25)

            Globals.shared.streaming.entries = self.liveEvents?["streamEntries"] as? [[String:Any]]
            
            Thread.onMainThread(block: {
                completion?()
            })
        }
    }
    
    func loadCategories()
    {
        if let categoriesDicts = self.loadJSONDictsFromURL(urlString: Constants.JSON.URL.CATEGORIES,key:Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES,filename: Constants.JSON.FILENAME.CATEGORIES) {
            var mediaCategoryDicts = [String:String]()
            
            for categoriesDict in categoriesDicts {
                if let category = categoriesDict["category_name"] {
                    mediaCategoryDicts[category] = categoriesDict["id"]
                }
            }
            
            Globals.shared.mediaCategory.dicts = mediaCategoryDicts
        }
    }

    lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "MCVC:" + UUID().uuidString
        operationQueue.qualityOfService = .userInitiated
        operationQueue.maxConcurrentOperationCount = 1 // Slides and Notes
        return operationQueue
    }()
    
    func loadMediaItems(completion: (() -> Void)?)
    {
        Globals.shared.isLoading = true
        
        operationQueue.cancelAllOperations()
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        let operation = CancellableOperation { (test:(()->(Bool))?) in
//        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            self.setupCategory()
            self.setupTag()
            
            self.setupBarButtons()
            self.setupListActivityIndicator()

            Thread.onMainThread {
                self.navigationItem.title = Constants.Title.Loading_Media
            }
            
            self.loadLive(completion: nil)
            
            var url:String?

            if Globals.shared.mediaCategory.selected != nil, let selectedID = Globals.shared.mediaCategory.selectedID {
                url = Constants.JSON.URL.CATEGORY + selectedID
            }

            if let url = url {
                switch self.jsonSource {
                case .download:
                    // From Caches Directory
                    if let mediaItemDicts = self.loadJSONDictsFromCachesDirectory(key: Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES) {
                        Globals.shared.mediaRepository.list = self.mediaItemsFromMediaItemDicts(mediaItemDicts)
                    }
                    break
                    
                case .direct:
                    // From URL
                    print(Globals.shared.mediaCategory.filename as Any)
                    if let filename = Globals.shared.mediaCategory.filename, let mediaItemDicts = self.loadJSONDictsFromURL(urlString: url,key: Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES,filename: filename) {
                        Globals.shared.mediaRepository.list = self.mediaItemsFromMediaItemDicts(mediaItemDicts)
                    } else {
                        Globals.shared.mediaRepository.list = nil
                        print("FAILED TO LOAD")
                    }
                    break
                }
            }
            
//            testMediaItemsTagsAndSeries()
//            
//            testMediaItemsBooksAndSeries()
//            
//            testMediaItemsForSeries()
//            
//            //We can test whether the PDF's we have, and the ones we don't have, can be downloaded (since we can programmatically create the missing PDF filenames).
//            testMediaItemsPDFs(testExisting: false, testMissing: true, showTesting: false)
//
//            //Test whether the audio starts to download
//            //If we can download at all, we assume we can download it all, which allows us to test all mediaItems to see if they can be downloaded/played.
//            testMediaItemsAudioFiles()

            Thread.onMainThread {
                self.navigationItem.title = Constants.Title.Loading_Settings
            }
            Globals.shared.loadSettings()
            
            Thread.onMainThread {
                self.navigationItem.title = Constants.Title.Sorting_and_Grouping
            }
            
            Globals.shared.media.all = MediaListGroupSort(mediaItems: Globals.shared.mediaRepository.list)

            if Globals.shared.search.valid {
                Globals.shared.search.complete = false
            }

            Globals.shared.setupDisplay(Globals.shared.media.active)
            
            Thread.onMainThread {
                self.navigationItem.title = Constants.Title.Setting_up_Player
                
                if (Globals.shared.mediaPlayer.mediaItem != nil) {
                    // This MUST be called on the main loop.
                    Globals.shared.mediaPlayer.setup(Globals.shared.mediaPlayer.mediaItem,playOnLoad:false)
                }

                self.setupTitle()
                
                self.setupViews()
                
                self.setupListActivityIndicator()

                Globals.shared.isLoading = false
                
                completion?()

                self.setupBarButtons()

                self.setupTag()
                self.setupCategory()
                
                self.setupListActivityIndicator()
            }
        }
            
        operationQueue.addOperation(operation)
    }
    
    func setupCategory()
    {
        Thread.onMainThread {
            self.mediaCategoryLabel.text = Globals.shared.mediaCategory.selected
        }
    }
    
    func setupBarButtons()
    {
        if Globals.shared.isLoading {
            disableBarButtons()
        } else {
            if (Globals.shared.mediaRepository.list != nil) {
                enableBarButtons()
            }
        }
    }
    
    func setupListActivityIndicator()
    {
        if Globals.shared.isLoading || Globals.shared.isSorting || Globals.shared.isGrouping || (Globals.shared.search.active && !Globals.shared.search.complete) {
            Thread.onMainThread {
                self.startAnimating()
            }
        } else {
            Thread.onMainThread {
                self.stopAnimating()
            }
        }
    }
    
    @objc func updateList()
    {
        Globals.shared.setupDisplay(Globals.shared.media.active)
        Thread.onMainThread {
            self.tableView.reloadData()
        }
    }
    
    var container:UIView!
    var loadingView:UIView!
    var actInd:UIActivityIndicatorView!

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
            self.container.isHidden = false
            self.loadingView.isHidden = false
            self.actInd.startAnimating()
        }
    }
    
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
        
        container.frame = view.frame
        container.center = CGPoint(x: view.bounds.width / 2 + tableView.frame.origin.x, y: view.bounds.height / 2)
        
        container.isUserInteractionEnabled = false
        
        loadingView.isUserInteractionEnabled = false
        
        actInd = activityIndicator

        actInd.isUserInteractionEnabled = false
        
        view.addSubview(container)
    }

    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(menuButtonAction(tap:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MENU), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateList), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSearch), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_SEARCH), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PLAYER_VIEW), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
   
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        addNotifications()
        
        let menuPressRecognizer = UITapGestureRecognizer(target: self, action: #selector(menuButtonAction(tap:)))
        menuPressRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        view.addGestureRecognizer(menuPressRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(playPauseButtonAction(tap:)))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue)];
        view.addGestureRecognizer(tapRecognizer)
        
        // Globals.shared.mediaRepository.list == nil in didBecomeActive
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        tableView?.allowsSelection = true
    }
    
    func updateDisplay(searchText:String?)
    {
        guard let searchText = searchText?.uppercased() else {
            return
        }
        
        if !Globals.shared.search.active || (Globals.shared.search.text?.uppercased() == searchText) {
            Globals.shared.setupDisplay(Globals.shared.media.active)
        } else {

        }
        
        Thread.onMainThread {
            if !self.tableView.isEditing {
                self.tableView.reloadData()
            } else {
                self.changesPending = true
            }
        }
    }

    func updateSearches(searchText:String?,mediaItems: [MediaItem]?)
    {
        guard let searchText = searchText?.uppercased() else {
            return
        }
        
        if Globals.shared.media.toSearch?.searches == nil {
            Globals.shared.media.toSearch?.searches = [String:MediaListGroupSort]()
        }
        
        Globals.shared.media.toSearch?.searches?[searchText] = MediaListGroupSort(mediaItems: mediaItems)
    }
    
    func updateSearchResults(_ searchText:String?,completion: (() -> Void)?)
    {
        guard let searchText = searchText?.uppercased() else {
            return
        }
        
        guard !searchText.isEmpty else {
            return
        }
        
        guard (Globals.shared.media.toSearch?.searches?[searchText] == nil) else {
            updateDisplay(searchText:searchText)
            setupListActivityIndicator()
            setupBarButtons()
            
            setupCategory()
            setupTag()
            
            return
        }
        
        Globals.shared.search.complete = false

        Globals.shared.clearDisplay()

        Thread.onMainThread {
            self.tableView.reloadData()
        }

        self.setupBarButtons()
        
        self.setupCategory()
        self.setupTag()

        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            var searchMediaItems:[MediaItem]?
            
            if let mediaItems = Globals.shared.media.toSearch?.list {
                for mediaItem in mediaItems {
                    Globals.shared.search.complete = false
                    
                    self.setupListActivityIndicator()
                    
                    let searchHit = mediaItem.search(searchText)
                    if searchHit {
                        if searchMediaItems == nil {
                            searchMediaItems = [mediaItem]
                        } else {
                            searchMediaItems?.append(mediaItem)
                        }
                    }
                }
            }
            
            // Final search update since we're only doing them in batches of Constants.SEARCH_RESULTS_BETWEEN_UPDATES
            
            self.updateSearches(searchText:searchText,mediaItems: searchMediaItems)
            self.updateDisplay(searchText:searchText)
            
            Thread.onMainThread {
                completion?()
                
                Globals.shared.search.complete = true
                
                self.setupListActivityIndicator()
                self.setupBarButtons()
                self.setupCategory()
                self.setupTag()
            }
        })
    }

    func selectOrScrollToMediaItem(_ mediaItem:MediaItem?, select:Bool, scroll:Bool, position: UITableViewScrollPosition)
    {
        guard !tableView.isEditing else {
            return
        }
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        guard let grouping = Globals.shared.grouping else {
            return
        }
        
        guard let indexStrings = Globals.shared.media.active?.section?.indexStrings else {
            return
        }
        
        guard let mediaItems = Globals.shared.media.active?.mediaItems else {
            return
        }
        
        guard let index = mediaItems.index(of: mediaItem) else {
            //            print(mediaItem)
            return
        }
        
        var indexPath = IndexPath(item: 0, section: 0)
        
        var section:Int = -1
        var row:Int = -1
        
        var sectionIndex : String?
        
        switch grouping {
        case GROUPING.YEAR:
            sectionIndex = mediaItem.yearSection
            break
            
        case GROUPING.TITLE:
            sectionIndex = mediaItem.multiPartSectionSort
            break
            
        case GROUPING.BOOK:
            // For mediaItem.books.count > 1 this arbitrarily selects the first one, which may not be correct.
            sectionIndex = mediaItem.bookSections.first
            break
            
        case GROUPING.SPEAKER:
            sectionIndex = mediaItem.speakerSectionSort
            break
            
        case GROUPING.CLASS:
            sectionIndex = mediaItem.classSectionSort
            break
            
        case GROUPING.EVENT:
            sectionIndex = mediaItem.eventSectionSort
            break
            
        default:
            break
        }
        
        if let sectionIndex = sectionIndex, let stringIndex = indexStrings.index(of: sectionIndex) {
            section = stringIndex
        }
        
        if let sectionIndexes = Globals.shared.media.active?.sectionIndexes {
            row = index - sectionIndexes[section]
        }

        //            print(section)
        
        if (section > -1) && (row > -1) {
            indexPath = IndexPath(row: row,section: section)
            
            guard (indexPath.section < tableView.numberOfSections) else {
                NSLog("indexPath section ERROR in selectOrScrollToMediaItem")
                NSLog("Section: \(indexPath.section)")
                NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                return
            }
            
            guard indexPath.row < tableView.numberOfRows(inSection: indexPath.section) else {
                NSLog("indexPath row ERROR in selectOrScrollToMediaItem")
                NSLog("Section: \(indexPath.section)")
                NSLog("TableView Number of Sections: \(tableView.numberOfSections)")
                NSLog("Row: \(indexPath.row)")
                NSLog("TableView Number of Rows in Section: \(tableView.numberOfRows(inSection: indexPath.section))")
                return
            }

            Thread.onMainThread {
                self.tableView.setEditing(false, animated: true)
            }

            if (select) {
                Thread.onMainThread {
                    self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
                }
            }
            
            if (scroll) {
                //Scrolling when the user isn't expecting it can be jarring.
                Thread.onMainThread {
                    self.tableView.scrollToRow(at: indexPath, at: position, animated: false)
                }
            }
        }
    }

    
    fileprivate func setupTag()
    {
        guard let showing = Globals.shared.media.tags.showing else {
            return
        }
        
        Thread.onMainThread {
            switch showing {
            case Constants.ALL:
                self.tagLabel.text = Constants.All
                break
                
            case Constants.TAGGED:
                self.tagLabel.text = Globals.shared.media.tags.selected
                break
                
            default:
                break
            }
        }
    }
    
    fileprivate func setupTitle()
    {
        let titleString : String?
        
        let attrTitleString = NSMutableAttributedString()
        
        attrTitleString.append(NSAttributedString(string: "Media",   attributes: Constants.Fonts.Attributes.title3Grey))
        
        if !Globals.shared.mediaPlayer.isZoomed {
            titleString = Constants.CBC.SHORT
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

            label.text = titleString
            
            attrTitleString.append(NSAttributedString(string: "\n",   attributes: Constants.Fonts.Attributes.body))
            attrTitleString.append(NSAttributedString(string: " ",   attributes: Constants.Fonts.Attributes.headline))

            label.attributedText = attrTitleString
            
            navigationItem.titleView = label
        }
    }

    @objc func updateSearch()
    {
        guard Globals.shared.search.valid else {
            return
        }
        
        updateSearchResults(Globals.shared.search.text,completion: nil)
    }
    
    @objc func liveView()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: self)
    }
    
    @objc func playerView()
    {
        Globals.shared.gotoPlayingPaused = true
        performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: self)
    }

    func endSearch()
    {
        Globals.shared.search.active = false
        Globals.shared.search.text = nil
        
        Globals.shared.clearDisplay()
        
        Globals.shared.setupDisplay(Globals.shared.media.active)
        
        self.tableView.reloadData()
    }
    
    func searchAction()
    {
        guard Thread.isMainThread else {
            return
        }
        
        let alert = UIAlertController(title: "Search",
                                      message: Constants.EMPTY_STRING,
                                      preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField:UITextField) in
            if Globals.shared.search.active {
                textField.text = Globals.shared.search.text
            } else {
                textField.placeholder = "search string"
            }
        })
        
        let searchAction = UIAlertAction(title: "Search", style: UIAlertActionStyle.default, handler: {
            alertItem -> Void in
            if let searchText = alert.textFields?[0].text {
                print(searchText)
                
                if (searchText != Constants.EMPTY_STRING) { //
                    Globals.shared.search.active = true
                    Globals.shared.search.text = searchText.uppercased()
                    
                    self.updateSearchResults(searchText,completion: nil)
                } else {
                    self.endSearch()
                }
            } else {
                self.endSearch()
            }
        })
        alert.addAction(searchAction)
        
        let clearAction = UIAlertAction(title: "Clear", style: .destructive, handler: {
            (action : UIAlertAction!) -> Void in
            self.endSearch()
        })
        alert.addAction(clearAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in

        })
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func tagAction()
    {
        var strings = [Constants.All]
        
        if let mediaItemTags = Globals.shared.media.all?.mediaItemTags {
            strings.append(contentsOf: mediaItemTags)
        }
        
        if let navigationController = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .fullScreen
            
            popover.navigationItem.title = "Series"
            
            popover.delegate = self
            
            popover.purpose = .selectingTags
            
            popover.section.strings = strings
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            present(navigationController, animated: true, completion: nil )
        }
    }
    
    @objc func menuButtonAction(tap:UITapGestureRecognizer)
    {
        print("MTVC menu button pressed")
        
        if !Thread.isMainThread {
            print("NOT MAIN THREAD")
        }

        guard Globals.shared.popoverNavCon == nil else {
            return
        }

        setNeedsFocusUpdate()
        
        Globals.shared.popoverNavCon = self.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController
        
        if Globals.shared.popoverNavCon != nil, let popover = Globals.shared.popoverNavCon?.viewControllers[0] as? PopoverTableViewController {
            Globals.shared.popoverNavCon?.modalPresentationStyle = .fullScreen
            
            popover.navigationItem.title = "Menu Options"
            
            popover.delegate = self
            
            popover.purpose = .selectingMenu
            
            var strings = [String]()

            if (Globals.shared.mediaPlayer.url == URL(string:Constants.URL.LIVE_STREAM)) {
                strings.append("Library")
            } else {
                if !Globals.shared.mediaPlayer.isZoomed {
                    if !Globals.shared.showingAbout {
                        strings.append("About")
                        
                        if Globals.shared.mediaPlayer.loaded, Globals.shared.mediaPlayer.mediaItem?.playing == Playing.video {
                            strings.append("Toggle Zoom")
                        } else
                        
                        if let hasSlides = selectedMediaItem?.hasSlides, hasSlides,
                            selectedMediaItem?.showing?.range(of: Showing.slides) != nil {
                            strings.append("Toggle Zoom")
                        }
                        
                        if let selectedMediaItem = Globals.shared.selectedMediaItem.detail, selectedMediaItem.hasSlides {
                            if selectedMediaItem.showing?.range(of: Showing.slides) != nil {
                                if selectedMediaItem.pageNum > 0 {
                                    strings.append("Previous Slide")
                                }
                                
                                if let count = selectedMediaItem.pageImages?.count, selectedMediaItem.pageNum < (count - 1) {
                                    strings.append("Next Slide")
                                }
                                
                                strings.append("Hide Slides")
                            } else {
                                strings.append("Show Slides")
                            }
                        }
                    } else {
                        if (Globals.shared.mediaPlayer.mediaItem != nil) {
                            strings.append("Current Selection")
                        } else {
                            //Nothing to show
                            strings.append("Library")
                        }
                    }
                    
                    if Globals.shared.streaming.entries?.count > 0, Globals.shared.reachability.isReachable {
                        strings.append(Constants.Strings.Live)
                    }
                    
                    strings.append(Constants.Strings.Category)
                    if let count = Globals.shared.media.all?.mediaItemTags?.count, count > 0 {
                        strings.append(Constants.Strings.Series)
                    }
                    
                    strings.append(Constants.Strings.Sort)
                    strings.append(Constants.Strings.Group)
                    strings.append(Constants.Strings.Index)
                    
                    strings.append(Constants.Strings.Search)
                    
                    strings.append("Refresh Media")
                    
                    strings.append(Constants.Strings.Clear_Slide_Cache)
                } else {
                    strings.append(Constants.Strings.Toggle_Zoom)
                    
                    if let selectedMediaItem = Globals.shared.selectedMediaItem.detail, selectedMediaItem.hasSlides {
                        if selectedMediaItem.showing?.range(of: Showing.slides) != nil {
                            if selectedMediaItem.pageNum > 0 {
                                strings.append(Constants.Strings.Previous_Slide)
                            }

                            if let count = selectedMediaItem.pageImages?.count, selectedMediaItem.pageNum < (count - 1) {
                                strings.append(Constants.Strings.Next_Slide)
                            }

                            if selectedMediaItem.playing == Playing.video, Globals.shared.mediaPlayer.mediaItem == selectedMediaItem {
                                strings.append(Constants.Strings.Hide_Slides)
                            }
                        } else {
                            strings.append(Constants.Strings.Show_Slides)
                        }
                    }
                }
            }
            
            popover.section.strings = strings
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            if let popoverNavCon = Globals.shared.popoverNavCon {
                present(popoverNavCon, animated: true, completion: nil )
            }
        }
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
                print("stopped")
                Thread.onMainThread {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PLAY_PAUSE), object: nil)
                }
                
            default:
                print("default")
                break
            }
        } else {
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PLAY_PAUSE), object: nil)
            }
        }
    }
    
    @objc func willEnterForeground()
    {
        
    }
    
    func loadCompletion()
    {
        if Globals.shared.mediaRepository.list == nil {
            let alert = UIAlertController(title: "No media available.",
                                          message: "Please check your network connection and try again.",
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                self.setupListActivityIndicator()
            })
            alert.addAction(action)
            
            self.present(alert, animated: true, completion: nil)
        } else {
            self.selectedMediaItem = Globals.shared.selectedMediaItem.master
            
            if Globals.shared.search.active && !Globals.shared.search.complete { // && Globals.shared.search.transcripts
                self.updateSearchResults(Globals.shared.search.text,completion: {
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                        Thread.onMainThread {
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle)
                        }
                    })
                })
            } else {
                // Reload the table
                self.tableView.reloadData()
                
                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                    Thread.onMainThread {
                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle)
                    }
                })
            }
        }
        
        self.tableView.isHidden = false
    }
    
    @objc func didBecomeActive()
    {
        guard !Globals.shared.isLoading, Globals.shared.mediaRepository.list == nil else {
            return
        }
        
        loadCategories()
        
        // Download or Load
        
        switch jsonSource {
        case .download:
            break
            
        case .direct:
            tableView.isHidden = true
            
            loadMediaItems()
            {
                self.loadCompletion()
            }
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if Globals.shared.media.active?.list == nil {
            tableView.isHidden = true
        }
        
        addNotifications()

        updateUI()
    }
    
    func about()
    {
        performSegue(withIdentifier: Constants.SEGUE.SHOW_ABOUT2, sender: self)
    }
    
    func updateUI()
    {
        setupCategory()
        setupTag()
        
        setupTitle()
        
        setupBarButtons()

        setupListActivityIndicator()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        Globals.shared.freeMemory()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        guard !Globals.shared.mediaPlayer.isZoomed else {
            return false
        }
        
        guard (Globals.shared.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) else {
            print("Player is LIVE STREAMING.")
            return false
        }

        var show:Bool
        
        show = true
        
        switch identifier {
            case Constants.SEGUE.SHOW_ABOUT:
                break

            case Constants.SEGUE.SHOW_MEDIAITEM:
                break
            
            default:
                break
        }
        
        return show
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var dvc = segue.destination as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = dvc as? UINavigationController, let visibleViewController = navCon.visibleViewController {
            dvc = visibleViewController
        }
        
        if let identifier = segue.identifier {
            switch identifier {                
            case Constants.SEGUE.SHOW_LIVE:
                if sender != nil {
                    (dvc as? LiveViewController)?.streamEntry = sender as? StreamEntry
                } else {
                    let defaults = UserDefaults.standard
                    if let streamEntry = StreamEntry(defaults.object(forKey: Constants.SETTINGS.LIVE) as? [String:Any]) {
                        (dvc as? LiveViewController)?.streamEntry = streamEntry
                    }
                }
                break
                
            case Constants.SEGUE.SHOW_ABOUT2:
                Globals.shared.showingAbout = true
                break
                
            case Constants.SEGUE.SHOW_MEDIAITEM:
                if Globals.shared.mediaPlayer.url == URL(string:Constants.URL.LIVE_STREAM) { // (Globals.shared.mediaPlayer.pip == .stopped)
                    Globals.shared.mediaPlayer.pause()
                }
                
                Globals.shared.showingAbout = false
                if (Globals.shared.gotoPlayingPaused) {
                    Globals.shared.gotoPlayingPaused = !Globals.shared.gotoPlayingPaused

                    if let destination = dvc as? MediaViewController {
                        destination.selectedMediaItem = Globals.shared.mediaPlayer.mediaItem
                    }
                } else {
                    if let myCell = sender as? MediaTableViewCell {
                        if (selectedMediaItem != myCell.mediaItem) || (Globals.shared.history == nil) {
                            Globals.shared.addToHistory(myCell.mediaItem)
                        }
                        selectedMediaItem = myCell.mediaItem
                        
                        if selectedMediaItem != nil {
                            if let destination = dvc as? MediaViewController {
                                destination.selectedMediaItem = selectedMediaItem
                            }
                        }
                    }
                }
                break

            default:
                break
            }
        }

    }
}

extension MediaTableViewController : UITableViewDataSource
{
    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int
    {
        guard let headers = Globals.shared.display.section.headers else {
            return 0
        }
        
        return headers.count
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]?
    {
        return nil
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
    {
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        guard let headers = Globals.shared.display.section.headers else {
            return nil
        }
        
        if section < headers.count {
            return headers[section]
        } else {
            return nil
        }
    }
    
    func tableView(_ TableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let counts = Globals.shared.display.section.counts else {
            return 0
        }

        if section < counts.count {
            return counts[section]
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.MEDIAITEM, for: indexPath) as? MediaTableViewCell ?? MediaTableViewCell()
        
        cell.hideUI()
        
        // Configure the cell
        if let indexes = Globals.shared.display.section.indexes, let mediaItems = Globals.shared.display.mediaItems {
            if indexPath.section < indexes.count {
                let section = indexes[indexPath.section]
                if section + indexPath.row < mediaItems.count {
                    cell.mediaItem = mediaItems[section + indexPath.row]
                } else {
                    print("No mediaItem for cell!")
                }
            } else {
                print("No mediaItem for cell!")
            }
        } else {
            print("No mediaItem for cell!")
        }
        
        cell.searchText = Globals.shared.search.active ? Globals.shared.search.text : nil

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        guard section < Globals.shared.display.section.headers?.count, let title = Globals.shared.display.section.headers?[section] else {
            return Constants.HEADER_HEIGHT
        }
        
        let heightSize: CGSize = CGSize(width: tableView.frame.width - 40, height: .greatestFiniteMagnitude)
        
        let height = title.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.body, context: nil).height
        
        return max(Constants.HEADER_HEIGHT,height + 28)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.text = nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        var view : MediaTableViewControllerHeaderView?
        
        view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "MediaTableViewController") as? MediaTableViewControllerHeaderView
        if view == nil {
            view = MediaTableViewControllerHeaderView()
        }
        
        if section >= 0, section < Globals.shared.display.section.headers?.count, let title = Globals.shared.display.section.headers?[section] {
            view?.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
            
            if view?.label == nil {
                let label = UILabel()
                
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
                
                label.translatesAutoresizingMaskIntoConstraints = false
                
                view?.addSubview(label)
                
                view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[label]-20-|", options: [.alignAllCenterY], metrics: nil, views: ["label":label]))
                view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllCenterX], metrics: nil, views: ["label":label]))
            
                view?.label = label
            }
            
            view?.label?.attributedText = NSAttributedString(string: title,   attributes: Constants.Fonts.Attributes.body)
            
            view?.alpha = 0.85
        }
        
        return view
    }
}

extension MediaTableViewController : UITableViewDelegate
{
    // MARK: UITableViewDelegate
    
    func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath?
    {
        return tableView.indexPathForSelectedRow
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("didSelect")

        guard !Globals.shared.mediaPlayer.isZoomed else {
            return
        }
        
        guard (Globals.shared.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) else {
            print("Player is LIVE STREAMING.")
            return
        }
        
        if let cell: MediaTableViewCell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell {
            selectedMediaItem = cell.mediaItem
        } else {
            
        }
        
        preferredFocusView = splitViewController?.viewControllers[1].view
    }
    
    func tableView(_ tableView:UITableView, didDeselectRowAt indexPath: IndexPath)
    {

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return false
    }
    
    func authentication()
    {
        guard let url = URL(string: "https://17iPVurdk9fn2ZKLVnnfqN4HKKIb9WXMKzN0l5K5:@bibles.org/v2/eng-NASB/passages.js?q[]=") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                print("error=\(String(describing: error))")
                return
            }
            
            print("response = \(String(describing: response))")
            
            if let data = data {
                let responseString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
                print("responseString = \(String(describing: responseString))")
            }
        }
        task.resume()
    }
}
