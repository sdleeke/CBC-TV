//
//  Tags.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class Tags
{
    var showing:String?
    {
        get {
            return selected == nil ? Constants.ALL : Constants.TAGGED
        }
    }
    
    var selected:String?
    {
        get {
            return Globals.shared.mediaCategory.tag
        }
        set {
            if let newValue = newValue {
                if (Globals.shared.media.tagged[newValue] == nil) {
                    if Globals.shared.media.all == nil {
                        //This is filtering, i.e. searching all mediaItems => s/b in background
                        Globals.shared.media.tagged[newValue] = MediaListGroupSort(mediaItems: mediaItemsWithTag(Globals.shared.mediaRepository.list, tag: newValue))
                    } else {
                        Globals.shared.media.tagged[newValue] = MediaListGroupSort(mediaItems: Globals.shared.media.all?.tagMediaItems?[newValue.withoutPrefixes])
                    }
                }
            } else {
                
            }
            
            Globals.shared.mediaCategory.tag = newValue
        }
    }
}
