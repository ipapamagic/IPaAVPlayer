//
//  ViewController.swift
//  IPaMusicPlayer
//
//  Created by ipapamagic@gmail.com on 01/03/2019.
//  Copyright (c) 2019 ipapamagic@gmail.com. All rights reserved.
//

import UIKit
import IPaAVPlayer
class ViewController: UIViewController {
    var videoView:IPaAVPlayerView {
        return self.view as! IPaAVPlayerView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let player = IPaAVPlayer()
        let url = Bundle.main.url(forResource: "v", withExtension: "mp4")
        player.playUrl = url!
        player.isLoop = true
        self.videoView.avPlayer = player
        player.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func onTap(_ sender: Any) {
        self.videoView.avPlayer?.isLoop = !(self.videoView.avPlayer?.isLoop ?? false)
    }
    
}

