//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  ImageManager.swift
//
//  Created by Dalton Cherry on 9/24/14.
//  Copyright (c) 2014 Vluxe. All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////////////////////////

import Foundation
import SwiftHTTP

public class ImageManager {
    public var cache: CacheProtocol!
    
    public init(cacheDirectory: String) {
        var dir = cacheDirectory
        if dir == "" {
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            dir = "\(paths[0])" //use default documents folder, not ideal but better than the cache not working
        }
        cache = ImageCache(dir)
    }
    //fetch an image from the network
    public func fetch(url: String, progress:((Double) -> Void)!, success:((NSData) -> Void)!, failure:((NSError) -> Void)!) {
        let hash = self.hash(url)
        //check from memory first
        let data = cache.fromMemory(hash)
        if data != nil {
            if let s = success {
                s(data!)
            }
            return
        }
        //next check from disk asynchronously
        cache.fromDisk(hash, success: { (d: NSData) in
            if let s = success {
                s(d)
            }
        }, failure: { (Void) in
            //lastly fetch from the network asynchronously
            let task = HTTPTask()
            task.download(url, parameters: nil, progress: { (status: Double) in
                if let p = progress {
                    p(status)
                }
                }, success: { (response: HTTPResponse) in
                    self.cache.add(hash, url: response.responseObject! as NSURL)
                    if let s = success {
                        s(self.cache.fromMemory(hash)!)
                    }
                }, failure: { (error: NSError) in
                    if let f = failure {
                        f(error)
                    }
            })
        })
    }
    //not staying public, just for testing.
    public func hash(url: String) -> String {
        var hash = url
        let len = countElements(url)-1
        if hash[advance(hash.startIndex,len)] == "/" {
            hash = hash[hash.startIndex..<advance(hash.startIndex,len)]
        }
        //hmmm, thinking about this...
        //not sure if I want to do the bridging and do CC_MD5
        //or do a simpler hashing algorithm and just hand roll it.
        //CC_MD5(hash, len, result)
        return "\(hash.hash)"
    }
    //Image manager singleton to manage displaying/caching images
    public class var sharedManager : ImageManager {
        
    struct Static {
        static let instance : ImageManager = ImageManager(cacheDirectory: "")
        }
        return Static.instance
    }
}
