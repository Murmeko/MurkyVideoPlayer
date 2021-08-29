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
    
    var player: MVP?
    
    let playerView: UIView = {
        let view = UIView()
        return view
    }()
    
    func setupPlayer() {
        player = MVP.init(width: playerView.frame.width, height: playerView.frame.height)
        player?.setQualityNames(firstName: "FHD", secondName: "HD", thirdName: "SD", fourthName: "MP3")
        player?.setQualityURLs(firstURL: nil, secondURL: nil, thirdURL: nil, fourthURL: nil)
    }
    
    func updateFrame() {
        self.playerView.frame = view.frame
        self.playerView.topAnchor.constraint(equalTo: view.topAnchor,constant: view.safeAreaInsets.top).isActive = true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
