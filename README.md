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

Full article here: [Vluxe](http://vluxe.io/skeets.html)

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

//for OSX
//let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
//ImageManager.sharedManager.cache.diskDirectory = "\(paths[0])/\(NSBundle.mainBundle().bundleIdentifier!)/ImageCache"

ImageManager.sharedManager.cache.cleanDisk()

//fetch the image
ImageManager.fetch("http://vluxe.io/assets/images/logo.png",
    progress: { (status: Double) in
        println("updating some UI for this: \(status)") //useful if you have some kind of progress dialog as the image loads
    },success: { (data: NSData) in
        println("got an image!")
        // Do this on the main thread since we're async right now
        dispatch_async(dispatch_get_main_queue(), {
            imageView.image = UIImage(data: data) //set the image data
        })
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

### Cocoapods

### [CocoaPods](http://cocoapods.org/)
At this time, Cocoapods support for Swift frameworks is supported in a [pre-release](http://blog.cocoapods.org/Pod-Authors-Guide-to-CocoaPods-Frameworks/).

To use Skeets in your project add the following 'Podfile' to your project

    source 'https://github.com/CocoaPods/Specs.git'

    xcodeproj 'YourProjectName.xcodeproj'
    platform :ios, '8.0'

    pod 'Skeets', :git => "https://github.com/daltoniam/skeets.git", :tag => "0.9.1"

    target 'YourProjectNameTests' do
        pod 'Skeets', :git => "https://github.com/daltoniam/skeets.git", :tag => "0.9.1"
    end

Then run:

    pod install

#### Updating the Cocoapod
You can validate Skeets.podspec using:

    pod spec lint Skeets.podspec

This should be tested with a sample project before releasing it. This can be done by adding the following line to a ```Podfile```:

    pod 'Skeets', :git => 'https://github.com/username/skeets.git'

Then run:

    pod install

If all goes well you are ready to release. First, create a tag and push:

    git tag 'version'
    git push --tags

Once the tag is available you can send the library to the Specs repo. For this you'll have to follow the instructions in [Getting Setup with Trunk](http://guides.cocoapods.org/making/getting-setup-with-trunk.html).

    pod trunk push Skeets.podspec



### Carthage

Check out the [Carthage](https://github.com/Carthage/Carthage) docs on how to add a install. The `Skeets` framework is already setup with shared schemes.

[Carthage Install](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

### Rogue

First see the [installation docs](https://github.com/acmacalister/Rogue) for how to install Rogue.

To install Skeets run the command below in the directory you created the rogue file.

```
rogue add https://github.com/daltoniam/SwiftHTTP
rogue add https://github.com/daltoniam/Skeets
```

Next open the `libs` folder and add the `Skeets.xcodeproj` to your Xcode project. Once that is complete, in your "Build Phases" add the `Skeets.framework` to your "Link Binary with Libraries" phase. Make sure to add the `libs` folder to your `.gitignore` file.

### Other

Simply grab the framework (either via git submodule or another package manager).

Add the `Skeets.xcodeproj` to your Xcode project. Once that is complete, in your "Build Phases" add the `Skeets.framework` to your "Link Binary with Libraries" phase.

### Add Copy Frameworks Phase

If you are running this in an OSX app or on a physical iOS device you will need to make sure you add the `Skeets.framework` or `SkeetsOSX.framework` to be included in your app bundle. To do this, in Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar. In the tab bar at the top of that window, open the "Build Phases" panel. Expand the "Link Binary with Libraries" group, and add `Skeets.framework` or `SkeetsOSX.framework` depending on if you are building an iOS or OSX app. Click on the + button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add `Skeets.framework` or `SkeetsOSX.framework` respectively.

## TODOs

- [ ] Complete Docs
- [ ] Add Unit Tests

## License

Skeets is licensed under the Apache v2 License.

## Contact

### Dalton Cherry
* https://github.com/daltoniam
* http://twitter.com/daltoniam
* http://daltoniam.com


