//
//  StreamEntry.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class StreamEntry
{
    init?(_ storage:[String:Any]?)
    {
        guard storage != nil else {
            return nil
        }
        
        self.storage = storage
    }
    
    var storage : [String:Any]?
    
    subscript(key:String?) -> Any?
    {
        get {
            guard let key = key else {
                return nil
            }
            return storage?[key]
        }
        set {
            guard let key = key else {
                return
            }
            
            storage?[key] = newValue
        }
    }

    var id : Int? {
        get {
            return self["id"] as? Int
        }
    }
    
    var start : Int?
    {
        get {
            return self["start"] as? Int
        }
    }
    
    var startDate : Date?
    {
        get {
            if let start = start {
                return Date(timeIntervalSince1970: TimeInterval(start))
            } else {
                return nil
            }
        }
    }
    
    var end : Int?
    {
        get {
            return self["end"] as? Int
        }
    }
    
    var endDate : Date?
    {
        get {
            if let end = end {
                return Date(timeIntervalSince1970: TimeInterval(end))
            } else {
                return nil
            }
        }
    }
    
    var name : String?
    {
        get {
            return self["name"] as? String
        }
    }
    
    var date : String?
    {
        get {
            return self["date"] as? String
        }
    }
    
    var text : String?
    {
        get {
            if let name = name,let startDate = startDate?.mdyhm,let endDate = endDate?.mdyhm {
                return "\(name)\nStart: \(startDate)\nEnd: \(endDate)"
            } else {
                return nil
            }
        }
    }
}
