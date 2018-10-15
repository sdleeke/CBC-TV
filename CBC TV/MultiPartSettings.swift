//
//  MultiPartSettings.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class MultiPartSettings
{
    weak var mediaItem:MediaItem?
    
    init(mediaItem:MediaItem?)
    {
        if (mediaItem == nil) {
            print("nil mediaItem in Settings init!")
        }
        self.mediaItem = mediaItem
    }
    
    subscript(key:String) -> String?
    {
        get {
            guard let mediaItem = mediaItem else {
                print("mediaItem == nil in MultiPartSettings!")
                return nil
            }
            
            return Globals.shared.multiPartSettings?[mediaItem.seriesID]?[key]
        }
        set {
            guard let mediaItem = mediaItem else {
                print("mediaItem == nil in MultiPartSettings!")
                return
            }
            
            if Globals.shared.multiPartSettings == nil {
                Globals.shared.multiPartSettings = [String:[String:String]]()
            }
            
            guard (Globals.shared.multiPartSettings != nil) else {
                print("Globals.shared.viewSplits == nil in SeriesSettings!")
                return
            }
            
            if (Globals.shared.multiPartSettings?[mediaItem.seriesID] == nil) {
                Globals.shared.multiPartSettings?[mediaItem.seriesID] = [String:String]()
            }
            if (Globals.shared.multiPartSettings?[mediaItem.seriesID]?[key] != newValue) {
                Globals.shared.multiPartSettings?[mediaItem.seriesID]?[key] = newValue
                
                // For a high volume of activity this can be very expensive.
                Globals.shared.saveSettingsBackground()
            }
        }
    }
}
