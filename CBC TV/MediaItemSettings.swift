//
//  MediaItemSettings.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class MediaItemSettings
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
                return nil
            }
            
            return Globals.shared.mediaItemSettings?[mediaItem.id]?[key]
        }
        set {
            guard let mediaItem = mediaItem else {
                print("mediaItem == nil in Settings!")
                return
            }
            
            if Globals.shared.mediaItemSettings == nil {
                Globals.shared.mediaItemSettings = [String:[String:String]]()
            }
            if (Globals.shared.mediaItemSettings != nil) {
                if (Globals.shared.mediaItemSettings?[mediaItem.id] == nil) {
                    Globals.shared.mediaItemSettings?[mediaItem.id] = [String:String]()
                }
                if (Globals.shared.mediaItemSettings?[mediaItem.id]?[key] != newValue) {
                    //                        print("\(mediaItem)")
                    Globals.shared.mediaItemSettings?[mediaItem.id]?[key] = newValue
                    
                    // For a high volume of activity this can be very expensive.
                    Globals.shared.saveSettingsBackground()
                }
            } else {
                print("Globals.shared.settings == nil in Settings!")
            }
        }
    }
}

