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
                if (streamEntry?.storage != nil) {
                    defaults.set(streamEntry?.storage,forKey: Constants.SETTINGS.LIVE)
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

    @objc func clearView()
    {
        Thread.onMainThread {
            Globals.shared.mediaPlayer.view?.isHidden = true
            self.logo.isHidden = false
        }
    }
    
    @objc func liveView()
    {
        Thread.onMainThread {
            self.setupLivePlayerView()
            
            Globals.shared.mediaPlayer.view?.isHidden = false
            self.logo.isHidden = true
        }
    }
    
    func addNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        addNotifications()
        
        setupLivePlayerView()
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
        Globals.shared.freeMemory()
    }

    @IBOutlet weak var logo: UIImageView!
    
    fileprivate func setupLivePlayerView()
    {
        guard let splitViewController = splitViewController else {
            return
        }
        
        if (Globals.shared.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
            Globals.shared.mediaPlayer.pause() // IfPlaying

            Globals.shared.mediaPlayer.setup(url: URL(string:Constants.URL.LIVE_STREAM),playOnLoad:true)
            Globals.shared.mediaPlayer.setupPlayingInfoCenter()
        }
        
        Globals.shared.mediaPlayer.showsPlaybackControls = true
        
        if (Globals.shared.mediaPlayer.view != nil) {
            Globals.shared.mediaPlayer.view?.isHidden = true
            Globals.shared.mediaPlayer.view?.removeFromSuperview()
            
            Globals.shared.mediaPlayer.view?.frame = splitViewController.view.bounds // self.view.bounds // webView.bounds
            
            view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            if let view = Globals.shared.mediaPlayer.view {
                splitViewController.view.addSubview(view)
                
                let top = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(top)
                let bottom = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(bottom)
                let leading = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(leading)
                let trailing = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(trailing)

                let centerX = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(centerX)
                let centerY = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(centerY)
                
                let width = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(width)
                let height = NSLayoutConstraint(item: view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: view.superview, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.0, constant: 0.0)
                view.superview?.addConstraint(height)

                self.view.setNeedsLayout()

                self.view.bringSubviewToFront(view)
                
                view.isHidden = false
            }

            // For UI
            DispatchQueue.global(qos: .background).async {
                Thread.sleep(forTimeInterval: 0.1)
                Globals.shared.mediaPlayer.play()
            }
        }
    }
}
