//
//  Media.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

struct MediaNeed {
    var sorting:Bool = true
    var grouping:Bool = true
}

class Media {
    var need = MediaNeed()
    
    //All mediaItems
    var all:MediaListGroupSort?
    
    //The mediaItems with the selected tags, although now we only support one tag being selected
    var tagged = [String:MediaListGroupSort]()
    
    var tags = Tags()
    
    var toSearch:MediaListGroupSort? {
        get {
            guard let showing = tags.showing else {
                return nil
            }
            
            var mediaItems:MediaListGroupSort?
            
            switch showing {
            case Constants.TAGGED:
                if let selected = tags.selected {
                    mediaItems = tagged[selected]
                }
                break
                
            case Constants.ALL:
                mediaItems = all
                break
                
            default:
                break
            }
            
            return mediaItems
        }
    }
    
    var active:MediaListGroupSort? {
        get {
            guard let showing = tags.showing else {
                return nil
            }
            
            var mediaItems:MediaListGroupSort?
            
            switch showing {
            case Constants.TAGGED:
                if let selected = tags.selected {
                    mediaItems = tagged[selected]
                }
                break
                
            case Constants.ALL:
                mediaItems = all
                break
                
            default:
                break
            }
            
            if Globals.shared.search.active {
                if let searchText = Globals.shared.search.text?.uppercased() {
                    mediaItems = mediaItems?.searches?[searchText]
                }
            }
            
            return mediaItems
        }
    }
}
