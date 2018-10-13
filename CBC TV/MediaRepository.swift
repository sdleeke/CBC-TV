//
//  MediaRepository.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class MediaRepository {
    var list:[MediaItem]? { //Not in any specific order
        willSet {
            
        }
        didSet {
            index = nil
            classes = nil
            events = nil
            
            guard let list = list else {
                return
            }
            
            for mediaItem in list {
                if let id = mediaItem.id {
                    if index == nil {
                        index = [String:MediaItem]()
                    }
                    if index?[id] == nil {
                        index?[id] = mediaItem
                    } else {
                        print("DUPLICATE MEDIAITEM ID: \(mediaItem)")
                    }
                }
                
                if let className = mediaItem.className {
                    if classes == nil {
                        classes = [className]
                    } else {
                        classes?.append(className)
                    }
                }
                
                if let eventName = mediaItem.eventName {
                    if events == nil {
                        events = [eventName]
                    } else {
                        events?.append(eventName)
                    }
                }
            }
            
            Globals.shared.groupings = Constants.groupings
            Globals.shared.groupingTitles = Constants.GroupingTitles
            
            if classes?.count > 0 {
                Globals.shared.groupings.append(GROUPING.CLASS)
                Globals.shared.groupingTitles.append(Grouping.Class)
            }
            
            if events?.count > 0 {
                Globals.shared.groupings.append(GROUPING.EVENT)
                Globals.shared.groupingTitles.append(Grouping.Event)
            }
            
            if let grouping = Globals.shared.grouping, !Globals.shared.groupings.contains(grouping) {
                Globals.shared.grouping = GROUPING.YEAR
            }
        }
    }
    
    var index:[String:MediaItem]?
    var classes:[String]?
    var events:[String]?
}
