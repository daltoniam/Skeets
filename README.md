Skeets
=====

![skeets](http://img1.wikia.nocookie.net/__cb20110522030251/marvel_dc/images/2/2b/Skeets_JLU_1.jpg)

Skeets is a networking image library that fetches, caches, and displays images via HTTP in Swift. It is built off [SwiftHTTP](https://github.com/daltoniam/SwiftHTTP).

## Features

- Multi level cache. In-memory and disk caching.
- Nonblocking IO. All HTTP and disk IO happen in the background, thanks to GCD.
- Simple one method to load a remote image.
- Robust, fast, and customizable caching.
- Simple concise codebase at just a few hundred LOC.
- handles redundant image requests, so only one request is sent for multiple queries

## Example

First thing is to import the framework. See the Installation instructions, on how to add the framework to your project.

```swift
import Skeets
```

Once imported, you can start requesting images.

```swift
//create a imageView
let imageView = UIImageView(frame: CGRectMake(0, 60, 200, 200))
self.view.addSubview(imageView)

//set the cache directory. Only have to do this once since `sharedManager` is a singleton
let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
ImageManager.sharedManager.cache.diskDirectory = "\(paths[0])/ImageCache"
ImageManager.sharedManager.cache.cleanDisk()

//fetch the image
ImageManager.sharedManager.fetch("http://vluxe.io/assets/images/logo.png",
    progress: { (status: Double) in
        println("updating some UI for this: \(status)") //useful if you have some kind of progress dialog as the image loads
    },success: { (data: NSData) in
        println("got an image!")
        imageView.image = UIImage(data: data) //set the image data
    }, failure: { (error: NSError) in
        println("failed to get an image: \(error)")
})
```

## Custom Cache

Skeets also supports customized caching and protocols. It is possible to implement your own custom cache by implementing the `CacheProtocol`. There is also a powerful default cache provided with a few customization options.

```swift
let c = ImageManager.sharedManager.cache as? ImageCache
if let cache = c {
    cache.diskAge = 60 * 60 //360 seconds or 1 hour (Default is 1 day).
    cache.imageCount = 10 //only 10 images will be stored in memory (Default is 50).
}
```

The cache can also be manually purged (e.g. memory warning is received).

```swift
ImageManager.sharedManager.cache.clearCache()
```

The disk can also be clean for possibly stale entries as well.

```swift
ImageManager.sharedManager.cache.cleanDisk()
```

## Requirements

Skeets requires at least iOS 8/OSX 10.10 or above.

Skeets depends on [SwiftHTTP](https://github.com/daltoniam/SwiftHTTP). Make sure to import that framework as well before using Skeets.

## Installation

Add the `skeets.xcodeproj` to your Xcode project. Once that is complete, in your "Build Phases" add the `skeets.framework` to your "Link Binary with Libraries" phase.

## TODOs

- [ ] Complete Docs
- [ ] Add Unit Tests
- [ ] Add Swallow Installation Docs

## License

Skeets is licensed under the Apache v2 License.

## Contact

### Dalton Cherry
* https://github.com/daltoniam
* http://twitter.com/daltoniam
* http://daltoniam.com


