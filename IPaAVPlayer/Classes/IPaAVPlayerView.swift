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
    override open class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    lazy var indicatorView:UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(indicator)
        indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        indicator.hidesWhenStopped = true
        indicator.isHidden = true
        return indicator
    }()
    open var avPlayer:IPaAVPlayer? {
        didSet {
            if let player = oldValue?.avPlayer {
                player.removeObserver(self, forKeyPath: "timeControlStatus")
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
                player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old,.new], context: nil)
                player.addPeriodicTimeObserver(forInterval: CMTime(value: 300, timescale: 600), queue: .main) { (currentTime) in
                    self.delegate?.onCurrentTimeUpdate(self, currentTime: currentTime.seconds)
                }
                finishObserver =  NotificationCenter.default.addObserver(forName: IPaAVPlayer.IPaAVPlayerItemFinished, object: avPlayer, queue: .main) { (notification) in
                    self.delegate?.onFinishPlay(self)
                }
            }
            
        }
    }
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        checkStatus()
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
