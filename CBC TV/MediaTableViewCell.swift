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
            Globals.shared.userAlert(title: "Not Main Thread", message: "MediaTableViewCell:hideUI")
            return
        }
        
        isHiddenUI(true)
    }
    
    func isHiddenUI(_ state:Bool)
    {
        guard Thread.isMainThread else {
            Globals.shared.userAlert(title: "Not Main Thread", message: "MediaTableViewCell:isHiddenUI")
            return
        }
        
        title.isHidden = state
        
        icons.isHidden = state
    }
    
    func setupText()
    {
        clear()

        let titleString = NSMutableAttributedString()
        
        if let formattedDate = mediaItem?.formattedDate?.highlighted(searchText) {
            titleString.append(formattedDate)
        }
        
        if !titleString.string.isEmpty {
            titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
        }
        if let service = mediaItem?.service {
            titleString.append(NSAttributedString(string: service, attributes: Constants.Fonts.Attributes.body))
        }

        if let speaker = mediaItem?.speaker?.highlighted(searchText) {
            if !titleString.string.isEmpty {
                titleString.append(NSAttributedString(string: Constants.SINGLE_SPACE))
            }
            titleString.append(speaker)
        }
        
        var title:String?
        
        title = mediaItem?.title

        if searchText != nil {
            // This causes searching for "(Part " to present a blank title.
            // We do it to avoid text line wrapping between Part and the number.
            if  let rangeBefore = mediaItem?.title?.range(of: " (Part"),
                let rangeAfter = mediaItem?.title?.range(of: " (Part "),
                let string = mediaItem?.title {
                let first = String(string[..<rangeBefore.upperBound])
                let second = String(string[rangeAfter.upperBound...])
                title = first + Constants.UNBREAKABLE_SPACE + second // replace the space with an unbreakable one
            }
        }
        
        if let title = title?.highlighted(searchText) {
            if !titleString.string.isEmpty {
                titleString.append(NSAttributedString(string: "\n"))
            }
            
            titleString.append(title)
        }
        
        if let scriptureReference = mediaItem?.scriptureReference?.highlighted(searchText) {
            if !titleString.string.isEmpty {
                titleString.append(NSAttributedString(string: "\n"))
            }
            
            titleString.append(scriptureReference)
        }
        
        if let className = mediaItem?.className?.highlighted(searchText) {
            if !titleString.string.isEmpty {
                titleString.append(NSAttributedString(string: "\n"))
            }
            
            titleString.append(className)
        }
        
        if let eventName = mediaItem?.eventName?.highlighted(searchText) {
            if !titleString.string.isEmpty {
                titleString.append(NSAttributedString(string: "\n"))
            }
            
            titleString.append(eventName)
        }
                
        Thread.onMainThread { () -> (Void) in
            self.title.attributedText = titleString
        }
    }
    
    @objc func updateUI()
    {
        guard Thread.isMainThread else {
            Globals.shared.userAlert(title: "Not Main Thread", message: "MediaTableViewCell:updateUI")
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
    
    func setupIcons()
    {
        guard Thread.isMainThread else {
            Globals.shared.userAlert(title: "Not Main Thread", message: "MediaTableViewCell:setupIcons")
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
