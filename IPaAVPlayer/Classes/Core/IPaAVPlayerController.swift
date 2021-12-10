//
//  IPaAVPlayerController.swift
//  IPaAVPlayer
//
//  Created by IPa Chen on 2021/11/23.
//

import UIKit
import AVFoundation
private var statusHandle: UInt8 = 0
private var avplayerHandle: UInt8 = 0
public protocol IPaAVPlayerController:NSObject {
    var avPlayer:IPaAVPlayer? {set get}
}
open class IPaAVPlayerViewerView:UIView,IPaAVPlayerController {
    @objc dynamic public var avPlayer:IPaAVPlayer? {
        didSet {
            if let oldValue = oldValue {
                if let statusObservation = statusObservation {
                    statusObservation.invalidate()
                    self.statusObservation = nil
                }
                if let timeObserver = timeObserver {
                    oldValue.avPlayer.removeTimeObserver(timeObserver)
                }
                if let finishObserver = finishObserver {
                    NotificationCenter.default.removeObserver(finishObserver)
                    self.finishObserver = nil
                }
            }
            
            let player = avPlayer?.avPlayer
            
            self.setAVPlayer(player)
            
            if let avPlayer = avPlayer,let player = player {
                self.updateAVPlayerStatus(player, status: player.timeControlStatus)
                
                self.statusObservation = player.observe(\.timeControlStatus, options: [.old,.new],changeHandler:{ (player, changedValue) in
                    self.updateAVPlayerStatus(player, status: player.timeControlStatus)
                })
                self.timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 300, timescale: 600), queue: .main) { (currentTime) in
                    self.updateAVPlayerCurrentTime(player,currentTime:currentTime.seconds)
                    
                }
                self.finishObserver =  NotificationCenter.default.addObserver(forName: IPaAVPlayer.IPaAVPlayerItemFinished, object: avPlayer, queue: .main) { (notification) in
                    self.avplayerIsFinished(player)
                    
                }
            }
        }
    }
    var timeObserver:Any?
    var finishObserver:NSObjectProtocol?
    var statusObservation:NSKeyValueObservation?
    func setAVPlayer(_ player:AVPlayer?) {
        
    }
    func updateAVPlayerStatus(_ player:AVPlayer,status:AVPlayer.TimeControlStatus) {
        
    }
    func updateAVPlayerCurrentTime(_ player:AVPlayer,currentTime:TimeInterval)
    {
        
    }
    func avplayerIsFinished(_ player:AVPlayer) {
        
    }
}
