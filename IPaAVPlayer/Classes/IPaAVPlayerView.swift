//
//  IPaAVPlayerView.swift
//  IPaAVPlayer
//
//  Created by IPa Chen on 2020/2/20.
//

import UIKit
import AVFoundation
public protocol IPaAVPlayerViewDelegate
{
    func onCurrentTimeUpdate(_ view:IPaAVPlayerView,currentTime:TimeInterval)
    func onTimeControlStatus(_ view:IPaAVPlayerView,status:AVPlayer.TimeControlStatus?)
    func onFinishPlay(_ view:IPaAVPlayerView)
}
open class IPaAVPlayerView: UIView {
    open var delegate:IPaAVPlayerViewDelegate?
    var timeObserver:Any?
    var finishObserver:NSObjectProtocol?
    var statusObservation:NSKeyValueObservation?
    override open class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    lazy var indicatorView:UIActivityIndicatorView = {
        var style:UIActivityIndicatorView.Style
        
        if #available(iOS 13.0, *) {
            style = .large
        } else {
            // Fallback on earlier versions
            style = .whiteLarge
        }
        
        let indicator = UIActivityIndicatorView(style: style)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(indicator)
        indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        indicator.hidesWhenStopped = true
        indicator.isHidden = true
        return indicator
    }()
    open var videoGravity:AVLayerVideoGravity {
        get {
            return self.playerLayer.videoGravity
        }
        set {
            self.playerLayer.videoGravity = newValue
        }
    }
    open var avPlayer:IPaAVPlayer? {
        didSet {
            if let player = oldValue?.avPlayer {
                if let statusObservation = statusObservation {
                    statusObservation.invalidate()
                    self.statusObservation = nil
                }
                if let timeObserver = timeObserver {
                    player.removeTimeObserver(timeObserver)
                }
                if let finishObserver = finishObserver {
                    NotificationCenter.default.removeObserver(finishObserver)
                    self.finishObserver = nil
                }
            }
            
            playerLayer.player = avPlayer?.avPlayer

            if let avPlayer = avPlayer ,let player = avPlayer.avPlayer {
                self.checkStatus()
                self.statusObservation = player.observe(\.timeControlStatus, options: [.old,.new]) { (player, changedValue) in
                    self.checkStatus()
                }
                
                player.addPeriodicTimeObserver(forInterval: CMTime(value: 300, timescale: 600), queue: .main) { (currentTime) in
                    self.delegate?.onCurrentTimeUpdate(self, currentTime: currentTime.seconds)
                }
                finishObserver =  NotificationCenter.default.addObserver(forName: IPaAVPlayer.IPaAVPlayerItemFinished, object: avPlayer, queue: .main) { (notification) in
                    self.delegate?.onFinishPlay(self)
                }
            }
            
        }
    }
    
    func checkStatus() {
        if let avPlayer = avPlayer {
            let status = avPlayer.timeControlStatus
            if status == .waitingToPlayAtSpecifiedRate {
                self.indicatorView.isHidden = false
                self.indicatorView.startAnimating()
            }
            else {
                self.indicatorView.isHidden = true
            }
            self.delegate?.onTimeControlStatus(self,status:avPlayer.timeControlStatus)
        }
        else {
            self.indicatorView.isHidden = false
            self.indicatorView.startAnimating()
        }
        
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
