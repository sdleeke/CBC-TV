//
//  MediaListGroupSort.swift
//  CBC
//
//  Created by Steve Leeke on 12/14/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import AVKit

//Group//String//Sort
typealias MediaGroupSort = [String:[String:[String:[MediaItem]]]]

//Group//String//Name
typealias MediaGroupNames = [String:[String:String]]

class StringNode {
    var string:String?
    
    init(_ string:String?)
    {
        self.string = string
    }
    
    var wordEnding = false
    
    var stringNodes:[StringNode]?
    
    var isLeaf:Bool {
        get {
            return stringNodes == nil
        }
    }
    
    func depthBelow(_ cumulative:Int) -> Int
    {
        if isLeaf {
            return cumulative
        } else {
            var depthsBelow = [Int]()
            
            for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
                depthsBelow.append(stringNode.depthBelow(cumulative + 1))
            }
            
            if let last = depthsBelow.sorted().last {
//                print(depthsBelow)
//                print(depthsBelow.sorted())
//                print("\n")
                return last
            } else {
                return 0
            }
        }
    }
    
    func printWords(_ cumulativeString:String?)
    {
        //        guard string != nil else {
        //            return
        //        }
        
        if wordEnding {
            if cumulativeString != nil {
                if string != nil {
                    print(cumulativeString!+string!)
                } else {
                    print(cumulativeString!)
                }
            } else {
                if string != nil {
                    print(string!)
                }
            }
            
            //            print("\n")
        }
        
        guard stringNodes != nil else {
            return
        }
        
        for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
            //            print(string!+"-")
            if cumulativeString != nil {
                if string != nil {
                    stringNode.printWords(cumulativeString!+string!+"-")
                } else {
                    stringNode.printWords(cumulativeString!+"-")
                }
            } else {
                if string != nil {
                    stringNode.printWords(string!+"-")
                } else {
                    stringNode.printWords(nil)
                }
            }
        }
    }
    
    func htmlWords(_ cumulativeString:String?) -> [String]?
    {
        //        guard string != nil else {
        //            return
        //        }

        var html = [String]()
        
        if wordEnding {
            if cumulativeString != nil {
                if string != nil {
                    let word = cumulativeString! + string! + "</td>"
                    html.append(word)
//                    print(word)
                } else {
                    let word = cumulativeString! + "</td>"
                    html.append(word)
//                    print(word)
                }
            } else {
                if string != nil {
                    let word = "<td>" + string! + "</td>"
                    html.append(word)
//                    print(word)
                }
            }
            
            //            print("\n")
        }

        guard let stringNodes = stringNodes else {
            return html.count > 0 ? html : nil
        }
        
        for stringNode in stringNodes.sorted(by: { $0.string < $1.string }) {
            //            print(string!+"-")
            if cumulativeString != nil {
                if string != nil {
                    if let words = stringNode.htmlWords(cumulativeString!+string!+"</td><td>") {
                        html.append(contentsOf: words)
                    }
                } else {
                    if let words = stringNode.htmlWords(cumulativeString!+"</td><td>") {
                        html.append(contentsOf: words)
                    }
                }
            } else {
                if string != nil {
                    if let words = stringNode.htmlWords("<td>" + string! + "</td><td>") {
                        html.append(contentsOf: words)
                    }
                } else {
                    if let words = stringNode.htmlWords(nil) {
                        html.append(contentsOf: words)
                    }
                }
            }
        }
        
        return html.count > 0 ? html : nil
    }
    
    func addStringNode(_ newString:String?)
    {
        guard (newString != nil) else {
            return
        }

        guard (stringNodes != nil) else {
            let newNode = StringNode(newString)
            newNode.wordEnding = true
            stringNodes = [newNode]
            newNode.stringNodes = [StringNode(Constants.WORD_ENDING)]
            return
        }

        var fragment = newString
        
        var foundNode:StringNode?
        
        var isEmpty = fragment!.isEmpty
        
        while !isEmpty {
            for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
                if stringNode.string?.endIndex >= fragment!.endIndex, stringNode.string?.substring(to: fragment!.endIndex) == fragment {
                    foundNode = stringNode
                    break
                }
            }
            
            if foundNode != nil {
                break
            }
            
            fragment = fragment!.substring(to: fragment!.index(before: fragment!.endIndex))
            
            if fragment != nil {
                isEmpty = fragment!.isEmpty
            } else {
                isEmpty = true
            }
        }
        
        if foundNode != nil {
            foundNode?.addString(newString)
        } else {
            let newNode = StringNode(newString)
            newNode.wordEnding = true
            newNode.stringNodes = [StringNode(Constants.WORD_ENDING)]
            stringNodes?.append(newNode)
        }
    }
    
    func addString(_ newString:String?)
    {
        guard let stringEmpty = newString?.isEmpty, !stringEmpty else {
            return
        }

        guard (string != nil) else {
            addStringNode(newString)
            return
        }
        
        guard (string != newString) else {
            wordEnding = true
            
            var found = false
            
            if var stringNodes = stringNodes {
                for stringNode in stringNodes {
                    if stringNode.string == Constants.WORD_ENDING {
                        found = true
                        break
                    }
                }
                
                if !found {
                    stringNodes.append(StringNode(Constants.WORD_ENDING))
                }
            } else {
                stringNodes = [StringNode(Constants.WORD_ENDING)]
            }
            
            return
        }
        
        var fragment = newString
        
        var isEmpty = fragment!.isEmpty
        
        while !isEmpty {
            if string?.endIndex >= fragment!.endIndex, string?.substring(to: fragment!.endIndex) == fragment {
                break
            }

            fragment = fragment!.substring(to: fragment!.index(before: fragment!.endIndex))

            if fragment != nil {
                isEmpty = fragment!.isEmpty
            } else {
                isEmpty = true
            }
        }
        
        if !isEmpty {
            let stringRemainder = string?.substring(from: fragment!.endIndex)

            let newStringRemainder = newString?.substring(from: fragment!.endIndex)
            
            if let isEmpty = stringRemainder?.isEmpty, !isEmpty {
                let newNode = StringNode(stringRemainder)
                newNode.stringNodes = stringNodes
                
                newNode.wordEnding = wordEnding
                
                if !wordEnding, let index = stringNodes?.index(where: { (stringNode:StringNode) -> Bool in
                    return stringNode.string == Constants.WORD_ENDING
                }) {
                    stringNodes?.remove(at: index)
                }
                
                wordEnding = false
                
                string = fragment
                stringNodes = [newNode]
            }
            
            if let isEmpty = newStringRemainder?.isEmpty, !isEmpty {
                addStringNode(newStringRemainder)
            } else {
                wordEnding = true
            }
        } else {
            // No match!?!?!
        }
    }
    
    func addStrings(_ strings:[String]?)
    {
        guard strings != nil else {
            return
        }
        
        for string in strings! {
            addString(string)
        }
    }
}

class MediaListGroupSort {
    @objc func freeMemory()
    {
//        lexicon = nil
        
        guard searches != nil else {
            return
        }
        
        if !globals.search.active {
            searches = nil
        } else {
            // Is this risky, to try and delete all but the current search?
            if let keys = searches?.keys {
                for key in keys {
                    //                    print(key,globals.search.text)
                    if key != globals.search.text {
                        searches?[key] = nil
                    } else {
                        //                        print(key,globals.search.text)
                    }
                }
            }
        }
    }
    
    var list:[MediaItem]? { //Not in any specific order
        willSet {
            
        }
        didSet {
            if (list != nil) {
                index = [String:MediaItem]()
                
                for mediaItem in list! {
                    index![mediaItem.id!] = mediaItem
                    
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
            }
        }
    }
    
    var index:[String:MediaItem]? //MediaItems indexed by ID.
    var classes:[String]?
    var events:[String]?
    
    var searches:[String:MediaListGroupSort]? // Hierarchical means we could search within searches - but not right now.
    
    var groupSort:MediaGroupSort?
    var groupNames:MediaGroupNames?
    
    var tagMediaItems:[String:[MediaItem]]?//sortTag:MediaItem
    var tagNames:[String:String]?//sortTag:tag
    
    var proposedTags:[String]? {
        get {
            var possibleTags = [String:Int]()
            
            if let tags = mediaItemTags {
                for tag in tags {
                    var possibleTag = tag
                    
                    if possibleTag.range(of: "-") != nil {
                        while possibleTag.range(of: "-") != nil {
                            let range = possibleTag.range(of: "-")
                            
                            let candidate = possibleTag.substring(to: range!.lowerBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            
                            if (Int(candidate) == nil) && !tags.contains(candidate) {
                                if let count = possibleTags[candidate] {
                                    possibleTags[candidate] =  count + 1
                                } else {
                                    possibleTags[candidate] =  1
                                }
                            }

                            possibleTag = possibleTag.substring(from: range!.upperBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        }
                        
                        if !possibleTag.isEmpty {
                            let candidate = possibleTag.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                            if (Int(candidate) == nil) && !tags.contains(candidate) {
                                if let count = possibleTags[candidate] {
                                    possibleTags[candidate] =  count + 1
                                } else {
                                    possibleTags[candidate] =  1
                                }
                            }
                        }
                    }
                }
            }
            
            let proposedTags:[String] = possibleTags.keys.map { (string:String) -> String in
                return string
            }
            return proposedTags.count > 0 ? proposedTags : nil
        }
    }
    
    var mediaItemTags:[String]? {
        get {
            return tagMediaItems?.keys.sorted(by: { $0 < $1 }).map({ (string:String) -> String in
                return self.tagNames![string]!
            })
        }
    }
    
    var mediaItems:[MediaItem]? {
        get {
            return mediaItems(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sortGroup(_ grouping:String?)
    {
        guard (list != nil) else {
            return
        }
        
        var groupedMediaItems = [String:[String:[MediaItem]]]()
        
        for mediaItem in list! {
            var entries:[(string:String,name:String)]?
            
            switch grouping! {
            case Grouping.YEAR:
                entries = [(mediaItem.yearString,mediaItem.yearString)]
                break
                
            case Grouping.TITLE:
                entries = [(mediaItem.multiPartSectionSort,mediaItem.multiPartSection)]
                break
                
            case Grouping.BOOK:
                // Need to update this for the fact that mediaItems can have more than one book.
                if let books = mediaItem.books {
                    for book in books {
                        if entries == nil {
                            entries = [(book,book)]
                        } else {
                            entries?.append((book,book))
                        }
                    }
                }
                if entries == nil {
                    if let scriptureReference = mediaItem.scriptureReference?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                        entries = [(scriptureReference,scriptureReference)]
                    } else {
                        entries = [(Constants.None,Constants.None)]
                    }
                }
                //                if entries?.count > 1 {
                //                    print(mediaItem,entries!)
                //                }
                break
                
            case Grouping.SPEAKER:
                entries = [(mediaItem.speakerSectionSort,mediaItem.speakerSection)]
                break
                
            case Grouping.CLASS:
                entries = [(mediaItem.classSectionSort,mediaItem.classSection)]
                break
                
            case Grouping.EVENT:
                entries = [(mediaItem.eventSectionSort,mediaItem.eventSection)]
                break
                
            default:
                break
            }
            
            if (groupNames?[grouping!] == nil) {
                groupNames?[grouping!] = [String:String]()
            }
            
            if entries != nil {
                for entry in entries! {
                    groupNames?[grouping!]?[entry.string] = entry.name
                    
                    if (groupedMediaItems[grouping!] == nil) {
                        groupedMediaItems[grouping!] = [String:[MediaItem]]()
                    }
                    
                    if groupedMediaItems[grouping!]?[entry.string] == nil {
                        groupedMediaItems[grouping!]?[entry.string] = [mediaItem]
                    } else {
                        groupedMediaItems[grouping!]?[entry.string]?.append(mediaItem)
                    }
                }
            }
        }
        
        if (groupSort?[grouping!] == nil) {
            groupSort?[grouping!] = [String:[String:[MediaItem]]]()
        }
        if (groupedMediaItems[grouping!] != nil) {
            for string in groupedMediaItems[grouping!]!.keys {
                if (groupSort?[grouping!]?[string] == nil) {
                    groupSort?[grouping!]?[string] = [String:[MediaItem]]()
                }
                for sort in Constants.sortings {
                    let array = sortMediaItemsChronologically(groupedMediaItems[grouping!]?[string])
                    
                    switch sort {
                    case Sorting.CHRONOLOGICAL:
                        groupSort?[grouping!]?[string]?[sort] = array
                        break
                        
                    case Sorting.REVERSE_CHRONOLOGICAL:
                        groupSort?[grouping!]?[string]?[sort] = array?.reversed()
                        break
                        
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func mediaItems(grouping:String?,sorting:String?) -> [MediaItem]?
    {
        var groupedSortedMediaItems:[MediaItem]?
        
        if (groupSort == nil) {
            return nil
        }
        
        if (groupSort?[grouping!] == nil) {
            sortGroup(grouping)
        }
        
        //        print("\(groupSort)")
        if (groupSort![grouping!] != nil) {
            for key in groupSort![grouping!]!.keys.sorted(
                by: {
                    switch grouping! {
                    case Grouping.YEAR:
                        switch sorting! {
                        case Sorting.CHRONOLOGICAL:
                            return $0 < $1
                            
                        case Sorting.REVERSE_CHRONOLOGICAL:
                            return $1 < $0
                            
                        default:
                            break
                        }
                        break
                        
                    case Grouping.BOOK:
                        if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                            return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                        } else {
                            return bookNumberInBible($0) < bookNumberInBible($1)
                        }
                        
                    default:
                        return $0.lowercased() < $1.lowercased()
                    }
                    
                    return $0 < $1
            }) {
                let mediaItems = groupSort?[grouping!]?[key]?[sorting!]
                
                if (groupedSortedMediaItems == nil) {
                    groupedSortedMediaItems = mediaItems
                } else {
                    groupedSortedMediaItems?.append(contentsOf: mediaItems!)
                }
            }
        }
        
        return groupedSortedMediaItems
    }
    
    struct Section {
        weak var mlgs:MediaListGroupSort?
        
        init(_ mlgs:MediaListGroupSort?)
        {
            self.mlgs = mlgs
        }
        
        var headerStrings:[String]? {
            get {
                return mlgs?.sectionTitles(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
        
        var counts:[Int]? {
            get {
                return mlgs?.sectionCounts(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
        
        var indexes:[Int]? {
            get {
                return mlgs?.sectionIndexes(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
        
        var indexStrings:[String]? {
            get {
                return mlgs?.sectionIndexTitles(grouping: globals.grouping,sorting: globals.sorting)
            }
        }
    }
    
    lazy var section:Section? = {
        [unowned self] in
        return Section(self)
        }()
    
    func sectionIndexTitles(grouping:String?,sorting:String?) -> [String]?
    {
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Sorting.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Sorting.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        })
    }
    
    func sectionTitles(grouping:String?,sorting:String?) -> [String]?
    {
        return sectionIndexTitles(grouping: grouping,sorting: sorting)?.map({ (string:String) -> String in
            return groupNames![grouping!]![string]!
        })
    }
    
    func sectionCounts(grouping:String?,sorting:String?) -> [Int]?
    {
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Sorting.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Sorting.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            return groupSort![grouping!]![string]![sorting!]!.count
        })
    }
    
    var sectionIndexes:[Int]? {
        get {
            return sectionIndexes(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sectionIndexes(grouping:String?,sorting:String?) -> [Int]?
    {
        var cumulative = 0
        
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Sorting.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Sorting.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            let prior = cumulative
            
            cumulative += groupSort![grouping!]![string]![sorting!]!.count
            
            return prior
        })
    }
    
    init(mediaItems:[MediaItem]?)
    {
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(MediaListGroupSort.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
        
        guard (mediaItems != nil) else {
            return
        }
        
        list = mediaItems
        
        groupNames = MediaGroupNames()
        groupSort = MediaGroupSort()
        
        sortGroup(globals.grouping)

        tagMediaItems = [String:[MediaItem]]()
        tagNames = [String:String]()

        for mediaItem in list! {
            if let tags =  mediaItem.tagsSet {
                for tag in tags {
                    let sortTag = stringWithoutPrefixes(tag)
                    
                    if sortTag == "" {
                        print(sortTag as Any)
                    }

                    if tagMediaItems?[sortTag!] == nil {
                        tagMediaItems?[sortTag!] = [mediaItem]
                    } else {
                        tagMediaItems?[sortTag!]?.append(mediaItem)
                    }
                    tagNames?[sortTag!] = tag
                }
            }
        }
    }
}

