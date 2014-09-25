//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  ImageManager.swift
//
//  Created by Dalton Cherry on 9/24/14.
//  Copyright (c) 2014 Vluxe. All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////////////////////////

import Foundation

class ImageManager {
    var cache: CacheProtocol!
    
    init(cacheDirectory: String) {
        cache = ImageCache(cacheDirectory)
    }
    //fetch an image from the network
    func fetch(url: String, progress:((Double) -> Void)!, success:((NSData) -> Void)!, failure:((NSError) -> Void)!) {
        let hash = url //hash the URL here
        let data = cache.fromMemory(hash)
        if data != nil {
            success(data!)
            return
        }
        cache.fromDisk(hash, success: { (d: NSData) -> Void in
            success(d)
        }, failure: { (Void) -> Void in
            //send download swiftHTTP request
            //add the data to the cache
        })
    }
    
    //image manager singleton to manage displaying/caching images
    class var sharedManager : ImageManager {
        
    struct Static {
        static let instance : ImageManager = ImageManager(cacheDirectory: "")
        }
        return Static.instance
    }
}
