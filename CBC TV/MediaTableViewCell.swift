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
        DispatchQueue.main.async {
            self.title.attributedText = nil
            self.detail.attributedText = nil
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
        detail.isHidden = state
        
        icons.isHidden = state
    }
    
    func setupText()
    {
        clear()

        let titleString = NSMutableAttributedString()
        
        if let searchHit = mediaItem?.searchHit(searchText).formattedDate, searchHit, let formattedDate = mediaItem?.formattedDate {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = formattedDate.lowercased().range(of: searchText!.lowercased()) {
                before = formattedDate.substring(to: range.lowerBound)
                string = formattedDate.substring(with: range)
                after = formattedDate.substring(from: range.upperBound)
                
                if let before = before {
                    titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                }
                if let string = string {
                    titleString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
                }
                if let after = after {
                    titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                }
            }
        } else {
            titleString.append(NSAttributedString(string:mediaItem!.formattedDate!, attributes: Constants.Fonts.Attributes.normal))
        }
        
        if !titleString.string.isEmpty {
            titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
        }
        titleString.append(NSAttributedString(string: mediaItem!.service!, attributes: Constants.Fonts.Attributes.normal))
        
        if let searchHit = mediaItem?.searchHit(searchText).speaker, searchHit, let speaker = mediaItem?.speaker {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = speaker.lowercased().range(of: searchText!.lowercased()) {
                before = speaker.substring(to: range.lowerBound)
                string = speaker.substring(with: range)
                after = speaker.substring(from: range.upperBound)
                
                if !titleString.string.isEmpty {
                    titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
                }
                
                if let before = before {
                    titleString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                }
                if let string = string {
                    titleString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
                }
                if let after = after {
                    titleString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                }
            }
        } else {
            if !titleString.string.isEmpty {
                titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
            }
            titleString.append(NSAttributedString(string:mediaItem!.speaker!, attributes: Constants.Fonts.Attributes.normal))
        }
        
        DispatchQueue.main.async {
            //                print(titleString.string)
            self.title.attributedText = titleString // NSAttributedString(string: "\(mediaItem!.formattedDate!) \(mediaItem!.service!) \(mediaItem!.speaker!)", attributes: normal)
        }
        
        let detailString = NSMutableAttributedString()
        
        var title:String?
        
        if (searchText == nil) && (mediaItem?.title?.range(of: " (Part ") != nil) {
            // This causes searching for "(Part " to present a blank title.
            let first = mediaItem!.title!.substring(to: (mediaItem!.title!.range(of: " (Part")?.upperBound)!)
            let second = mediaItem!.title!.substring(from: (mediaItem!.title!.range(of: " (Part ")?.upperBound)!)
            title = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
        } else {
            title = mediaItem?.title
        }
        
        if let searchHit = mediaItem?.searchHit(searchText).title, searchHit {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = title?.lowercased().range(of: searchText!.lowercased()) {
                before = title?.substring(to: range.lowerBound)
                string = title?.substring(with: range)
                after = title?.substring(from: range.upperBound)
                
                if let before = before {
                    detailString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.bold))
                }
                if let string = string {
                    detailString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.boldHighlighted))
                }
                if let after = after {
                    detailString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.bold))
                }
            }
        } else {
            if let title = title {
                detailString.append(NSAttributedString(string: title,   attributes: Constants.Fonts.Attributes.bold))
            }
        }
        
        if let searchHit = mediaItem?.searchHit(searchText).scriptureReference, searchHit, let scriptureReference = mediaItem?.scriptureReference {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = scriptureReference.lowercased().range(of: searchText!.lowercased()) {
                before = scriptureReference.substring(to: range.lowerBound)
                string = scriptureReference.substring(with: range)
                after = scriptureReference.substring(from: range.upperBound)
                
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                if let before = before {
                    detailString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                }
                if let string = string {
                    detailString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
                }
                if let after = after {
                    detailString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                }
            }
        } else {
            if let scriptureReference = mediaItem?.scriptureReference {
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                detailString.append(NSAttributedString(string: scriptureReference,   attributes: Constants.Fonts.Attributes.normal))
            }
        }
        
        if mediaItem!.searchHit(searchText).className {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = mediaItem?.className?.lowercased().range(of: searchText!.lowercased()) {
                before = mediaItem?.className?.substring(to: range.lowerBound)
                string = mediaItem?.className?.substring(with: range)
                after = mediaItem?.className?.substring(from: range.upperBound)
                
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                if let before = before {
                    detailString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                }
                if let string = string {
                    detailString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
                }
                if let after = after {
                    detailString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                }
            }
        } else {
            if let className = mediaItem?.className {
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                detailString.append(NSAttributedString(string: className, attributes: Constants.Fonts.Attributes.normal))
            }
        }
        
        if mediaItem!.searchHit(searchText).eventName {
            var string:String?
            var before:String?
            var after:String?
            
            if let range = mediaItem?.eventName?.lowercased().range(of: searchText!.lowercased()) {
                before = mediaItem?.eventName?.substring(to: range.lowerBound)
                string = mediaItem?.eventName?.substring(with: range)
                after = mediaItem?.eventName?.substring(from: range.upperBound)
                
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                if let before = before {
                    detailString.append(NSAttributedString(string: before,   attributes: Constants.Fonts.Attributes.normal))
                }
                if let string = string {
                    detailString.append(NSAttributedString(string: string,   attributes: Constants.Fonts.Attributes.highlighted))
                }
                if let after = after {
                    detailString.append(NSAttributedString(string: after,   attributes: Constants.Fonts.Attributes.normal))
                }
            }
        } else {
            if let eventName = mediaItem?.eventName {
                if !detailString.string.isEmpty {
                    detailString.append(NSAttributedString(string: "\n"))
                }
                detailString.append(NSAttributedString(string: eventName, attributes: Constants.Fonts.Attributes.normal))
            }
        }
        
        DispatchQueue.main.async {
            //                print(detailString.string)
            self.detail.attributedText = detailString
        }
    }
    
    func updateUI()
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
        
        if (detail.text != nil) || (detail.attributedText != nil) {
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
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: oldValue)
                })
            }
            
            if (mediaItem != nil) {
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.addObserver(self, selector: #selector(MediaTableViewCell.updateUI), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                })
            }
            
            updateUI()
        }
    }
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var icons: UILabel!
    
    override func addSubview(_ view: UIView)
    {
        super.addSubview(view)
        
        let buttonFont = UIFont(name: Constants.FA.name, size: Constants.FA.ACTION_ICONS_FONT_SIZE)
        let confirmationClass: AnyClass = NSClassFromString("UITableViewCellDeleteConfirmationView")!
        
        // replace default font in swipe buttons
        let s = subviews.flatMap({$0}).filter { $0.isKind(of: confirmationClass) }
        
        for sub in s {
            for button in sub.subviews {
                if let b = button as? UIButton {
                    b.titleLabel?.font = buttonFont
                }
            }
        }
    }

    func setupIcons()
    {
        guard Thread.isMainThread else {
            userAlert(title: "Not Main Thread", message: "MediaTableViewCell:setupIcons")
            return
        }
        
        guard mediaItem != nil else {
            return
        }
        
        if (searchText != nil) {
            let attrString = NSMutableAttributedString()
            
            if (globals.mediaPlayer.mediaItem == mediaItem) {
                if let state = globals.mediaPlayer.state {
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
            
            if (mediaItem!.hasTags) {
                if (mediaItem?.tagsSet?.count > 1) {
                    if mediaItem!.searchHit(searchText).tags {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAGS, attributes: Constants.FA.Fonts.Attributes.icons))
                    }
                } else {
                    if mediaItem!.searchHit(searchText).tags {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: Constants.FA.Fonts.Attributes.highlightedIcons))
                    } else {
                        attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.TAG, attributes: Constants.FA.Fonts.Attributes.icons))
                    }
                }
            }

            if (mediaItem!.hasVideo) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.VIDEO, attributes: Constants.FA.Fonts.Attributes.icons))
            }
            
            if (mediaItem!.hasAudio) {
                attrString.append(NSAttributedString(string: Constants.SINGLE_SPACE + Constants.FA.AUDIO, attributes: Constants.FA.Fonts.Attributes.icons))
            }
            
            DispatchQueue.main.async {
                self.icons.attributedText = attrString
            }
        } else {
            var string = String()
            
            if (globals.mediaPlayer.mediaItem == mediaItem) {
                if let state = globals.mediaPlayer.state {
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
            
            if (mediaItem!.hasTags) {
                if (mediaItem?.tagsSet?.count > 1) {
                    string = string + Constants.SINGLE_SPACE + Constants.FA.TAGS
                } else {
                    string = string + Constants.SINGLE_SPACE + Constants.FA.TAG
                }
            }
            
            if (mediaItem!.hasVideo) {
                string = string + Constants.SINGLE_SPACE + Constants.FA.VIDEO
            }
            
            if (mediaItem!.hasAudio) {
                string = string + Constants.SINGLE_SPACE + Constants.FA.AUDIO
            }
            
            DispatchQueue.main.async {
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
