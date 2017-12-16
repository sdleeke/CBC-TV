//
//  LiveViewController.swift
//  CBC
//
//  Created by Steve Leeke on 11/9/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class LiveViewController: UIViewController
{
    var streamEntry:StreamEntry?
    {
        didSet {
            let defaults = UserDefaults.standard
            if streamEntry != nil {
                if (streamEntry?.dict != nil) {
                    defaults.set(streamEntry?.dict,forKey: Constants.SETTINGS.LIVE)
                } else {
                    //Should not happen
                    defaults.removeObject(forKey: Constants.SETTINGS.LIVE)
                }
            } else {
                defaults.removeObject(forKey: Constants.SETTINGS.LIVE)
            }
            defaults.synchronize()
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

    }

    func clearView()
    {
        Thread.onMainThread {
            globals.mediaPlayer.view?.isHidden = true
            self.logo.isHidden = false
        }
    }
    
    func liveView()
    {
        Thread.onMainThread {
            self.setupLivePlayerView()
            
            globals.mediaPlayer.view?.isHidden = false
            self.logo.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
//        logo.isHidden = true
        
        setupLivePlayerView()

//        navigationItem.title = streamEntry?.name
        
        NotificationCenter.default.addObserver(self, selector: #selector(LiveViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LiveViewController.liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }

    @IBOutlet weak var logo: UIImageView!
    
    fileprivate func setupLivePlayerView()
    {
        guard let splitViewController = splitViewController else {
            return
        }
        
        if (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
            globals.mediaPlayer.pause() // IfPlaying

            globals.mediaPlayer.setup(url: URL(string:Constants.URL.LIVE_STREAM),playOnLoad:true)
            globals.mediaPlayer.setupPlayingInfoCenter()
        }
        
        globals.mediaPlayer.showsPlaybackControls = true
        
//        splitViewController.preferredDisplayMode = .primaryHidden
        
        if (globals.mediaPlayer.view != nil) {
            globals.mediaPlayer.view?.isHidden = true
            globals.mediaPlayer.view?.removeFromSuperview()
            
            globals.mediaPlayer.view?.frame = splitViewController.view.bounds // self.view.bounds // webView.bounds
            
            view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            if let view = globals.mediaPlayer.view {
                splitViewController.view.addSubview(view)
                
                let top = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(top)
                let bottom = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(bottom)
                let leading = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(leading)
                let trailing = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(trailing)

                let centerX = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(centerX)
                let centerY = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(centerY)
                
                let width = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: view.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(width)
                let height = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: view.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(height)

                self.view.setNeedsLayout()

                self.view.bringSubview(toFront: view)
                
                view.isHidden = false
            }

            DispatchQueue.global(qos: .background).async {
                Thread.sleep(forTimeInterval: 0.1)
                globals.mediaPlayer.play()
            }
        }
    }
}
