# MurkyVideoPlayer

[![Bitrise Build Status](https://app.bitrise.io/app/079ed0572add1f28/status.svg?token=zlOLIxvdLAGujKB-bndc1Q)](https://app.bitrise.io/app/079ed0572add1f28)
[![Travis Build Status](https://app.travis-ci.com/Murmeko/MurkyVideoPlayer.svg?branch=main)](https://app.travis-ci.com/Murmeko/MurkyVideoPlayer)
[![Maintainability](https://api.codeclimate.com/v1/badges/e9b0082a11c8fe51b3c9/maintainability)](https://codeclimate.com/github/Murmeko/MurkyVideoPlayer/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/e9b0082a11c8fe51b3c9/test_coverage)](https://codeclimate.com/github/Murmeko/MurkyVideoPlayer/test_coverage)
[![Version](https://img.shields.io/cocoapods/v/MurkyVideoPlayer.svg?style=flat)](https://cocoapods.org/pods/MurkyVideoPlayer)
[![License](https://img.shields.io/cocoapods/l/MurkyVideoPlayer.svg?style=flat)](https://cocoapods.org/pods/MurkyVideoPlayer)
[![Platform](https://img.shields.io/cocoapods/p/MurkyVideoPlayer.svg?style=flat)](https://cocoapods.org/pods/MurkyVideoPlayer)

MurkyVideoPlayer is an opensource video player library written in Swift.
<p float="left">
  <img src="https://media1.giphy.com/media/INBJVV3vcW8fxrAap0/giphy.gif?cid=790b7611c7706ae57b327762d2b2d6ea2f6275d79d5ad146&rid=giphy.gif" width="180" height="320"  />
  <img src="https://media4.giphy.com/media/BUilIIQ6YVeCTBeXun/giphy.gif?cid=790b7611f41783c25de58dc0eed1d70acf84b89dfa9258de&rid=giphy.gif" width="180" height="320"  />
  <img src="https://media1.giphy.com/media/jc3fI2vcn9PshYa2vZ/giphy.gif?cid=790b761148434a59dfcbdbb48eae71a7d41418e0ce22bad9&rid=giphy.gif" width="480" height="320"  />
</p>

## Requirements

| Platform | Installation |
| --- | --- |
| iOS 13.0+ | [CocoaPods](#cocoapods) |

## Installation

MurkyVideoPlayer is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MurkyVideoPlayer'
```

## How to use

### Import MurkyVideoPlayer

```swift

import MurkyVideoPlayer

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
```

### Set up MVP and PlayerView

```swift

import MurkyVideoPlayer

class ViewController: UIViewController {

let playerView: UIView = {
        let view = UIView()
        return view
    }()
    
    var player: MVP?
    
    func setupPlayer() {
        player = MVP.init(width: playerView.frame.width, height: playerView.frame.height)
        player?.setQualityNames(firstName: <String?>, secondName: <String?>, thirdName: <String?>, fourthName: <String?>)
        player?.setQualityURLs(firstURL: <URL?>, secondURL: <URL?>, thirdURL: <URL?>, fourthURL: <URL?>)
        player?.setSliderColor(miniumTrackTintColor: <UIColor?>, thumbColor: <UIColor?>, maximumTrackTintColor: <UIColor?>)
        player?.preferredQuality(quality: <MVP.qualities>)
        // Note: Do not select a preferred quality if there is no URL
    } 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(playerView)
        self.playerView.frame = view.frame
        
        setupPlayer()
        
        playerView.addSubview(player!)
        
        player?.playerReady()
    }
}

```
### Update players frame when transitioned

```swift
import MurkyVideoPlayer

class ViewController: UIViewController {
    
    let playerView: UIView = {
        let view = UIView()
        return view
    }()
    
    var player: MVP?
    
    func setupPlayer() {
        player = MVP.init(width: playerView.frame.width, height: playerView.frame.height)
        player?.setQualityNames(firstName: <String?>, secondName: <String?>, thirdName: <String?>, fourthName: <String?>)
        player?.setQualityURLs(firstURL: <URL?>, secondURL: <URL?>, thirdURL: <URL?>, fourthURL: <URL?>)
        player?.setSliderColor(miniumTrackTintColor: <UIColor?>, thumbColor: <UIColor?>, maximumTrackTintColor: <UIColor?>)
        player?.preferredQuality(quality: <MVP.qualities>)
        // Note: Do not select a preferred quality if there is no URL
    } 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(playerView)
        self.playerView.frame = view.frame
        
        setupPlayer()
        
        playerView.addSubview(player!)
        
        player?.playerReady()
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            self.player?.deviceRotated()
        })
    }
}

```

## License

MurkyVideoPlayer is available under the MIT license. See the LICENSE file for more info.
