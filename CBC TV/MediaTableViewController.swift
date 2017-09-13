//
//  MediaTableViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation

extension UIColor
{
    // MARK: UIColor extension
    
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
    
    static func controlBlue() -> UIColor
    {
        return UIColor(red: 14, green: 122, blue: 254)
    }
}

enum JSONSource {
    case direct
    case download
}

extension MediaTableViewController : PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index: Int, strings: [String]?, purpose:PopoverPurpose)
    {
        if !Thread.isMainThread {
            print("NOT MAIN THREAD")
        }
        
        dismiss(animated: true, completion: nil)
        
        guard let string = strings?[index] else {
            return
        }

        splitViewController?.preferredDisplayMode = .allVisible

        switch purpose {
        case .selectingMenu:
            switch string {
            case "About":
                globals.mediaPlayer.isZoomed = false
                performSegue(withIdentifier: Constants.SEGUE.SHOW_ABOUT2, sender: self)
                break
                
            case "Search":
                searchAction()
                break
                
            case "Current Selection":
                globals.gotoPlayingPaused = true
                globals.mediaPlayer.isZoomed = false
                
                performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: self)
                break
                
            case "Category":
                mediaCategoryAction()
                break

            case "Series":
                tagAction()
                break
                
            case "Library":
                globals.gotoPlayingPaused = true
                performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: self)
                break
                
            case "Toggle Zoom":
                if globals.mediaPlayer.isZoomed {
                    globals.mediaPlayer.showsPlaybackControls = false
                    globals.mediaPlayer.controller?.isSkipForwardEnabled = false
                    globals.mediaPlayer.controller?.isSkipBackwardEnabled = false
                } else {
                    globals.mediaPlayer.showsPlaybackControls = true
                    globals.mediaPlayer.controller?.isSkipForwardEnabled = true
                    globals.mediaPlayer.controller?.isSkipBackwardEnabled = true
                }
                globals.mediaPlayer.isZoomed = !globals.mediaPlayer.isZoomed

                setupViews()
                break
                
            case "Sort":
                sortAction()
                break
                
            case "Group":
                groupAction()
                break
                
            case "Index":
                indexAction()
                break

            case "Live":
                preferredFocusView = nil
//                performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: self)
                
                
                if globals.streamEntries?.count > 0, globals.reachability.currentReachabilityStatus != .notReachable, //globals.streamEntries?.count > 0,
                    let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.modalPresentationStyle = .fullScreen
                    
                    popover.navigationItem.title = "Live Events"

                    popover.allowsSelection = true
                    
                    // An enhancement to selectively highlight (select)
                    popover.shouldSelect = { (indexPath:IndexPath) -> Bool in
                        if let keys:[String] = popover.section.stringIndex?.keys.map({ (string:String) -> String in
                            return string
                        }).sorted() {
                            // We have to use sorted() because the order of keys is undefined.
                            // We are assuming they are presented in sort order in the tableView
                            return keys[indexPath.section] == "Playing"
                        }
                        
                        return false
                    }
                    
                    // An alternative to rowClickedAt
                    popover.didSelect = { (indexPath:IndexPath) -> Void in
                        if let keys:[String] = popover.section.stringIndex?.keys.map({ (string:String) -> String in
                            return string
                        }).sorted() {
                            // We have to use sorted() because the order of keys is undefined.
                            // We are assuming they are presented in sort order in the tableView
                            let key = keys[indexPath.section]
                            
                            if key == "Playing" {
                                self.dismiss(animated: true, completion: nil)
//                                if let isCollapsed = self.splitViewController?.isCollapsed, isCollapsed {
//                                }
                                if let streamEntry = StreamEntry(globals.streamEntryIndex?[key]?[indexPath.row]) {
                                    self.performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: streamEntry)
                                }
                            }
                        }
                    }
                    
//                    popover.search = true
                    
//                    popover.refresh = {
//                        popover.section.strings = nil
//                        popover.section.headerStrings = nil
//                        popover.section.counts = nil
//                        popover.section.indexes = nil
//                        
//                        popover.tableView?.reloadData()
//                        
//                        self.loadLive() {
//                            if #available(iOS 10.0, *) {
//                                if let isRefreshing = popover.tableView?.refreshControl?.isRefreshing, isRefreshing {
//                                    popover.refreshControl?.endRefreshing()
//                                }
//                            } else {
//                                // Fallback on earlier versions
//                                if popover.isRefreshing {
//                                    popover.refreshControl?.endRefreshing()
//                                    popover.isRefreshing = false
//                                }
//                            }
//                            
//                            //                                popover.section.strings = globals.streamStrings
//                            popover.section.stringIndex = globals.streamStringIndex
//                            
//                            popover.tableView.reloadData()
//                        }
//                    }
                    
                    // These assume the streamEntries have been collected!
                    //                popover.section.strings = globals.streamStrings
                    //                popover.section.stringIndex = globals.streamStringIndex
                    
                    // This was an experiment - finally sorted out the need to set section.indexes/counts when showIndex is false
                    //                popover.stringsFunction = { (Void) -> [String]? in
                    //                    self.loadLive(completion: nil)
                    //                    return globals.streamStrings
                    //                }
                    
                    // Makes no sense w/o section.showIndex also being true - UNLESS you're using section.stringIndex
                    popover.section.showHeaders = true
                    
                    present(navigationController, animated: true, completion: {
                        // This is an alternative to popover.stringsFunction
                        popover.activityIndicator.isHidden = false
                        popover.activityIndicator.startAnimating()
                        
                        self.loadLive() {
                            popover.section.stringIndex = globals.streamStringIndex
                            popover.tableView.reloadData()
                            
                            popover.activityIndicator.stopAnimating()
                            popover.activityIndicator.isHidden = true
                        
                            popover.setPreferredContentSize()
                        }
                        
//                        self.presentingVC = navigationController
                        //                        DispatchQueue.main.async(execute: { () -> Void in
                        //                            // This prevents the Show/Hide button from being tapped, as normally the toolar that contains the barButtonItem that anchors the popoever, and all of the buttons (UIBarButtonItem's) on it, are in the passthroughViews.
                        //                            navigationController.popoverPresentationController?.passthroughViews = nil
                        //                        })
                    })
                }

                break
                
            default:
                break
            }
            break
            
        case .selectingCategory:
            guard (globals.mediaCategory.selected != string) || (globals.mediaRepository.list == nil) else {
                return
            }
            
            globals.mediaCategory.selected = string
            
            globals.mediaPlayer.unobserve()
            
            let liveStream = globals.mediaPlayer.url == URL(string: Constants.URL.LIVE_STREAM)
            
            globals.mediaPlayer.pause() // IfPlaying
            
            globals.clearDisplay()
            
            tableView.reloadData()
            
            if splitViewController != nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
            }
            
            //                    tagLabel.text = nil
            
            // This is ABSOLUTELY ESSENTIAL to reset all of the Media so that things load as if from a cold start.
            globals.media = Media()
            
            loadMediaItems()
                {
                    if liveStream {
                        DispatchQueue.main.async(execute: { () -> Void in
                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
                        })
                    }
                    
                    if globals.mediaRepository.list == nil {
                        let alert = UIAlertController(title: "No media available.",
                                                      message: "Please check your network connection and try again.",
                                                      preferredStyle: UIAlertControllerStyle.alert)

                        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                            self.setupListActivityIndicator()
                        })
                        alert.addAction(action)

                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.selectedMediaItem = globals.selectedMediaItem.master
                        
                        if globals.search.active && !globals.search.complete {
                            self.updateSearchResults(globals.search.text,completion: {
                                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                    DispatchQueue.main.async(execute: { () -> Void in
                                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                                    })
                                })
                            })
                        } else {
                            // Reload the table
                            self.tableView.reloadData()
                            
                            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top)
                                })
                            })
                        }
                    }
                    
                    self.tableView.isHidden = false
            }
            break
            
        case .selectingSorting:
            globals.sorting = Constants.sortings[Constants.SortingTitles.index(of: string)!]
            
            if (globals.media.need.sorting) {
                globals.clearDisplay()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                    
                    self.startAnimating()
                    
                    self.disableBarButtons()
                    
                    DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                        globals.setupDisplay(globals.media.active)
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.tableView.reloadData()
                            
                            self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.top) // was Middle
                            
                            self.stopAnimating()
                            
                            self.enableBarButtons()
                            
                            self.preferredFocusView = self.tableView
                        })
                    })
                })
            }
            break
            
        case .selectingGrouping:
            globals.grouping = globals.groupings[globals.groupingTitles.index(of: string)!]
            
            if globals.media.need.grouping {
                globals.clearDisplay()
                
                self.tableView.reloadData()
                
                self.startAnimating()
                
                self.disableBarButtons()
                
                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                    globals.setupDisplay(globals.media.active)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                        
                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                        
                        self.stopAnimating()
                        
                        self.enableBarButtons()
                        
                        self.preferredFocusView = self.tableView
                    })
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
                    if (globals.media.tags.showing != Constants.ALL) {
                        new = true
                        //                            globals.media.tags.showing = Constants.ALL
                        globals.media.tags.selected = nil
                    }
                    break
                    
                default:
                    //Tagged
                    
                    let tagSelected = string
                    
                    new = (globals.media.tags.showing != Constants.TAGGED) || (globals.media.tags.selected != tagSelected)
                    
                    if (new) {
                        //                                print("\(globals.media.active!.mediaItemTags)")
                        
                        globals.media.tags.selected = tagSelected
                        
                        //                            globals.media.tags.showing = Constants.TAGGED
                    }
                    break
                }
                
                if (new) {
                    DispatchQueue.main.async(execute: { () -> Void in
                        globals.clearDisplay()
                        
                        self.tableView.reloadData()
                        
                        self.startAnimating()
                        
                        self.disableBarButtons()
                    })
                    
                    if (globals.search.active) {
                        self.updateSearchResults(globals.search.text,completion: nil)
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        globals.setupDisplay(globals.media.active)
                        
                        self.tableView.reloadData()
                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.none) // was Middle
                        
                        self.stopAnimating()
                        
                        self.enableBarButtons()
                        
                        self.setupTag()
                    })
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
            if (preferredFocusView != nil) {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setNeedsFocusUpdate()
//                    self.updateFocusIfNeeded()
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
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .fullScreen
            
            popover.navigationItem.title = "Categories"
            
            popover.delegate = self
            
            popover.purpose = .selectingCategory
            
            popover.section.strings = globals.mediaCategory.names
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            present(navigationController, animated: true, completion: nil )
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    {
        didSet {
            tableView.register(MediaTableViewControllerHeaderView.self, forHeaderFooterViewReuseIdentifier: "MediaTableViewController")

//            tableView.remembersLastFocusedIndexPath = true
            tableView.mask = nil
        }
    }
    
    func sortAction()
    {
        if !Thread.isMainThread {
            print("NOT MAIN THREAD")
        }
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
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
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .fullScreen
            
            popover.navigationItem.title = "Group By"
            
            popover.delegate = self
            
            popover.purpose = .selectingGrouping
            
            popover.section.strings = globals.groupingTitles
            
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
        
//        startAnimating()
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
            let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
            navigationController.modalPresentationStyle = .fullScreen
            
            popover.navigationItem.title = "Index"
            
            popover.delegate = self
            
            popover.purpose = .selectingSection
            
            popover.section.strings = globals.media.active?.section?.indexStrings
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            present(navigationController, animated: true, completion: nil )
        }
    }
    
    var selectedMediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            globals.selectedMediaItem.master = selectedMediaItem
        }
    }
    
    func disableBarButtons()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        })
    }
    
    func enableBarButtons()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        })
    }

    func setupViews()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })
        
        setupTitle()
        
        selectedMediaItem = globals.selectedMediaItem.master
        
        //Without this background/main dispatching there isn't time to scroll after a reload.
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle) // was Middle

                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.preferredFocusView = self.tableView
                    })
                })
            })
        })
        
        if (splitViewController != nil) {
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_VIEW), object: nil)
            })
        }
    }

    func jsonAlert(title:String,message:String)
    {
        if (UIApplication.shared.applicationState == UIApplicationState.active) {
            DispatchQueue.main.async(execute: { () -> Void in
                let alert = UIAlertController(title:title,
                                              message:message,
                                              preferredStyle: UIAlertControllerStyle.alert)
                
                let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                    
                })
                alert.addAction(action)
                
                self.present(alert, animated: true, completion: nil)
            })
        }
    }

//    func jsonFromFileSystem(filename:String?) -> Any?
//    {
//        guard let filename = filename else {
//            return nil
//        }
//        
//        guard let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) else {
//            return nil
//        }
//        
//        do {
//            let data = try Data(contentsOf: jsonFileSystemURL) // , options: NSData.ReadingOptions.mappedIfSafe
//            print("able to read json from the URL.")
//            
//            do {
//                let json = try JSONSerialization.jsonObject(with: data, options: [])
//                return json
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//                return nil
//            }
//        } catch let error as NSError {
//            print("Network unavailable: json could not be read from the file system.")
//            NSLog(error.localizedDescription)
//            return nil
//        }
//    }

//    func jsonFromURL(url:String,filename:String) -> Any?
//    {
//        guard let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename) else {
//            return nil
//        }
//        
//        guard globals.reachability.currentReachabilityStatus != .notReachable else {
//            print("json not reachable.")
//            
//            //            globals.alert(title:"Network Error",message:"Newtork not available, attempting to load last available media list.")
//            
//            return jsonFromFileSystem(filename: filename)
//        }
//        
//        do {
//            let data = try Data(contentsOf: URL(string: url)!) // , options: NSData.ReadingOptions.mappedIfSafe
//            print("able to read json from the URL.")
//            
//            do {
//                let json = try JSONSerialization.jsonObject(with: data, options: [])
//                
//                do {
//                    try data.write(to: jsonFileSystemURL)//, options: NSData.WritingOptions.atomic)
//                    
//                    print("able to write json to the file system")
//                } catch let error as NSError {
//                    print("unable to write json to the file system.")
//                    
//                    NSLog(error.localizedDescription)
//                }
//                
//                return json
//            } catch let error as NSError {
//                NSLog(error.localizedDescription)
//                return jsonFromFileSystem(filename: filename)
//            }
//        } catch let error as NSError {
//            NSLog(error.localizedDescription)
//            return jsonFromFileSystem(filename: filename)
//        }
//    }

//    func jsonFromURL(url:String,filename:String) -> JSON
//    {
//        let jsonFileSystemURL = cachesURL()?.appendingPathComponent(filename)
//        
//        do {
//            let data = try Data(contentsOf: URL(string: url)!) // , options: NSData.ReadingOptions.mappedIfSafe
//            
//            let json = JSON(data: data)
//            if json != JSON.null {
//                do {
//                    try data.write(to: jsonFileSystemURL!)//, options: NSData.WritingOptions.atomic)
////                    jsonAlert(title:"Pursue sanctification!",message:"Media list read, loaded, and written.")
//                } catch let error as NSError {
//                    print("Media List Error","Media list read and loaded but write failed.")
//                    NSLog(error.localizedDescription)
//                }
//                
//                print(json)
//                return json
//            } else {
//                print("could not get json from URL, make sure that it exists and contains valid json.")
//                
//                do {
//                    let data = try Data(contentsOf: jsonFileSystemURL!) // , options: NSData.ReadingOptions.mappedIfSafe
//                    
//                    let json = JSON(data: data)
//                    if json != JSON.null {
////                        jsonAlert(title:"Media List Error",message:"Media list read but failed to load.  Last available copy read and loaded.")
//                        print("could get json from the file system.")
////                        print(json)
//                        return json
//                    } else {
//                        jsonAlert(title:"Media List Error",message:"Media list read but failed to load. Last available copy read but load failed.")
//                        print("could not get json from the file system either.")
//                    }
//                } catch let error as NSError {
//                    print("Media List Error","Media list read but failed to load.  Last available copy read failed.")
//                    NSLog(error.localizedDescription)
//                }
//            }
//        } catch let error as NSError {
//            print("getting json from URL failed, make sure that it exists and contains valid json.")
//            print(error.localizedDescription)
//            
//            do {
//                let data = try Data(contentsOf: jsonFileSystemURL!) // , options: NSData.ReadingOptions.mappedIfSafe
//                
//                let json = JSON(data: data)
//                if json != JSON.null {
////                    jsonAlert(title:"Media List Error",message:"Media list read failed.  Last available copy read and loaded.")
//                    print("could get json from the file system.")
//                    //                        print(json)
//                    return json
//                } else {
//                    jsonAlert(title:"Media List Error",message:"Media list read failed.  Last available copy read but load failed.")
//                    print("could not get json from the file system either.")
//                }
//            } catch let error as NSError {
//                print("Media List Error","Media list read failed.  Last available copy read failed.")
//                NSLog(error.localizedDescription)
//            }
//        }
//        //        } else {
//        //            print("Invalid filename/path.")
//        //        }
//        
//        return nil
//    }
    
    func loadJSONDictsFromCachesDirectory(key:String) -> [[String:String]]?
    {
        var mediaItemDicts = [[String:String]]()
        
        if let json = jsonDataFromCachesDirectory() as? [String:Any] {
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
        
//        if json != JSON.null {
////            print("json:\(json)")
//            
//            let mediaItems = json[key]
//            
//            for i in 0..<mediaItems.count {
//                
//                var dict = [String:String]()
//                
//                for (key,value) in mediaItems[i] {
//                    dict[key] = "\(value)"
//                }
//                
//                mediaItemDicts.append(dict)
//            }
//            
//            //            print(mediaItemDicts)
//            
//            return mediaItemDicts.count > 0 ? mediaItemDicts : nil
//        } else {
//            print("could not get json from file, make sure that file contains valid json.")
//        }
        
        return nil
    }
    
    func loadJSONDictsFromURL(url:String,key:String,filename:String) -> [[String:String]]?
    {
        var mediaItemDicts = [[String:String]]()
        
        if let json = jsonFromURL(url: url,filename: filename) as? [String:Any] {
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

//    func loadJSONDictsFromURL(url:String,key:String,filename:String) -> [[String:String]]?
//    {
//        var mediaItemDicts = [[String:String]]()
//        
//        let json = jsonFromURL(url: url,filename: filename)
//        
//        if json != JSON.null {
//            print(json)
//            
//            let mediaItems = json[key]
//            
//            for i in 0..<mediaItems.count {
//                
//                var dict = [String:String]()
//                
//                for (key,value) in mediaItems[i] {
////                    print(key,value)
//                    dict[key] = "\(value)".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//                }
//                
//                mediaItemDicts.append(dict)
//            }
//            
//            //            print(mediaItemDicts)
//            
//            return mediaItemDicts.count > 0 ? mediaItemDicts : nil
//        } else {
//            print("could not get json from URL, make sure that URL contains valid json.")
//        }
//        
//        return nil
//    }
    
    func mediaItemsFromMediaItemDicts(_ mediaItemDicts:[[String:String]]?) -> [MediaItem]?
    {
        if (mediaItemDicts != nil) {
            return mediaItemDicts?.map({ (mediaItemDict:[String : String]) -> MediaItem in
                MediaItem(dict: mediaItemDict)
            })
        }
        
        return nil
    }
    
    func loadLive() -> [String:Any]?
    {
        return jsonFromURL(url: "https://api.countrysidebible.org/cache/streamEntries.json") as? [String:Any]
    }
    
    func loadLive(completion:((Void)->(Void))?)
    {
        DispatchQueue.global(qos: .background).async() {
            Thread.sleep(forTimeInterval: 0.25)
            
            if let liveEvents = jsonFromURL(url: "https://api.countrysidebible.org/cache/streamEntries.json") as? [String:Any] {
                //            print(liveEvents["streamEntries"] as? [[String:Any]])
                
                globals.streamEntries = liveEvents["streamEntries"] as? [[String:Any]]
                
                Thread.onMainThread(block: {
                    completion?()
                })
                
                //            print(globals.streamCategories)
                
                //            print(globals.streamSchedule)
                
            }
        }
    }
    
    func loadCategories()
    {
        if let categoriesDicts = self.loadJSONDictsFromURL(url: Constants.JSON.URL.CATEGORIES,key:Constants.JSON.ARRAY_KEY.CATEGORY_ENTRIES,filename: Constants.JSON.FILENAME.CATEGORIES) {
            //                print(categoriesDicts)
            
            var mediaCategoryDicts = [String:String]()
            
            for categoriesDict in categoriesDicts {
                mediaCategoryDicts[categoriesDict["category_name"]!] = categoriesDict["id"]
            }
            
            globals.mediaCategory.dicts = mediaCategoryDicts
            
            //                print(globals.mediaCategories)
        }
    }
    
    func loadMediaItems(completion: (() -> Void)?)
    {
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            globals.isLoading = true
            
            self.setupCategory()
            self.setupTag()
            
            self.setupBarButtons()
            self.setupListActivityIndicator()

            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Title.Loading_Media
            })
            
            self.loadLive(completion: nil)
            
            var url:String?

            if (globals.mediaCategory.selected != nil) && (globals.mediaCategory.selectedID != nil) {
                url = Constants.JSON.URL.CATEGORY + globals.mediaCategory.selectedID!
            }
            
//            print(Constants.JSON_CATEGORY_URL + globals.mediaCategoryID!)

            if url != nil {
                switch self.jsonSource {
                case .download:
                    // From Caches Directory
                    if let mediaItemDicts = self.loadJSONDictsFromCachesDirectory(key: Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES) {
                        globals.mediaRepository.list = self.mediaItemsFromMediaItemDicts(mediaItemDicts)
                    }
                    break
                    
                case .direct:
                    // From URL
                    print(globals.mediaCategory.filename as Any)
                    if let filename = globals.mediaCategory.filename, let mediaItemDicts = self.loadJSONDictsFromURL(url: url!,key: Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES,filename: filename) {
                        globals.mediaRepository.list = self.mediaItemsFromMediaItemDicts(mediaItemDicts)
                    } else {
                        globals.mediaRepository.list = nil
                        print("FAILED TO LOAD")
                    }
                    break
                }
            }
            
//            globals.printLexicon()
//
//            var tokens = Set<String>()
//            
//            for mediaItem in globals.mediaRepository.list! {
//                if let stringTokens = tokensFromString(mediaItem.title!) {
//                    tokens = tokens.union(Set(stringTokens))
//                }
//            }
//            print(Array(tokens).sorted() {
//                if $0.endIndex < $1.endIndex {
//                    return $0.endIndex < $1.endIndex
//                } else
//                if $0.endIndex == $1.endIndex {
//                    return $0 < $1
//                }
//                return false
//            } )
            
//            var count = 0
//            
//            for mediaItem in globals.mediaRepository.list! {
//                if mediaItem.hasVideo {
//                    self.players[mediaItem.video!] = AVPlayer(url: mediaItem.videoURL!)
//                    
//                    self.players[mediaItem.video!]?.currentItem?.addObserver(self,
//                                                                          forKeyPath: #keyPath(AVPlayerItem.status),
//                                                                          options: [.old, .new],
//                                                                          context: nil) // &GlobalPlayerContext
//                    self.mediaItems[mediaItem.video!] = mediaItem
//                    
//                    sleep(1)
//                    count += 1
//                    
//                    print("MediaItem Count \(count): \(mediaItem.title!)")
//                }
//            }
            
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

            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Title.Loading_Settings
            })
            globals.loadSettings()
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Title.Sorting_and_Grouping
            })
            
            globals.media.all = MediaListGroupSort(mediaItems: globals.mediaRepository.list)

//            print(globals.mediaRepository.list?.count)
//            print(globals.media.all?.list?.count)
            
            if globals.search.valid {
                globals.search.complete = false
            }

            globals.setupDisplay(globals.media.active)
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.navigationItem.title = Constants.Title.Setting_up_Player
                
                if (globals.mediaPlayer.mediaItem != nil) {
                    // This MUST be called on the main loop.
                    globals.mediaPlayer.setup(globals.mediaPlayer.mediaItem,playOnLoad:false)
                }

//                self.navigationItem.title = nil // Constants.Media // Constants.CBC.TITLE.SHORT
                
                self.setupTitle()
                
                self.setupViews()
                
                self.setupListActivityIndicator()

                globals.isLoading = false
                
                completion?()

                self.setupBarButtons()

                self.setupTag()
                self.setupCategory()
                
                self.setupListActivityIndicator()
            })
        })
    }
    
    func setupCategory()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            self.mediaCategoryLabel.text = globals.mediaCategory.selected
        })
    }
    
    func setupBarButtons()
    {
        if globals.isLoading {
            disableBarButtons()
        } else {
            if (globals.mediaRepository.list != nil) {
                enableBarButtons()
            }
        }
    }
    
    func setupListActivityIndicator()
    {
        if globals.isLoading || (globals.search.active && !globals.search.complete) {
            DispatchQueue.main.async(execute: { () -> Void in
                self.startAnimating()
            })
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                self.stopAnimating()
            })
        }
    }
    
    func updateList()
    {
        globals.setupDisplay(globals.media.active)
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })
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
        
//        print("stopAnimating")

        if Thread.isMainThread {
            self.actInd.stopAnimating()
            self.loadingView.isHidden = true
            self.container.isHidden = true
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                self.actInd.stopAnimating()
                self.loadingView.isHidden = true
                self.container.isHidden = true
            })
        }
    }
    
    func startAnimating()
    {
        if container == nil { // loadingView
            setupLoadingView()
        }

        guard loadingView != nil else {
            return
        }
        
        guard actInd != nil else {
            return
        }
        
//        print("startAnimating")
        
        if Thread.isMainThread {
            self.container.isHidden = false
            self.loadingView.isHidden = false
            self.actInd.startAnimating()
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                self.container.isHidden = false
                self.loadingView.isHidden = false
                self.actInd.startAnimating()
            })
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

        container = loadingViewController.view!
        
        container.backgroundColor = UIColor.clear//.white.withAlphaComponent(0.0)

        container.frame = view.frame
        container.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height / 2)
        
        container.isUserInteractionEnabled = false
        
        loadingView = loadingViewController.view.subviews[0]
        
        loadingView.isUserInteractionEnabled = false
        
        actInd = loadingView.subviews[0] as! UIActivityIndicatorView
        
        actInd.isUserInteractionEnabled = false
        
        view.addSubview(container) // loadingView
    }

    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.menuButtonAction(tap:)), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MENU), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.updateList), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.updateSearch), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.UPDATE_SEARCH), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.playerView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.PLAYER_VIEW), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.willEnterForeground), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.WILL_ENTER_FORGROUND), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewController.didBecomeActive), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.DID_BECOME_ACTIVE), object: nil)
    }
   
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        addNotifications()
        
        let menuPressRecognizer = UITapGestureRecognizer(target: self, action: #selector(MediaTableViewController.menuButtonAction(tap:)))
        menuPressRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        view.addGestureRecognizer(menuPressRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MediaTableViewController.playPauseButtonAction(tap:)))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue)];
        view.addGestureRecognizer(tapRecognizer)
        
        // in didBecomeActive
//        if globals.mediaRepository.list == nil {
//            //            disableBarButtons()
//            
//            loadCategories()
//            
//            // Download or Load
//            
//            switch jsonSource {
//            case .download:
////                downloadJSON()
//                break
//                
//            case .direct:
//                tableView.isHidden = true
//
//                loadMediaItems()
//                {
//                    if globals.mediaRepository.list == nil {
//                        let alert = UIAlertController(title: "No media available.",
//                                                      message: "Please check your network connection and try again.",
//                                                      preferredStyle: UIAlertControllerStyle.alert)
//                        
//                        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
//                            self.setupListActivityIndicator()
//                        })
//                        alert.addAction(action)
//                        
//                        self.present(alert, animated: true, completion: nil)
//                    } else {
//                        self.selectedMediaItem = globals.selectedMediaItem.master
//                        
//                        if globals.search.active && !globals.search.complete { // && globals.search.transcripts
//                            self.updateSearchResults(globals.search.text,completion: {
//                                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                                    DispatchQueue.main.async(execute: { () -> Void in
//                                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle)
//                                    })
//                                })
//                            })
//                        } else {
//                            // Reload the table
//                            self.tableView.reloadData()
//
//                            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                                DispatchQueue.main.async(execute: { () -> Void in
//                                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle)
//                                })
//                            })
//                        }
//                    }
//
//                    self.tableView.isHidden = false
//                }
//                break
//            }
//        }
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        tableView?.allowsSelection = true
    }
    
    func updateDisplay(searchText:String?)
    {
        guard let searchText = searchText?.uppercased() else {
            return
        }
        
        if !globals.search.active || (globals.search.text?.uppercased() == searchText) {
//            print(globals.search.text,searchText)
//            print("setupDisplay")
            globals.setupDisplay(globals.media.active)
        } else {
//            print("clearDisplay 1")
//            globals.clearDisplay()
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            if !self.tableView.isEditing {
                self.tableView.reloadData()
            } else {
                self.changesPending = true
            }
        })
    }

    func updateSearches(searchText:String?,mediaItems: [MediaItem]?)
    {
        guard let searchText = searchText?.uppercased() else {
            return
        }
        
        if globals.media.toSearch?.searches == nil {
            globals.media.toSearch?.searches = [String:MediaListGroupSort]()
        }
        
        globals.media.toSearch?.searches?[searchText] = MediaListGroupSort(mediaItems: mediaItems)
    }
    
    func updateSearchResults(_ searchText:String?,completion: (() -> Void)?)
    {
//        print(searchText)

        guard let searchText = searchText?.uppercased() else {
            return
        }
        
        guard !searchText.isEmpty else {
            return
        }
        
//        print(searchText)
        
        guard (globals.media.toSearch?.searches?[searchText] == nil) else {
            updateDisplay(searchText:searchText)
            setupListActivityIndicator()
            setupBarButtons()
            
            setupCategory()
            setupTag()
            
            return
        }
        
        globals.search.complete = false

//            print(searchText!)

        globals.clearDisplay()

        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })

        self.setupBarButtons()
        
        self.setupCategory()
        self.setupTag()

        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            //                print("1: ",searchText,Constants.EMPTY_STRING)
            
            var searchMediaItems:[MediaItem]?
            
            if globals.media.toSearch?.list != nil {
                for mediaItem in globals.media.toSearch!.list! {
                    globals.search.complete = false
                    
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
            
            DispatchQueue.main.async(execute: { () -> Void in
                completion?()
                
                globals.search.complete = true
                
                self.setupListActivityIndicator()
                self.setupBarButtons()
                self.setupCategory()
                self.setupTag()
            })
        })
    }

    func selectOrScrollToMediaItem(_ mediaItem:MediaItem?, select:Bool, scroll:Bool, position: UITableViewScrollPosition)
    {
        guard !tableView.isEditing else {
            return
        }
        
        guard mediaItem != nil else {
            return
        }
        
        guard globals.media.active?.mediaItems?.index(of: mediaItem!) != nil else {
            return
        }
        
        var indexPath = IndexPath(item: 0, section: 0)
        
        var section:Int = -1
        var row:Int = -1
        
        let mediaItems = globals.media.active?.mediaItems
        
        if let index = mediaItems!.index(of: mediaItem!) {
            switch globals.grouping! {
            case Grouping.YEAR:
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.yearSection!)!
                break
                
            case Grouping.TITLE:
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.multiPartSectionSort!)!
                break
                
            case Grouping.BOOK:
                // For mediaItem.books.count > 1 this arbitrarily selects the first one, which may not be correct.
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.bookSections.first!)!
                break
                
            case Grouping.SPEAKER:
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.speakerSection!)!
                break
                
            case Grouping.CLASS:
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.classSection!)!
                break
                
            case Grouping.EVENT:
                section = globals.media.active!.section!.indexStrings!.index(of: mediaItem!.eventSection!)!
                break
                
            default:
                break
            }
            
            row = index - globals.media.active!.sectionIndexes![section]
        }
        
        //            print(section)
        
        if (section > -1) && (row > -1) {
            indexPath = IndexPath(row: row,section: section)
            
//            print(tableView.numberOfSections,tableView.numberOfRows(inSection: section),indexPath)

            //            print("\(globals.mediaItemSelected?.title)")
            //            print("Row: \(indexPath.item)")
            //            print("Section: \(indexPath.section)")
            
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

            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.setEditing(false, animated: true)
            })

            if (select) {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
                })
            }
            
            if (scroll) {
                //Scrolling when the user isn't expecting it can be jarring.
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.scrollToRow(at: indexPath, at: position, animated: false)
                })
            }
        }
    }

    
    fileprivate func setupTag()
    {
        DispatchQueue.main.async(execute: { () -> Void in
            switch globals.media.tags.showing! {
            case Constants.ALL:
                self.tagLabel.text = Constants.All // searchBar.placeholder
                break
                
            case Constants.TAGGED:
                self.tagLabel.text = globals.media.tags.selected // searchBar.placeholder
                break
                
            default:
                break
            }
        })
    }
    
    fileprivate func setupTitle()
    {
        let titleString : String?
        
        let attrTitleString = NSMutableAttributedString()
        
        attrTitleString.append(NSAttributedString(string: "Media",   attributes: Constants.Fonts.Attributes.titleGrey))
        
        if !globals.mediaPlayer.isZoomed {
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
            
            attrTitleString.append(NSAttributedString(string: "\n",   attributes: Constants.Fonts.Attributes.normal))
            attrTitleString.append(NSAttributedString(string: " ",   attributes: Constants.Fonts.Attributes.bold))

            label.attributedText = attrTitleString
            
//            if titleString != Constants.CBC.LONG, let text = label.text {
//                label.text = text + "\n" + titleString
//                
//                attrTitleString.append(NSAttributedString(string: "\n",   attributes: Constants.Fonts.Attributes.normal))
//                attrTitleString.append(NSAttributedString(string: titleString,   attributes: Constants.Fonts.Attributes.bold))
//                label.attributedText = attrTitleString
//            }
            
            navigationItem.titleView = label
        }
    }

//    func setupTitle()
//    {
//        if !globals.isLoading {
//            navigationItem.title = Constants.CBC.TITLE.SHORT
//        }
//    }
    
    func updateSearch()
    {
        guard globals.search.valid else {
            return
        }
        
        updateSearchResults(globals.search.text,completion: nil)
    }
    
    func liveView()
    {
//        globals.mediaPlayer.killPIP = true
        performSegue(withIdentifier: Constants.SEGUE.SHOW_LIVE, sender: self)
    }
    
    func playerView()
    {
        globals.gotoPlayingPaused = true
//        globals.mediaPlayer.killPIP = true
        performSegue(withIdentifier: Constants.SEGUE.SHOW_MEDIAITEM, sender: self)
    }

    func endSearch()
    {
        globals.search.active = false
        globals.search.text = nil
        
        globals.clearDisplay()
        
        globals.setupDisplay(globals.media.active)
        
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
            if globals.search.active {
                textField.text = globals.search.text
            } else {
                textField.placeholder = "search string"
            }
        })
        
        let searchAction = UIAlertAction(title: "Search", style: UIAlertActionStyle.default, handler: {
            alertItem -> Void in
            if let searchText = (alert.textFields![0] as UITextField).text {
                print(searchText)
                
                if (searchText != Constants.EMPTY_STRING) { //
                    globals.search.active = true
                    globals.search.text = searchText.uppercased()
                    
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
        
        if let mediaItemTags = globals.media.all?.mediaItemTags {
            strings.append(contentsOf: mediaItemTags)
        }
        
        if let navigationController = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController,
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
    
    func menuButtonAction(tap:UITapGestureRecognizer)
    {
        print("MTVC menu button pressed")
        
        if !Thread.isMainThread {
            print("NOT MAIN THREAD")
        }

        guard globals.popoverNavCon == nil else {
            return
        }

        setNeedsFocusUpdate()
        
        globals.popoverNavCon = self.storyboard!.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW_NAV) as? UINavigationController
        
        if globals.popoverNavCon != nil, let popover = globals.popoverNavCon?.viewControllers[0] as? PopoverTableViewController {
            globals.popoverNavCon?.modalPresentationStyle = .fullScreen
            
            popover.navigationItem.title = "Menu Options"
            
            popover.delegate = self
            
            popover.purpose = .selectingMenu
            
            var strings = [String]()

            if (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
                if !globals.mediaPlayer.isZoomed {
                    if !globals.showingAbout {
                        if globals.mediaPlayer.loaded && (globals.mediaPlayer.mediaItem?.playing == Playing.video) {
                            strings.append("Toggle Zoom")
                        }
                        strings.append("About")
                    } else {
                        if (globals.mediaPlayer.mediaItem != nil) {
                            if let nvc = self.splitViewController!.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                                if let myvc = nvc.topViewController as? MediaViewController {
                                    if (myvc.selectedMediaItem != nil) {
                                        if (myvc.selectedMediaItem != globals.mediaPlayer.mediaItem) {
                                            // The mediaItemPlaying is not the one showing
                                            strings.append("Current Selection")
                                        } else {
                                            // The mediaItemPlaying is the one showing
                                        }
                                    } else {
                                        // The mediaItemPlaying can't be showing because there is not selectedMediaItem.
                                        strings.append("Current Selection")
                                    }
                                } else {
                                    // About is showing
                                    strings.append("Current Selection")
                                }
                            }
                        } else {
                            //Nothing to show
                            strings.append("Library")
                        }
                    }
                    
                    if globals.streamEntries?.count > 0, globals.reachability.currentReachabilityStatus != .notReachable {
                        strings.append("Live")
                    }
                    
                    strings.append("Category")
                    if let count = globals.media.all?.mediaItemTags?.count, count > 0 {
                        strings.append("Series")
                    }
                    
                    strings.append("Sort")
                    strings.append("Group")
                    strings.append("Index")
                    
                    strings.append("Search")
                } else {
                    strings.append("Toggle Zoom")
                }
            } else {
                strings.append("Library")
            }
            
            popover.section.strings = strings
            
            popover.section.showIndex = false
            popover.section.showHeaders = false
            
            present(globals.popoverNavCon!, animated: true, completion: nil )
        }
    }
    
    func playPauseButtonAction(tap:UITapGestureRecognizer)
    {
        print("play pause button pressed")
        
//        if (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
//            DispatchQueue.main.async(execute: { () -> Void in
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PLAY_PAUSE), object: nil)
//            })
//        } else {
        if let state = globals.mediaPlayer.state {
            switch state {
            case .playing:
                globals.mediaPlayer.pause()
                
            case .paused:
                globals.mediaPlayer.play()
                
            case .stopped:
                print("stopped")
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PLAY_PAUSE), object: nil)
                })
                
            default:
                print("default")
                break
            }
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.PLAY_PAUSE), object: nil)
            })
        }
//        }
    }
    
    func willEnterForeground()
    {
        
    }
    
    func didBecomeActive()
    {
        guard globals.mediaRepository.list == nil else {
            return
        }
        
//        tableView.isHidden = true
        
        //            disableBarButtons()
        
        loadCategories()
        
        // Download or Load
        
        switch jsonSource {
        case .download:
            //                downloadJSON()
            break
            
        case .direct:
            tableView.isHidden = true
            
            loadMediaItems()
                {
                    if globals.mediaRepository.list == nil {
                        let alert = UIAlertController(title: "No media available.",
                                                      message: "Please check your network connection and try again.",
                                                      preferredStyle: UIAlertControllerStyle.alert)
                        
                        let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
                            self.setupListActivityIndicator()
                        })
                        alert.addAction(action)
                        
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.selectedMediaItem = globals.selectedMediaItem.master
                        
                        if globals.search.active && !globals.search.complete { // && globals.search.transcripts
                            self.updateSearchResults(globals.search.text,completion: {
                                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                    DispatchQueue.main.async(execute: { () -> Void in
                                        self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle)
                                    })
                                })
                            })
                        } else {
                            // Reload the table
                            self.tableView.reloadData()
                            
                            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                                DispatchQueue.main.async(execute: { () -> Void in
                                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle)
                                })
                            })
                        }
                    }
                    
                    self.tableView.isHidden = false
            }
            break
        }

//        loadMediaItems()
//            {
//                if globals.mediaRepository.list == nil {
//                    let alert = UIAlertController(title: "No media available.",
//                                                  message: "Please check your network connection and try again.",
//                                                  preferredStyle: UIAlertControllerStyle.alert)
//                    
//                    let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) -> Void in
//                        self.setupListActivityIndicator()
//                    })
//                    alert.addAction(action)
//                    
//                    self.present(alert, animated: true, completion: nil)
//                } else {
//                    self.selectedMediaItem = globals.selectedMediaItem.master
//                    
//                    if globals.search.active && !globals.search.complete { // && globals.search.transcripts
//                        self.updateSearchResults(globals.search.text,completion: {
//                            DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                                DispatchQueue.main.async(execute: { () -> Void in
//                                    self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle)
//                                })
//                            })
//                        })
//                    } else {
//                        // Reload the table
//                        self.tableView.reloadData()
//                        
//                        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
//                            DispatchQueue.main.async(execute: { () -> Void in
//                                self.selectOrScrollToMediaItem(self.selectedMediaItem, select: true, scroll: true, position: UITableViewScrollPosition.middle)
//                            })
//                        })
//                    }
//                }
//                
//                self.tableView.isHidden = false
//        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
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
        globals.freeMemory()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        guard !globals.mediaPlayer.isZoomed else {
            return false
        }
        
        guard (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) else {
            print("Player is LIVE STREAMING.")
            return false
        }

        var show:Bool
        
        show = true

    //    print("shouldPerformSegueWithIdentifier")
    //    print("Selected: \(globals.mediaItemSelected?.title)")
    //    print("Last Selected: \(globals.mediaItemLastSelected?.title)")
    //    print("Playing: \(globals.player.playing?.title)")
        
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
        if let navCon = dvc as? UINavigationController {
            dvc = navCon.visibleViewController!
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
                globals.showingAbout = true
                break
                
            case Constants.SEGUE.SHOW_MEDIAITEM:
                if globals.mediaPlayer.url == URL(string:Constants.URL.LIVE_STREAM) { // (globals.mediaPlayer.pip == .stopped)
                    globals.mediaPlayer.pause()
                }
                
                globals.showingAbout = false
                if (globals.gotoPlayingPaused) {
                    globals.gotoPlayingPaused = !globals.gotoPlayingPaused

                    if let destination = dvc as? MediaViewController {
                        destination.selectedMediaItem = globals.mediaPlayer.mediaItem
                    }
                } else {
                    if let myCell = sender as? MediaTableViewCell {
                        if (selectedMediaItem != myCell.mediaItem) || (globals.history == nil) {
                            globals.addToHistory(myCell.mediaItem)
                        }
                        selectedMediaItem = myCell.mediaItem //globals.media.activeMediaItems![index]

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

    func numberOfSections(in tableView: UITableView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        //return series.count
        return globals.display.section.headers != nil ? globals.display.section.headers!.count : 0
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
    {
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if globals.display.section.headers != nil {
            if section < globals.display.section.headers!.count {
                return globals.display.section.headers![section]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func tableView(_ TableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        //#warning Incomplete method implementation -- Return the number of items in the section
        if globals.display.section.counts != nil {
            if section < globals.display.section.counts!.count {
                return globals.display.section.counts![section]
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.MEDIAITEM, for: indexPath) as! MediaTableViewCell
        
        cell.hideUI()
        
        cell.searchText = globals.search.active ? globals.search.text : nil
        
        // Configure the cell
        if (globals.display.section.indexes != nil) && (globals.display.mediaItems != nil) {
            if indexPath.section < globals.display.section.indexes!.count {
                if let section = globals.display.section.indexes?[indexPath.section] {
                    if section + indexPath.row < globals.display.mediaItems!.count {
                        cell.mediaItem = globals.display.mediaItems?[section + indexPath.row]
                    } else {
                        print("No mediaItem for cell!")
                    }
                } else {
                    print("No mediaItem for cell!")
                }
            } else {
                print("No mediaItem for cell!")
            }
        } else {
            print("No mediaItem for cell!")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        guard section < globals.display.section.headers?.count, let title = globals.display.section.headers?[section] else {
            return Constants.HEADER_HEIGHT
        }
        
        let heightSize: CGSize = CGSize(width: tableView.frame.width - 20, height: .greatestFiniteMagnitude)
        
        let height = title.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: Constants.Fonts.Attributes.bold, context: nil).height
        
//        print(height,max(Constants.HEADER_HEIGHT,height + 28))
        
        return max(Constants.HEADER_HEIGHT,height + 28)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        if let header = view as? UITableViewHeaderFooterView {
            //            print(header.textLabel?.text)
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
        
        if section >= 0, section < globals.display.section.headers?.count, let title = globals.display.section.headers?[section] {
            view?.contentView.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0)
            
            if view?.label == nil {
                view?.label = UILabel()
                
                view?.label?.numberOfLines = 0
                view?.label?.lineBreakMode = .byWordWrapping
                
                view?.label?.translatesAutoresizingMaskIntoConstraints = false
                
                view?.addSubview(view!.label!)
                
                view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[label]-10-|", options: [.alignAllCenterY], metrics: nil, views: ["label":view!.label!]))
                view?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[label]-10-|", options: [.alignAllCenterX], metrics: nil, views: ["label":view!.label!]))
            }
            
            view?.label?.attributedText = NSAttributedString(string: title,   attributes: Constants.Fonts.Attributes.bold)
            
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

        guard !globals.mediaPlayer.isZoomed else {
            return
        }
        
        guard (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) else {
            print("Player is LIVE STREAMING.")
            return
        }
        
        if let cell: MediaTableViewCell = tableView.cellForRow(at: indexPath) as? MediaTableViewCell {
            selectedMediaItem = cell.mediaItem
//            print(selectedMediaItem)
        } else {
            
        }
        
        preferredFocusView = splitViewController?.viewControllers[1].view
    }
    
    func tableView(_ tableView:UITableView, didDeselectRowAt indexPath: IndexPath) {
//        print("didDeselect")

//        if let cell: MediaTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? MediaTableViewCell {
//
//        } else {
//            
//        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return false //actionsAtIndexPath(tableView, indexPath: indexPath) != nil
    }
    
    func authentication()
    {
        var request = URLRequest(url: URL(string: "https://17iPVurdk9fn2ZKLVnnfqN4HKKIb9WXMKzN0l5K5:@bibles.org/v2/eng-NASB/passages.js?q[]=")!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                print("error=\(String(describing: error))")
                return
            }
            
            print("response = \(String(describing: response))")
            
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
    }
    
    /*
     // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath)
    {
        switch editingStyle {
        case .delete:
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            break

        case .insert:
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            break

        case .none:
            break
        }
    }
     */
    
    /*
     // Override to support rearranging the table view.
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, toIndexPath: NSIndexPath) {

    }
     */
 
    /*
     // Override to support conditional rearranging of the table view.
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
     */

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    func tableView(_ tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: IndexPath) -> Bool {
        print("shouldHighlight")
        return true
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAtIndexPath indexPath: IndexPath) {
        print("didHighlight")
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: IndexPath) {
        print("Unhighlighted")
    }
     */
    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: NSIndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: AnyObject?) {
        print("performAction")
    }
     */
}
