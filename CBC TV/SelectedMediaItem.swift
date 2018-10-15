//
//  SelectedMediaItem.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class SelectedMediaItem
{
    var master:MediaItem?
    {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = Globals.shared.mediaCategory.selectedInMaster {
                selectedMediaItem = Globals.shared.mediaRepository.index?[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        
        set {
            Globals.shared.mediaCategory.selectedInMaster = newValue?.id
        }
    }
    
    var detail:MediaItem?
    {
        get {
            var selectedMediaItem:MediaItem?
            
            if let selectedMediaItemID = Globals.shared.mediaCategory.selectedInDetail {
                selectedMediaItem = Globals.shared.mediaRepository.index?[selectedMediaItemID]
            }
            
            return selectedMediaItem
        }
        
        set {
            Globals.shared.mediaCategory.selectedInDetail = newValue?.id
        }
    }
}
