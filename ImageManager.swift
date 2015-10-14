//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  ImageManager.swift
//
//  Created by Dalton Cherry on 9/24/14.
//  Copyright (c) 2014 Vluxe. All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////////////////////////

import Foundation

///This stores the blocks that come from the fetch method.
///This is used to ensure only one request goes out for multiple of the same url.
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

///This is the main class. It handles interaction with cache and ensuring only one request goes out for multiples of the same url
public class ImageManager : NSObject, NSURLSessionDownloadDelegate, NSURLSessionDelegate {
    ///The cache. This is anything that responses to the cache protocol. By default it uses the provided ImageCache.
    public var cache: CacheProtocol
    
    ///This is used so multiple request for the same url only sends one request
    private var pending = Dictionary<String,Array<BlockHolder>>()
    
    /**
    Initializes a new ImageManager
    
    - parameter cacheDirectory: is the directory on disk to save cached images to.
    */
    public init(cacheDirectory: String) {
        var dir = cacheDirectory
        if dir == "" {
            #if os(iOS)
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            dir = "\(paths[0])" //use default documents folder, not ideal but better than the cache not working
            #elseif os(OSX)
            let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
            if let name = NSBundle.mainBundle().bundleIdentifier {
                dir = "\(paths[0])/\(name)"
            }
            #endif
        }
        cache = ImageCache(dir)
    }
    
    ///convenience method so you don't have to call "ImageManager.sharedManager" everytime you want to fetch an image
    public class func fetch(url: String, progress:((Double) -> Void)!, success:((NSData) -> Void)!, failure:((NSError) -> Void)!) {
        ImageManager.sharedManager.fetch(url, progress: progress, success: success, failure: failure)
    }
    
    ///convenience method so you don't have to call "ImageManager.sharedManager" everytime you want to cancel an image
    public class func cancel(url: String) {
        ImageManager.sharedManager.cancel(url)
    }
    
    ///Image manager singleton to manage displaying/caching images.
    ///This is normally the primary vehicle for displaying your images.
    public class var sharedManager : ImageManager {
        
        struct Static {
            static let instance : ImageManager = ImageManager(cacheDirectory: "")
        }
        return Static.instance
    }
    
    /**
    Fetches the image from the nearest location avaliable.
    
    - parameter url: The url you would like to make a request to.
    - parameter method: The HTTP method/verb for the request.
    - parameter progress: The closure that is run when reporting download progress via HTTP.
    - parameter success: The closure that is run on a sucessful image retrieval.
    - parameter failure: The closure that is run on a failed HTTP Request.
    
    */
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
                    
                    self.fetchFromNetwork(url, progress: { (status: Double) in
                        dispatch_async(dispatch_get_main_queue(), {
                            self.doProgress(hash, status: status)
                        })
                        }, completionHandler: { () in
                            if let err = response.error {
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.doFailure(hash, error: err)
                                })
                            } else {
                                self.cache.add(hash, url: response.responseObject! as! NSURL)
                                dispatch_async(dispatch_get_main_queue(), {
                                    if let d = self.cache.fromMemory(hash) {
                                        self.doSuccess(hash, data: d)
                                    }
                                })
                            }
                        })
            })
        } else if var array = self.pending[hash] {
            array.append(BlockHolder(progress: progress, success: success, failure: failure))
            self.pending[hash] = array
        }
    }
    
    ///cancel the request, by simply removing the closures
    public func cancel(url: String) {
        let hash = self.hash(url)
        self.pending.removeValueForKey(hash)
    }
    
    ///run all the success closures
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
    
    ///run all the failure closures
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
    
    ///run all the progress closures
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
    
    ///Hashes the url so it can be saved to disk.
    private func hash(u: String) -> String {
        var url = u
        let len = url.characters.count-1
        if url[advance(url.startIndex,len)] == "/" {
            url = url[url.startIndex..<advance(url.startIndex,len)]
        }
        var hash: UInt32 = 0
        for (index, codeUnit) in enumerate(url.utf8) {
            hash += (UInt32(codeUnit) * UInt32(index))
            hash ^= (hash >> 6)
        }
        
        hash += (hash << 3)
        hash ^= (hash >> 11)
        hash += (hash << 15)
        
        return "\(hash)"
    }
    
    /**
    Creates a random string to use for the identifier of the background download/upload requests.
    
    :returns: Identifier String.
    */
    private func createBackgroundIdent() -> String {
        let letters = "abcdefghijklmnopqurstuvwxyz"
        var str = ""
        for var i = 0; i < 14; i++ {
            let start = Int(arc4random() % 14)
            str.append(letters[advance(letters.startIndex,start)])
        }
        return "com.vluxe.skeets.request.\(str)"
    }
    
    /// fetches the image url from the network.
    private func fetchFromNetwork(url: String, progress:((Double) -> Void)!, completionHandler:(() -> Void)!) -> NSURLSessionDownloadTask? {
        let ident = createBackgroundIdent()
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(ident)
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.downloadTaskWithRequest(NSURLRequest(URL: NSURL(string: url)!))
        task.resume()
        return task
    }
    
    //MARK: Methods for background downloads
    
    // called when the background download of an image URL fails.
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
    }
    
    // The background download finished and reports the url the data was saved to.
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        //handleFinish(session, task: downloadTask, response: location)
    }

    
    // Will report progress of background download
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        //handleProgress(session, totalBytesExpected: totalBytesExpectedToWrite, currentBytes:totalBytesWritten)
    }
}
