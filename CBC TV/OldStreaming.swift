//
//  Streaming.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class OldStreaming
{
    var entries:[[String:Any]]?
    
    var strings:[String]?
    {
        get {
            return entries?.filter({ (dict:[String : Any]) -> Bool in
                return StreamEntry(dict)?.startDate > Date()
            }).map({ (dict:[String : Any]) -> String in
                if let string = StreamEntry(dict)?.text {
                    return string
                } else {
                    return "ERROR"
                }
            })
        }
    }
    
    var stringIndex:[String:[String]]?
    {
        get {
            var stringIndex = [String:[String]]()
            
            let now = Date().addHours(0) // For convenience in testing.
            
            if let entries = entries {
                for event in entries {
                    let streamEntry = StreamEntry(event)
                    
                    if let start = streamEntry?.start, let end = streamEntry?.end, let text = streamEntry?.text {
                        // All streaming to start 10 minutes before and end 10 minutes after  the scheduled start time
                        if ((now.timeIntervalSince1970 + 10*60) >= Double(start)) && ((now.timeIntervalSince1970 - 10*60) <= Double(end)) {
                            if stringIndex["Playing"] == nil {
                                stringIndex["Playing"] = [String]()
                            }
                            stringIndex["Playing"]?.append(text)
                        } else {
                            if (now < streamEntry?.startDate) {
                                if stringIndex["Upcoming"] == nil {
                                    stringIndex["Upcoming"] = [String]()
                                }
                                stringIndex["Upcoming"]?.append(text)
                            }
                        }
                    }
                }
                
                if stringIndex["Playing"]?.count == 0 {
                    stringIndex["Playing"] = nil
                }
                
                return stringIndex.count > 0 ? stringIndex : nil
            } else {
                return nil
            }
        }
    }
    
    var entryIndex:[String:[[String:Any]]]?
    {
        get {
            var entryIndex = [String:[[String:Any]]]()
            
            let now = Date().addHours(0) // For convenience in testing.
            
            if let entries = entries {
                for event in entries {
                    let entry = StreamEntry(event)
                    
                    if let start = entry?.start, let end = entry?.end {
                        // All streaming to start 10 minutes before and end 10 minutes after the scheduled start time
                        if ((now.timeIntervalSince1970 + 10*60) >= Double(start)) && ((now.timeIntervalSince1970 - 10*60) <= Double(end)) {
                            if entryIndex["Playing"] == nil {
                                entryIndex["Playing"] = [[String:Any]]()
                            }
                            entryIndex["Playing"]?.append(event)
                        } else {
                            if (now < entry?.startDate) {
                                if entryIndex["Upcoming"] == nil {
                                    entryIndex["Upcoming"] = [[String:Any]]()
                                }
                                entryIndex["Upcoming"]?.append(event)
                            }
                        }
                    }
                }
                
                if entryIndex["Playing"]?.count == 0 {
                    entryIndex["Playing"] = nil
                }
                
                return entryIndex.count > 0 ? entryIndex : nil
            } else {
                return nil
            }
        }
    }
    
    var sorted:[[String:Any]]?
    {
        get {
            return entries?.sorted(by: { (firstDict: [String : Any], secondDict: [String : Any]) -> Bool in
                return StreamEntry(firstDict)?.startDate <= StreamEntry(secondDict)?.startDate
            })
        }
    }
    
    var categories:[String:[[String:Any]]]?
    {
        get {
            var categories = [String:[[String:Any]]]()
            
            if let entries = entries {
                for entry in entries {
                    if let name = StreamEntry(entry)?.name {
                        if categories[name] == nil {
                            categories[name] = [[String:Any]]()
                        }
                        categories[name]?.append(entry)
                    }
                }
                
                return categories.count > 0 ? categories : nil
            } else {
                return nil
            }
        }
    }
    
    // Year // Month // Day // Event
    var schedule:[String:[String:[String:[[String:Any]]]]]?
    {
        get {
            var schedule = [String:[String:[String:[[String:Any]]]]]()
            
            if let entries = entries {
                for entry in entries {
                    if let startDate = StreamEntry(entry)?.startDate {
                        if schedule[startDate.year] == nil {
                            schedule[startDate.year] = [String:[String:[[String:Any]]]]()
                        }
                        if schedule[startDate.year]?[startDate.month] == nil {
                            schedule[startDate.year]?[startDate.month] = [String:[[String:Any]]]()
                        }
                        if schedule[startDate.year]?[startDate.month]?[startDate.day] == nil {
                            schedule[startDate.year]?[startDate.month]?[startDate.day] = [[String:Any]]()
                        }
                        schedule[startDate.year]?[startDate.month]?[startDate.day]?.append(entry)
                    }
                }
                
                return schedule.count > 0 ? schedule : nil
            } else {
                return nil
            }
        }
    }
}
