//
//  Search.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class Search
{
    var complete:Bool = true
    
    var active:Bool = false
    {
        willSet {
            
        }
        didSet {
            if !active {
                complete = true
            }
        }
    }
    
    var valid:Bool
    {
        get {
            return active && extant
        }
    }
    
    var extant:Bool
    {
        get {
            return (text != nil) && (text != Constants.EMPTY_STRING)
        }
    }
    
    var text:String?
    {
        willSet {
            
        }
        didSet {
            if (text != oldValue) && !Globals.shared.isLoading {
                if extant {
                    UserDefaults.standard.set(text, forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                } else {
                    UserDefaults.standard.removeObject(forKey: Constants.SEARCH_TEXT)
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    var transcripts:Bool
    {
        get {
            return UserDefaults.standard.bool(forKey: Constants.USER_SETTINGS.SEARCH_TRANSCRIPTS)
        }
        set {
            // Setting to nil can cause a crash.
            Globals.shared.media.toSearch?.searches = [String:MediaListGroupSort]()
            
            UserDefaults.standard.set(newValue, forKey: Constants.USER_SETTINGS.SEARCH_TRANSCRIPTS)
            UserDefaults.standard.synchronize()
        }
    }
}
