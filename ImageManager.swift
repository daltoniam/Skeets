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

//this should go away at some point. Just a work around for poor swift substring support
//http://openradar.appspot.com/radar?id=6373877630369792
extension String {
    
    subscript (idx: Int) -> String
        {
        get
        {
            return self.substringWithRange(
                Range( start: advance( self.startIndex, idx),
                    end: advance( self.startIndex, idx + 1 )  )
            )
        }
    }
    
    subscript (r: Range<Int>) -> String
        {
        get
        {
            return self.substringWithRange(
                Range( start: advance( self.startIndex, r.startIndex),
                    end: advance( self.startIndex, r.endIndex + 1 ))              )
        }
    }
    
    func substringFrom(start: Int, to: Int) -> String
    {
        return (((self as NSString).substringFromIndex(start)) as NSString).substringToIndex(to - start + 1)
    }
}

public class ImageManager {
    public var cache: CacheProtocol!
    
    public init(cacheDirectory: String) {
        cache = ImageCache(cacheDirectory)
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
        if hash[len] == "/" {
            hash = hash[0..<len]
        }
        //hmmm, thinking about this...
        //not sure if I want to do the bridging and do CC_MD5
        //or do a simpler hashing algorithm and just hand roll it.
        //CC_MD5(hash, len, result)
        return hash
    }
    //Image manager singleton to manage displaying/caching images
    public class var sharedManager : ImageManager {
        
    struct Static {
        static let instance : ImageManager = ImageManager(cacheDirectory: "")
        }
        return Static.instance
    }
}
