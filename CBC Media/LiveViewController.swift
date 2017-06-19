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

class LiveViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        setupLivePlayerView()
    }

    func clearView()
    {
        DispatchQueue.main.async {
            globals.mediaPlayer.view?.isHidden = true
//            self.textView.isHidden = true
            self.logo.isHidden = false
        }
    }
    
    func liveView()
    {
        DispatchQueue.main.async {
            self.setupLivePlayerView()
            
            globals.mediaPlayer.view?.isHidden = false
//            self.textView.isHidden = false
            self.logo.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        logo.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(LiveViewController.clearView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.CLEAR_VIEW), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LiveViewController.liveView), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.LIVE_VIEW), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }

    @IBOutlet weak var logo: UIImageView!
    
    fileprivate func setupLivePlayerView()
    {
        guard (splitViewController != nil) else {
            return
        }
        
        if (globals.mediaPlayer.url != URL(string:Constants.URL.LIVE_STREAM)) {
            globals.mediaPlayer.pause() // IfPlaying

            globals.mediaPlayer.setup(url: URL(string:Constants.URL.LIVE_STREAM),playOnLoad:true)
            globals.mediaPlayer.setupPlayingInfoCenter()
        }
        
        globals.mediaPlayer.showsPlaybackControls = true
        
        splitViewController?.preferredDisplayMode = .primaryHidden
        
        if (globals.mediaPlayer.view != nil) {
            globals.mediaPlayer.view?.isHidden = true
            globals.mediaPlayer.view?.removeFromSuperview()
            
            globals.mediaPlayer.view?.frame = view.bounds // webView.bounds
            
            view.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
            
            self.view.addSubview(globals.mediaPlayer.view!)
            
            let centerX = NSLayoutConstraint(item: globals.mediaPlayer.view!, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: globals.mediaPlayer.view!.superview, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0)
            globals.mediaPlayer.view!.superview!.addConstraint(centerX)
            
            let centerY = NSLayoutConstraint(item: globals.mediaPlayer.view!, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: globals.mediaPlayer.view!.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0)
            globals.mediaPlayer.view!.superview!.addConstraint(centerY)
            
            let width = NSLayoutConstraint(item: globals.mediaPlayer.view!, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: globals.mediaPlayer.view!.superview, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0.0)
            globals.mediaPlayer.view!.superview!.addConstraint(width)
            
            let height = NSLayoutConstraint(item: globals.mediaPlayer.view!, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: globals.mediaPlayer.view!.superview, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 0.0)
            globals.mediaPlayer.view!.superview!.addConstraint(height)

            view.setNeedsLayout()

            view.bringSubview(toFront: globals.mediaPlayer.view!)

            globals.mediaPlayer.view?.isHidden = false

            DispatchQueue.global(qos: .background).async {
                Thread.sleep(forTimeInterval: 0.1)
                globals.mediaPlayer.play()
            }
        }
    }
}
