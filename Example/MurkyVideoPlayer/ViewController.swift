//
//  ViewController.swift
//  MurkyVideoPlayer
//
//  Created by Murmeko on 08/16/2021.
//  Copyright (c) 2021 Murmeko. All rights reserved.
//

import UIKit
import MurkyVideoPlayer

class ViewController: UIViewController {
    
    var playerPortraitConstraints: [NSLayoutConstraint]?
    var playerLandscapeConstraints: [NSLayoutConstraint]?
    
    var player: MVP?
    var width: CGFloat?
    var height: CGFloat?
    
    let playerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemPink
        return view
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { context in
            if UIApplication.shared.statusBarOrientation.isLandscape {
                NSLayoutConstraint.deactivate(self.playerPortraitConstraints!)
                NSLayoutConstraint.activate(self.playerLandscapeConstraints!)
                self.player?.setPlayerFrame(playerFrame: CGRect(x: 0, y: 0, width: self.height!, height: self.width!))
            } else {
                NSLayoutConstraint.deactivate(self.playerLandscapeConstraints!)
                NSLayoutConstraint.activate(self.playerPortraitConstraints!)
                self.player?.setPlayerFrame(playerFrame: CGRect(x: 0, y: 0, width: self.width!, height: (self.width!/16)*9))
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        height = view.frame.height
        width = view.frame.width
        view.addSubview(playerView)
        playerPortraitConstraints = [
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            playerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            playerView.heightAnchor.constraint(equalToConstant: ((view.frame.width / 16) * 9))
        ]
        playerLandscapeConstraints = [
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            playerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            playerView.heightAnchor.constraint(greaterThanOrEqualToConstant: view.frame.height)
        ]
        NSLayoutConstraint.activate(playerPortraitConstraints!)
        player = MVP()
        player?.setQualityNames(firstName: "FHD", secondName: "HD", thirdName: "SD", fourthName: "MP3")
        player?.setQualityURLs(firstURL: URL(string: "https://h265.donanimhaber.com/turknet_ropo_fhd.mp4"), secondURL: URL(string: "https://stream-720p.donanimhaber.com/turknet_ropo_hd.mp4"), thirdURL: URL(string: "https://stream-338p.donanimhaber.com/turknet_ropo.mp4"), fourthURL: URL(string: "https://stream-audio.donanimhaber.com/turknet_ropo.mp3"))
        player?.preferredQuality(quality: .firstQuality)
        player?.setPlayerFrame(playerFrame: CGRect(x: 0, y: 0, width: self.width!, height: (self.width!/16)*9))
        playerView.addSubview(player!)

        /*
         "Videos": [
                                     {
                                         "Value": "https://stream-720p.donanimhaber.com/turknet_ropo_hd.mp4",
                                         "Size": 0
                                     },
                                     {
                                         "Value": "https://stream-338p.donanimhaber.com/turknet_ropo.mp4",
                                         "Size": 0
                                     },
                                     {
                                         "Value": "https://stream-audio.donanimhaber.com/turknet_ropo.mp3",
                                         "Size": 33179
                                     },
                                     {
                                         "Value": "https://h265.donanimhaber.com/turknet_ropo.mp4",
                                         "Size": 56875
                                     },
                                     {
                                         "Value": "https://h265.donanimhaber.com/turknet_ropo_hd.mp4",
                                         "Size": 123163
                                     },
                                     {
                                         "Value": "https://h265.donanimhaber.com/turknet_ropo_fhd.mp4",
                                         "Size": 221498
                                     }
                                 ],
         */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
