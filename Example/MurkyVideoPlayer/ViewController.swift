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
    
    var launcher = MVP()
    
    @IBAction func doNotPressButton(_ sender: Any) {
        launcher.showVideoPlayer()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
