//
//  SKImageView.swift
//  Skeets
//
//  Created by Austin Cherry on 8/17/15.
//  Copyright © 2015 vluxe. All rights reserved.
//

import Foundation
#if os(iOS)
    import UIKit
    public typealias ImageView = UIImageView
    private typealias Image = UIImage
#elseif os(OSX)
    import AppKit
    public typealias ImageView = NSImageView
    private typealias Image = NSImage
#endif

public class SKImageView : ImageView {
    let manager = ImageManager(cacheDirectory: "")
    public var imageURL: String? {
        didSet {
            if let url = imageURL {
             fetchImageURL(url)
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func fetchImageURL(imageURL: String) {
        ImageManager.fetch(imageURL,
            progress: { (status: Double) in
                print("updating some UI for this: \(status)") //useful if you have some kind of progress dialog as the image loads
            },success: { (data: NSData) in
                print("got an image!")
                self.image = Image(data: data) //set the image data
            }, failure: { (error: NSError) in
                print("failed to get an image: \(error)")
        })
    }
}