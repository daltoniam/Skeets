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
    ///return a data blob from memory. Do NOT do long blocking calls IO calls in this method, only intend for fast hash lookups.
    mutating func fromMemory(hash: String) -> NSData?
    
    ///return a data blob from disk. Your implementation must call success and failure closures, else a network request will not be sent.
    //It is recommend to background the IO opts and then run the success and failure closures on the main thread. This way large or slow IO calls don't block drawing
    mutating func fromDisk(hash: String,success:((NSData) -> Void), failure:((NSError) -> Void))
    
    //add an item to the cache
    mutating func add(hash: String, data: NSData)
    
    //remove all the items from memory. This can be used to relieve memory pressue.
    mutating func clearCache()
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
public struct ImageCache: CacheProtocol {
    
    //images keeps a mapping from url hashes to imageNodes, this way nodes can be found in constant time
    var nodeMap = Dictionary<String,ImageNode>()
    
    //keeps a track of the start point of the list
    var head: ImageNode?
    
    //keeps a track of the end point of the list
    var tail: ImageNode?
    
    init() {
        
    }
    
    ///checks the Dictionary for an image
    public mutating func fromMemory(hash: String) -> NSData? {
        let node = self.nodeMap[hash]
        if let n = node {
            addToFront(n)
            return n.data
        }
        return nil
    }
    
    ///return a image from disk
    public mutating func fromDisk(hash: String,success:((NSData) -> Void), failure:((NSError) -> Void)) {
        //file system calls...
    }
    
    //add an item to the cache
    public mutating func add(hash: String, data: NSData) {
        self.nodeMap.removeValueForKey(hash)
        let node = ImageNode(data,hash)
        self.nodeMap[hash] = node
        addToFront(node)
        //need to evict/prune here
    }
    
    ///clear the images in memory
    public mutating func clearCache() {
        head = nil
        tail = nil
        nodeMap.removeAll(keepCapacity: true)
    }
    //adds the node to the front of the list (it is the most recently used!)
    private mutating func addToFront(node: ImageNode) {
        
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