//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Cache.swift
//
//  Created by Dalton Cherry on 9/24/14.
//  Copyright (c) 2014 Vluxe. All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////////////////////////

import Foundation

//This protocol can be implemented for custom image caching.
public protocol CacheProtocol {
    
    //the directory to be used for saving images to disk
    var diskDirectory: String! { get set }
    
    ///return a data blob from memory. Do NOT do long blocking calls IO calls in this method, only intend for fast hash lookups.
    func fromMemory(hash: String) -> NSData?
    
    ///return a data blob from disk. Your implementation must call success and failure closures, else a network request will not be sent.
    //It is recommend to background the IO opts and then run the success and failure closures on the main thread. This way large or slow IO calls don't block drawing
    func fromDisk(hash: String,success:((NSData) -> Void), failure:((Void) -> Void))
    
    //add an item to the cache
    func add(hash: String, data: NSData)
    
    //add an item to the cache
    func add(hash: String, url: NSURL)
    
    //remove all the items from memory. This can be used to relieve memory pressue.
    func clearCache()
    
    //remove all the expired items from the disk. This can be used to relieve disk space constraints.
    //Recommend that you run this on a background thread.
    func cleanDisk()
}

//The default image cache implemention. This uses a combo of a Dictionary and custom LinkedList to cache. 
//This allows constant time lookups, inserts, deletes, and maintains a LRU so the eviction can happen easily and quickly

//our linked list to find the LRU(Least Recently Used) image to evict from the cache when the time comes
class ImageNode {
    let hash: String!
    var prev: ImageNode?
    var next: ImageNode?
    var data: NSData!
    
    init(_ data: NSData, _ hash: String) {
        self.data = data
        self.hash = hash
    }
}
extension ImageNode: Equatable {}

func ==(lhs: ImageNode, rhs: ImageNode) -> Bool {
    return lhs.hash == rhs.hash
}
//The default implementation of the CacheProtocol
public class ImageCache: CacheProtocol {
    
    //the amount of images to store in memory before pruning
    public var imageCount = 50
    
    //the length of time a image is saved to disk before it expires (int seconds).
    public var diskAge = 60 * 60 * 24 //24 hours
    
    //the directory to be used for saving images to disk
    public var diskDirectory: String!
    
    //images keeps a mapping from url hashes to imageNodes, this way nodes can be found in constant time
    var nodeMap = Dictionary<String,ImageNode>()
    
    //keeps a track of the start point of the list
    var head: ImageNode?
    
    //keeps a track of the end point of the list
    var tail: ImageNode?
    
    init(_ cacheDirectory: String) {
        self.diskDirectory = cacheDirectory
    }
    
    ///checks the Dictionary for an image
    public func fromMemory(hash: String) -> NSData? {
        let node = self.nodeMap[hash]
        if let n = node {
            addToFront(n)
            return n.data
        }
        return nil
    }
    
    ///return a image from disk
    public func fromDisk(hash: String,success:((NSData) -> Void), failure:((Void) -> Void)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), {
            let cachePath = "\(self.diskDirectory)/\(hash)"
            let expireDate = NSDate(timeIntervalSinceNow: NSTimeInterval(-self.diskAge))
            let fileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(cachePath) {
                let attrs = fileManager.attributesOfItemAtPath(cachePath, error: nil)
                let modifyDate = attrs?[NSFileModificationDate] as NSDate
                if modifyDate.laterDate(expireDate).isEqualToDate(expireDate) {
                    fileManager.removeItemAtPath(cachePath, error: nil)
                    failure()
                } else {
                    let data = fileManager.contentsAtPath(cachePath)
                    if let d = data {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.add(hash, data: d)
                            success(d)
                        })
                    }
                    return
                }
            }
            failure()
        })
    }
    
    //add an item from the disk to the cache. 
    //Moves the file from the temp directory into the cacheDirectory, then adds it to the memory cache
    public func add(hash: String, url: NSURL) {
        let cachePath = "\(self.diskDirectory)/\(hash)"
        let moveUrl = NSURL(fileURLWithPath: cachePath)
        let fileManager = NSFileManager.defaultManager()
        fileManager.removeItemAtURL(moveUrl, error: nil)
        fileManager.moveItemAtURL(url, toURL: moveUrl, error: nil)
        let data = fileManager.contentsAtPath(cachePath)
        if let d = data {
            add(hash, data: d)
        }
    }
    //add an item to the cache
    public func add(hash: String, data: NSData) {
        var node: ImageNode! = self.nodeMap[hash]
        if node != nil {
            node.data = data
        } else {
            node = ImageNode(data,hash)
            self.nodeMap[hash] = node
        }
        addToFront(node)
        if self.nodeMap.count > self.imageCount {
            prune()
        }
    }
    
    ///clear the images in memory
    public func clearCache() {
        head = nil
        tail = nil
        nodeMap.removeAll(keepCapacity: true)
    }
    public func cleanDisk() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), {
            let fileManager = NSFileManager.defaultManager()
            let diskUrl = NSURL(fileURLWithPath: self.diskDirectory, isDirectory: true)
            let expireDate = NSDate(timeIntervalSinceNow: NSTimeInterval(-self.diskAge))
            let resources = [NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey]
            
            let enumerator = fileManager.enumeratorAtURL(diskUrl, includingPropertiesForKeys: resources,
                options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil)
            let array = enumerator?.allObjects
            for file in array! {
                if let fileUrl = file as? NSURL {
                    let values = fileUrl.resourceValuesForKeys(resources, error: nil)!
                    if let num = values[NSURLIsDirectoryKey] as? NSNumber  {
                        if num.boolValue {
                            continue
                        }
                    }
                    if let modifyDate = values[NSURLContentModificationDateKey] as? NSDate  {
                        if modifyDate.laterDate(expireDate).isEqualToDate(expireDate) {
                            fileManager.removeItemAtURL(fileUrl, error: nil)
                        }
                    }
                }
            }
        })
    }
    //cleans the cache up by removing LRU
    private func prune() {
        if let t = tail {
            let prev = t.prev
            t.prev = nil
            prev?.next = nil
            self.nodeMap.removeValueForKey(t.hash)
            tail = prev
        }
    }
    //adds the node to the front of the list (it is the most recently used!)
    private func addToFront(node: ImageNode) {
        
        //if this node is the tail, reassign tail to the prev node of the tail
        if let t = tail {
            if t == node && t.prev != nil {
                tail = t.prev
            }
        }
        //if this node was already in the list, we need to update its connections
        if let next = node.next {
            next.prev = node.prev
        }
        if let prev = node.prev {
            prev.next = node.next
        }
        //now append it to the head
        if let h = head {
            node.next = h
            h.prev = node
        } else {
            tail = node
        }
        head = node
    }
}