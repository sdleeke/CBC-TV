//
//  FetchImage.swift
//  CBC
//
//  Created by Steve Leeke on 10/5/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class FetchImage : Fetch<UIImage>, Size
{
    deinit {
        debug(self)
    }
    
    var url : URL?
    
    init?(name:String? = nil, url:URL?)
    {
        guard let url = url else {
            return nil
        }
        
        super.init(name:name)
        
        fetch = { [weak self] () -> (UIImage?) in
            return self?.fetchIt()
        }
        
        store = { [weak self] (image:UIImage?) in
            self?.storeIt(image: image)
        }
        
        retrieve = { [weak self] in
            return self?.retrieveIt()
        }
        
        self.url = url
    }
    
    var fileSystemURL:URL?
    {
        get {
            return url?.fileSystemURL
        }
    }
    
    var exists:Bool
    {
        get {
            return fileSystemURL?.exists ?? false
        }
    }
    
    func fetchIt() -> UIImage?
    {
        return self.url?.image
    }
    
//    func block(_ block:((UIImage?)->()))
//    {
//        if let image = image {
//            block(image)
//        }
//    }

    func load(success:((UIImage)->())?, failure:(()->())?)
    {
        if let image = result {
            success?(image)
        } else {
            failure?()
        }
    }

    var imageName : String?
    {
        return url?.lastPathComponent
    }
    
    var image : UIImage?
    {
        get {
            return result
        }
    }
    
    internal var _fileSize : Int?
    var fileSize : Int?
    {
        get {
            guard let fileSize = _fileSize else {
                _fileSize = fileSystemURL?.fileSize
                return _fileSize
            }
            
            return fileSize
        }
        set {
            _fileSize = newValue
        }
    }
    
    func delete(block:Bool)
    {
        clear()
        fileSize = nil
        fileSystemURL?.delete(block:block)
    }
    
    func retrieveIt() -> UIImage?
    {
        return fileSystemURL?.data?.image
    }
    
    func storeIt(image:UIImage?)
    {
        guard let image = image else {
            return
        }
        
        guard let fileSystemURL = self.fileSystemURL else {
            return
        }
        
        guard !fileSystemURL.exists else {
            return
        }
        
        guard let data = image.jpegData(compressionQuality: 1.0), !data.isEmpty else {
            return
        }
        
        do {
            try data.write(to: fileSystemURL, options: [.atomic])
            print("Image \(fileSystemURL.lastPathComponent) saved to file system")
            fileSize = fileSystemURL.fileSize ?? 0
        } catch let error {
            NSLog(error.localizedDescription)
            print("Image \(fileSystemURL.lastPathComponent) not saved to file system")
        }
    }
}

class FetchCachedImage : FetchImage
{
    private static var cache : ThreadSafeDictionary<UIImage>! = {
        return ThreadSafeDictionary<UIImage>(name:"FetchImageCache")
    }()
    
    private static var queue : DispatchQueue = {
        return DispatchQueue(label: "FetchImageCacheQueue")
    }()
    
    override func fetchIt() -> UIImage?
    {
        return FetchCachedImage.queue.sync {
            if let image = self.cachedImage {
                return image
            }
            
            let image = super.fetchIt()
            
            return image
        }
    }
    
    override func retrieveIt() -> UIImage?
    {
        return FetchCachedImage.queue.sync {
            // Belt and susupenders since this is also in fetchIt() which means it would happen there not here.
            if let image = self.cachedImage {
                return image
            }
            
            return super.retrieveIt()
        }
    }
    
    override func storeIt(image: UIImage?)
    {
        FetchCachedImage.queue.sync {
            // The indication that it needs to be stored is that it isn't in the cache yet.
            guard self.cachedImage == nil else {
                return
            }
            
            super.storeIt(image: image)
            
            self.cachedImage = image
        }
    }
    
    func clearCache()
    {
        FetchCachedImage.cache.clear()
    }
    
    var cachedImage : UIImage?
    {
        get {
            return FetchCachedImage.cache[self.imageName]
        }
        set {
            FetchCachedImage.cache[self.imageName] = newValue
        }
    }
}

