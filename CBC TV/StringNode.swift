//
//  StringNode.swift
//  CBC TV
//
//  Created by Steve Leeke on 10/13/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

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
            guard let stringNodes = stringNodes else {
                return 0
            }
            
            var depthsBelow = [Int]()
            
            for stringNode in stringNodes.sorted(by: { $0.string < $1.string }) {
                depthsBelow.append(stringNode.depthBelow(cumulative + 1))
            }
            
            if let last = depthsBelow.sorted().last {
                return last
            } else {
                return 0
            }
        }
    }
    
    func printWords(_ cumulativeString:String?)
    {
        if wordEnding {
            if let cumulativeString = cumulativeString {
                if let string = string {
                    print(cumulativeString+string)
                } else {
                    print(cumulativeString)
                }
            } else {
                if let string = string {
                    print(string)
                }
            }
        }
        
        guard let stringNodes = stringNodes else {
            return
        }
        
        for stringNode in stringNodes.sorted(by: { $0.string < $1.string }) {
            if let cumulativeString = cumulativeString {
                if let string = string {
                    stringNode.printWords(cumulativeString + string + "-")
                } else {
                    stringNode.printWords(cumulativeString + "-")
                }
            } else {
                if let string = string {
                    stringNode.printWords(string + "-")
                } else {
                    stringNode.printWords(nil)
                }
            }
        }
    }
    
    func htmlWords(_ cumulativeString:String?) -> [String]?
    {
        var html = [String]()
        
        if wordEnding {
            if let cumulativeString = cumulativeString {
                if let string = string {
                    let word = cumulativeString + string + "</td>"
                    html.append(word)
                } else {
                    let word = cumulativeString + "</td>"
                    html.append(word)
                }
            } else {
                if let string = string {
                    let word = "<td>" + string + "</td>"
                    html.append(word)
                }
            }
        }
        
        guard let stringNodes = stringNodes else {
            return html.count > 0 ? html : nil
        }
        
        for stringNode in stringNodes.sorted(by: { $0.string < $1.string }) {
            if let cumulativeString = cumulativeString {
                if let string = string {
                    if let words = stringNode.htmlWords(cumulativeString + string + "</td><td>") {
                        html.append(contentsOf: words)
                    }
                } else {
                    if let words = stringNode.htmlWords(cumulativeString + "</td><td>") {
                        html.append(contentsOf: words)
                    }
                }
            } else {
                if let string = string {
                    if let words = stringNode.htmlWords("<td>" + string + "</td><td>") {
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
        guard let newString = newString else {
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
        
        var isEmpty = fragment.isEmpty
        
        while !isEmpty {
            if let stringNodes = stringNodes?.sorted(by: { $0.string < $1.string }) {
                for stringNode in stringNodes {
                    if let string = stringNode.string, string.endIndex >= fragment.endIndex, String(string[..<fragment.endIndex]) == fragment {
                        foundNode = stringNode
                        break
                    }
                }
            }
            
            if foundNode != nil {
                break
            }
            
            fragment = String(fragment[..<fragment.index(before: fragment.endIndex)])
            
            isEmpty = fragment.isEmpty
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
        guard let newString = newString, !newString.isEmpty else {
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
        
        var isEmpty = fragment.isEmpty
        
        while !isEmpty {
            if let string = string, string.endIndex >= fragment.endIndex, String(string[..<fragment.endIndex]) == fragment {
                break
            }
            
            fragment = String(fragment[..<fragment.index(before: fragment.endIndex)])
            
            isEmpty = fragment.isEmpty
        }
        
        if !isEmpty {
            if let stringSubSequence = string?[fragment.endIndex...] {
                let stringRemainder = String(stringSubSequence)
                
                if !stringRemainder.isEmpty {
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
            }
            
            let newStringRemainder = String(newString[fragment.endIndex...])
            
            if !newStringRemainder.isEmpty {
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
        guard let strings = strings else {
            return
        }
        
        for string in strings {
            addString(string)
        }
    }
}
