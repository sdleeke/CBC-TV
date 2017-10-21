//
//  AppDelegate.swift
//  CBC TV
//
//  Created by Steve Leeke on 5/20/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate
{
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool
    {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else {
            return false
        }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MediaViewController else {
            return false
        }
        if topAsDetailController.selectedMediaItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        // Override point for customization after application launch.
        if let splitViewController = window?.rootViewController as? UISplitViewController {
            splitViewController.delegate = self
        }
    
        globals = Globals()

        globals.addAccessoryEvents()
        
        globals.startAudio()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        print("applicationWillResignActive")
        
        Thread.onMainThread { () -> (Void) in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_RESIGN_ACTIVE), object: nil)
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("applicationDidEnterBackground")
        
        if globals.mediaPlayer.isPlaying && (globals.mediaPlayer.mediaItem?.playing == Playing.video) { // && (globals.mediaPlayer.pip != .started)
            globals.mediaPlayer.pause()
        }
        
        Thread.onMainThread { () -> (Void) in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DID_ENTER_BACKGROUND), object: nil)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground")
        
        Thread.onMainThread { () -> (Void) in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_ENTER_FORGROUND), object: nil)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("applicationDidBecomeActive")
        
        globals.mediaPlayer.setupPlayingInfoCenter()
        
        Thread.onMainThread { () -> (Void) in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.DID_BECOME_ACTIVE), object: nil)
        }
    }

    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("applicationWillTerminate")
        Thread.onMainThread { () -> (Void) in
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.WILL_TERMINATE), object: nil)
        }
    }
}

