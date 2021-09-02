# MurkyVideoPlayer

[![CI Status](https://img.shields.io/travis/Murmeko/MurkyVideoPlayer.svg?style=flat)](https://travis-ci.org/Murmeko/MurkyVideoPlayer)
[![Version](https://img.shields.io/cocoapods/v/MurkyVideoPlayer.svg?style=flat)](https://cocoapods.org/pods/MurkyVideoPlayer)
[![License](https://img.shields.io/cocoapods/l/MurkyVideoPlayer.svg?style=flat)](https://cocoapods.org/pods/MurkyVideoPlayer)
[![Platform](https://img.shields.io/cocoapods/p/MurkyVideoPlayer.svg?style=flat)](https://cocoapods.org/pods/MurkyVideoPlayer)

<p float="left">
  <img src="https://media1.giphy.com/media/INBJVV3vcW8fxrAap0/giphy.gif?cid=790b7611c7706ae57b327762d2b2d6ea2f6275d79d5ad146&rid=giphy.gif" width="180" height="320"  />
  <img src="https://media4.giphy.com/media/BUilIIQ6YVeCTBeXun/giphy.gif?cid=790b7611f41783c25de58dc0eed1d70acf84b89dfa9258de&rid=giphy.gif" width="180" height="320"  />
</p>
<img src="https://media1.giphy.com/media/jc3fI2vcn9PshYa2vZ/giphy.gif?cid=790b761148434a59dfcbdbb48eae71a7d41418e0ce22bad9&rid=giphy.gif" width="366" height="212"  />

## How to use

```swift
// Import the library.
import MurkyVideoPlayer

class ViewController: UIViewController {
    
    let playerView: UIView = {
        let view = UIView()
        return view
    }()
    
    // Set up player
    var player: MVP?
    
    func setupPlayer() {
        player = MVP.init(width: playerView.frame.width, height: playerView.frame.height)
        player?.setQualityNames(firstName: <String?>, secondName: <String?>, thirdName: <String?>, fourthName: <String?>)
        player?.setQualityURLs(firstURL: <URL?>, secondURL: <URL?>, thirdURL: <URL?>, fourthURL: <URL?>)
        player?.setSliderColor(miniumTrackTintColor: <UIColor?>, thumbColor: <UIColor?>, maximumTrackTintColor: <UIColor?>)
        player?.preferredQuality(quality: <MVP.qualities>)
        // Note: Do not select a preferred quality if there is no URL
    } 
    
    // Update players frame when transitioned
    func updateFrame() {
        self.playerView.frame = view.frame
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            self.updateFrame()
            self.player?.deviceRotated()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(playerView)
        
        updateFrame()
        setupPlayer()
        
        playerView.addSubview(player!)
        
        player?.playerReady()
    }
}

```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

| Platform | Installation |
| --- | --- |
| iOS 13.0+ | [CocoaPods](#cocoapods) |

## Installation

MurkyVideoPlayer is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MurkyVideoPlayer'
:git => 'https://github.com/Murmeko/MurkyVideoPlayer.git'
```

## Author

Murmeko, yigiterdinc@gmail.com

## License

MurkyVideoPlayer is available under the MIT license. See the LICENSE file for more info.
