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

private class BlockHolder {
    var progress:((Double) -> Void)?
    var success:((NSData) -> Void)?
    var failure:((NSError) -> Void)?
    init(progress: ((Double) -> Void)?, success: ((NSData) -> Void)?, failure: ((NSError) -> Void)?) {
        self.progress = progress
        self.success = success
        self.failure = failure
    }
}
public class ImageManager {
    public var cache: CacheProtocol!
    private var pending = Dictionary<String,Array<BlockHolder>>()
    
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
        //The pending Dictionary makes sure we don't run multiple request for the same image
        //so we check that to make sure we aren't already requesting that image
        if self.pending[hash] == nil {
            var holder = Array<BlockHolder>()
            holder.append(BlockHolder(progress: progress, success: success, failure: failure))
            self.pending[hash] = holder
            //next check from disk asynchronously
            cache.fromDisk(hash, success: { (d: NSData) in
                self.doSuccess(hash, data: d)
                }, failure: { (Void) in
                    //lastly fetch from the network asynchronously
                    let task = HTTPTask()
                    task.download(url, parameters: nil, progress: { (status: Double) in
                        self.doProgress(hash, status: status)
                        }, success: { (response: HTTPResponse) in
                            self.cache.add(hash, url: response.responseObject! as NSURL)
                            self.doSuccess(hash, data: self.cache.fromMemory(hash)!)
                        }, failure: { (error: NSError) in
                            self.doFailure(hash, error: error)
                    })
            })
        } else if var array = self.pending[hash] {
            array.append(BlockHolder(progress: progress, success: success, failure: failure))
            self.pending[hash] = array
        }
    }
    
    //run all the success methods
    private func doSuccess(hash: String, data: NSData) {
        let holder = self.pending[hash]
        if let array = holder {
            for blocks in array {
                if let s = blocks.success {
                    s(data)
                }
            }
            self.pending.removeValueForKey(hash)
        }
    }
    
    //run all the failure methods
    private func doFailure(hash: String, error: NSError) {
        let holder = self.pending[hash]
        if let array = holder {
            for blocks in array {
                if let f = blocks.failure {
                    f(error)
                }
            }
            self.pending.removeValueForKey(hash)
        }
    }
    
    //run all the success methods
    private func doProgress(hash: String, status: Double) {
        let holder = self.pending[hash]
        if let array = holder {
            for blocks in array {
                if let p = blocks.progress {
                    p(status)
                }
            }
        }
    }
    
    //not staying public, just for testing.
    private func hash(url: String) -> String {
        var hash = url
        let len = countElements(url)-1
        if hash[advance(hash.startIndex,len)] == "/" {
            hash = hash[hash.startIndex..<advance(hash.startIndex,len)]
        }
        //hmmm, thinking about this...
        //not sure if I want to do the bridging and do CC_MD5
        //or do a simpler hashing algorithm and just hand roll it.
        //CC_MD5(hash, len, result)
        let data = hash.dataUsingEncoding(NSUTF8StringEncoding)
        let hashedUrl = data?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(0))
        return hashedUrl!
    }
    //Image manager singleton to manage displaying/caching images
    public class var sharedManager : ImageManager {
        
    struct Static {
        static let instance : ImageManager = ImageManager(cacheDirectory: "")
        }
        return Static.instance
    }
}
