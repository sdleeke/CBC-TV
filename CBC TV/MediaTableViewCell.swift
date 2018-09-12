//
//  MediaTableViewCell.swift
//  TWU
//
//  Created by Steve Leeke on 8/1/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

class MediaTableViewCell: UITableViewCell
{
    func clear()
    {
        Thread.onMainThread { () -> (Void) in
            self.title.attributedText = nil
        }
    }
    
    func hideUI()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:hideUI")
            return
        }
        
        isHiddenUI(true)
    }
    
    func isHiddenUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:isHiddenUI")
            return
        }
        
        title.isHidden = state
        
        icons.isHidden = state
    }
    
    func setupText()
    {
        clear()

        let titleString = NSMutableAttributedString()
        
        if let searchText = searchText, let searchHit = mediaItem?.searchHit(searchText).formattedDate, searchHit, let formattedDate = mediaItem?.formattedDate {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = formattedDate.lowercased().range(of: searchText.lowercased()) {
                before = String(formattedDate[..<range.lowerBound])
                string = String(formattedDate[range])
                after = String(formattedDate[range.upperBound...])
                
                if let before = before {
                    titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.body))
                }
                if let string = string {
                    titleString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.bodyHighlighted))
                }
                if let after = after {
                    titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.body))
                }
            }
        } else {
            if let formattedDate = mediaItem?.formattedDate {
                titleString.append(NSAttributedString(string:formattedDate, attributes: Constants.Fonts.Attributes.body))
            }
        }
        
        if !titleString.string.isEmpty {
            titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
        }
        if let service = mediaItem?.service {
            titleString.append(NSAttributedString(string: service, attributes: Constants.Fonts.Attributes.body))
        }

        if let searchText = searchText, let searchHit = mediaItem?.searchHit(searchText).speaker, searchHit, let speaker = mediaItem?.speaker {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = speaker.lowercased().range(of: searchText.lowercased()) {
                before = String(speaker[..<range.lowerBound])
                string = String(speaker[range])
                after = String(speaker[range.upperBound...])
                
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
                }
                
                if let before = before {
                    titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.body))
                }
                if let string = string {
                    titleString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.bodyHighlighted))
                }
                if let after = after {
                    titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.body))
                }
            }
        } else {
            if !titleString.string.isEmpty {
                titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
            }
            if let speaker = mediaItem?.speaker {
                titleString.append(NSAttributedString(string:speaker, attributes: Constants.Fonts.Attributes.body))
            }
        }
        
        var title:String?
        
        if searchText != nil {
            // This causes searching for "(Part " to present a blank title.
            if  let rangeBefore = mediaItem?.title?.range(of: " (Part"),
                let rangeAfter = mediaItem?.title?.range(of: " (Part "),
                let string = mediaItem?.title {
                let first = String(string[..<rangeBefore.upperBound])
                let second = String(string[rangeAfter.upperBound...])
                title = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
            }
        } else {
            title = mediaItem?.title
        }
        
        if let searchText = searchText, let searchHit = mediaItem?.searchHit(searchText).title, searchHit {
            var string:String?
            var before:String?
            var after:String?
            
            if let title = title, let range = title.lowercased().range(of: searchText.lowercased()) {
                before = String(title[..<range.lowerBound])
                string = String(title[range])
                after = String(title[range.upperBound...])
                
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: "\n"))
                }
                
                if let before = before {
                    titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.headline))
                }
                if let string = string {
                    titleString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.headlineHighlighted))
                }
                if let after = after {
                    titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.headline))
                }
            }
        } else {
            if let title = title {
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: "\n"))
                }
                
                titleString.append(NSAttributedString(string: title,   attributes: Constants.Fonts.Attributes.headline))
            }
        }
        
        if let searchHit = mediaItem?.searchHit(searchText).scriptureReference, searchHit, let scriptureReference = mediaItem?.scriptureReference {
            var string:String?
            var before:String?
            var after:String?
            
            if let searchText = searchText, let range = scriptureReference.lowercased().range(of: searchText.lowercased()) {
                before = String(scriptureReference[..<range.lowerBound])
                string = String(scriptureReference[range])
                after = String(scriptureReference[range.upperBound...])
                
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: "\n"))
                }
                
                if let before = before {
                    titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.body))
                }
                if let string = string {
                    titleString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.bodyHighlighted))
                }
                if let after = after {
                    titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.body))
                }
            }
        } else {
            if let scriptureReference = mediaItem?.scriptureReference {
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: "\n"))
                }
                
                titleString.append(NSAttributedString(string: scriptureReference,   attributes: Constants.Fonts.Attributes.body))
            }
        }
        
        if let searchText = searchText, let searchHit = mediaItem?.searchHit(searchText), searchHit.className {
            var string:String?
            var before:String?
            var after:String?
            
            if let className = mediaItem?.className, let range = className.lowercased().range(of: searchText.lowercased()) {
                before = String(className[..<range.lowerBound])
                string = String(className[range])
                after = String(className[range.upperBound...])
                
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: "\n"))
                }
                
                if let before = before {
                    titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.body))
                }
                if let string = string {
                    titleString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.bodyHighlighted))
                }
                if let after = after {
                    titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.body))
                }
            }
        } else {
            if let className = mediaItem?.className {
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: "\n"))
                }
                
                titleString.append(NSAttributedString(string: className, attributes: Constants.Fonts.Attributes.body))
            }
        }
        
        if let searchText = searchText, let searchHit = mediaItem?.searchHit(searchText), searchHit.eventName {
            var string:String?
            var before:String?
            var after:String?
            
            if let eventName = mediaItem?.eventName, let range = eventName.lowercased().range(of: searchText.lowercased()) {
                before = String(eventName[..<range.lowerBound])
                string = String(eventName[range])
                after = String(eventName[range.upperBound...])
                
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: "\n"))
                }
                
                if let before = before {
                    titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.body))
                }
                if let string = string {
                    titleString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.bodyHighlighted))
                }
                if let after = after {
                    titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.body))
                }
            }
        } else {
            if let eventName = mediaItem?.eventName {
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: "\n"))
                }
                
                titleString.append(NSAttributedString(string: eventName, attributes: Constants.Fonts.Attributes.body))
            }
        }
        
        Thread.onMainThread { () -> (Void) in
            self.title.attributedText = titleString
        }
    }
    
    @objc func updateUI()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:updateUI")
            return
        }
        
        guard (mediaItem != nil) else {
            isHiddenUI(true)
            print("No mediaItem for cell!")
            return
        }

        setupIcons()

        setupText()
        
        if (title.text != nil) || (title.attributedText != nil) {
            isHiddenUI(false)
        }
    }
    
    var searchText:String? {
        willSet {
            
        }
        didSet {
            updateUI()
        }
    }
    
    var mediaItem:MediaItem? {
        willSet {
            
        }
        didSet {
            if (oldValue != nil) {
                Thread.onMainThread { () -> (Void) in
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: oldValue)
                }
            }
            
            if (mediaItem != nil) {
                Thread.onMainThread { () -> (Void) in
                    NotificationCenter.default.addObserver(self, selector: #selector(self.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                }
            }
            
            updateUI()
        }
    }
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var icons: UILabel!
    
//    override func addSubview(_ view: UIView)
//    {
//        super.addSubview(view)
//        
//        guard let confirmationClass: AnyClass = NSClassFromString("UITableViewCellDeleteConfirmationView") else {
//            return
//        }
//        
//        let buttonFont = UIFont(name: Constants.FA.name, size: Constants.FA.ACTION_ICONS_FONT_SIZE)
//        
//        // replace default font in swipe buttons
//        let s = subviews.flatMap({$0}).filter { $0.isKind(of: confirmationClass) }
//        
//        for sub in s {
//            for button in sub.subviews {
//                if let b = button as? UIButton {
//                    b.titleLabel?.font = buttonFont
//                }
//            }
//        }
//    }

    func setupIcons()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:setupIcons")
            return
        }
        
        guard let mediaItem = mediaItem else {
            return
        }
        
        if (searchText != nil) {
            let attrString = NSMutableAttributedString()
            
            if (Globals.shared.mediaPlayer.mediaItem == mediaItem) {
                if let state = Globals.shared.mediaPlayer.state {
                    switch state {
                    case .paused:
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.PLAY, attributes: Constants.FA.Fonts.Attributes.icons))
                        break
                        
                    case .playing:
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.PLAYING, attributes: Constants.FA.Fonts.Attributes.icons))
                        break
                        
                    case .stopped:
                        break
                        
                    case .none:
                        break
                        
                    default:
                        break
                    }
                }
            }
            
            if (mediaItem.hasTags) {
                if (mediaItem.tagsSet?.count > 1) {
                    if mediaItem.searchHit(searchText).tags {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: Constants.FA.Fonts.Attributes.icons))
                    }
                } else {
                    if mediaItem.searchHit(searchText).tags {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: Constants.FA.Fonts.Attributes.icons))
                    }
                }
            }
            
            if mediaItem.hasSlides {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.SLIDES, attributes: Constants.FA.Fonts.Attributes.icons))
            }
            
            if (mediaItem.hasVideo) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.VIDEO, attributes: Constants.FA.Fonts.Attributes.icons))
            }
            
            if (mediaItem.hasAudio) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.AUDIO, attributes: Constants.FA.Fonts.Attributes.icons))
            }
            
            Thread.onMainThread { () -> (Void) in
                self.icons.attributedText = attrString
            }
        } else {
            var string = String()
            
            if (Globals.shared.mediaPlayer.mediaItem == mediaItem) {
                if let state = Globals.shared.mediaPlayer.state {
                    switch state {
                    case .paused:
                        string = string + Constants.SINGLE_SPACE + Constants.FA.PLAY
                        break
                        
                    case .playing:
                        string = string + Constants.SINGLE_SPACE + Constants.FA.PLAYING
                        break
                        
                    case .stopped:
                        break
                        
                    case .none:
                        break
                        
                    default:
                        break
                    }
                }
            }
            
            if (mediaItem.hasTags) {
                if (mediaItem.tagsSet?.count > 1) {
                    string = string + Constants.SINGLE_SPACE + Constants.FA.TAGS
                } else {
                    string = string + Constants.SINGLE_SPACE + Constants.FA.TAG
                }
            }
            
            if mediaItem.hasSlides {
                string = string + Constants.SINGLE_SPACE + Constants.FA.SLIDES
            }
            
            if (mediaItem.hasVideo) {
                string = string + Constants.SINGLE_SPACE + Constants.FA.VIDEO
            }
            
            if (mediaItem.hasAudio) {
                string = string + Constants.SINGLE_SPACE + Constants.FA.AUDIO
            }
            
            Thread.onMainThread { () -> (Void) in
                self.icons.text = string
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
