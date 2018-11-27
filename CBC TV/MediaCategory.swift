//
//  MediaCategory.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class MediaCategory
{
    var dicts:[String:String]?
    
    var filename:String?
    {
        get {
            guard let selectedID = selectedID else {
                return nil
            }
            
            return Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES + selectedID +  Constants.JSON.FILENAME_EXTENSION
        }
    }
    
    var names:[String]?
    {
        get {
            guard let keys = dicts?.keys else {
                return nil
            }
            
            return [String](keys).sorted()
        }
    }
    
    // This doesn't work if we someday allow multiple categories to be selected at the same time - unless the string contains multiple categories, as with tags.
    // In that case it would need to be an array.  Not a big deal, just a change.
    var selected:String?
    {
        get {
            if UserDefaults.standard.object(forKey: Constants.MEDIA_CATEGORY) == nil {
                UserDefaults.standard.set(Constants.Strings.Sermons, forKey: Constants.MEDIA_CATEGORY)
            }
            
            return UserDefaults.standard.string(forKey: Constants.MEDIA_CATEGORY)
        }
        set {
            if selected != nil {
                UserDefaults.standard.set(newValue, forKey: Constants.MEDIA_CATEGORY)
            } else {
                UserDefaults.standard.removeObject(forKey: Constants.MEDIA_CATEGORY)
            }
            
            UserDefaults.standard.synchronize()
        }
    }
    
    var selectedID:String?
    {
        get {
            guard let selected = selected, dicts?[selected] != nil else {
                return "1"
            }
            
            return dicts?[selected]
        }
    }
    
    var settings:[String:[String:String]]?
    
    var allowSaveSettings = true
    
    func saveSettingsBackground()
    {
        if allowSaveSettings {
            print("saveSettingsBackground")
            
            // Should be an opQueue
            DispatchQueue.global(qos: .background).async {
                self.saveSettings()
            }
        }
    }
    
    func saveSettings()
    {
        if allowSaveSettings {
            print("saveSettings")
            let defaults = UserDefaults.standard
            defaults.set(settings, forKey: Constants.SETTINGS.KEY.CATEGORY)
            defaults.synchronize()
        }
    }
    
    subscript(key:String) -> String?
    {
        get {
            if let selected = selected {
                return settings?[selected]?[key]
            } else {
                return nil
            }
        }
        set {
            guard let selected = selected else {
                print("selected == nil!")
                return
            }
            
            if settings == nil {
                settings = [String:[String:String]]()
            }
            
            guard (settings != nil) else {
                print("settings == nil!")
                return
            }
            
            if (settings?[selected] == nil) {
                settings?[selected] = [String:String]()
            }
            if (settings?[selected]?[key] != newValue) {
                settings?[selected]?[key] = newValue
                
                // For a high volume of activity this can be very expensive.
                saveSettingsBackground()
            }
        }
    }
    
    var tag:String?
    {
        get {
            return self[Constants.SETTINGS.KEY.COLLECTION]
        }
        set {
            self[Constants.SETTINGS.KEY.COLLECTION] = newValue
        }
    }
    
    var playing:String?
    {
        get {
            return self[Constants.SETTINGS.MEDIA_PLAYING]
        }
        set {
            self[Constants.SETTINGS.MEDIA_PLAYING] = newValue
        }
    }
    
    var selectedInMaster:String?
    {
        get {
            return self[Constants.SETTINGS.KEY.SELECTED_MEDIA.MASTER]
        }
        set {
            self[Constants.SETTINGS.KEY.SELECTED_MEDIA.MASTER] = newValue
        }
    }
    
    var selectedInDetail:String?
    {
        get {
            return self[Constants.SETTINGS.KEY.SELECTED_MEDIA.DETAIL]
        }
        set {
            self[Constants.SETTINGS.KEY.SELECTED_MEDIA.DETAIL] = newValue
        }
    }
}
