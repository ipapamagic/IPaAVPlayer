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
open class IPaAVPlayerView: IPaAVPlayerViewerView {
    
    
    open var delegate:IPaAVPlayerViewDelegate?
    
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
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    override func setAVPlayer(_ player: AVPlayer?) {
        guard let player = player else {
            self.indicatorView.isHidden = false
            self.indicatorView.startAnimating()
            playerLayer.player = nil
            return
        }

        playerLayer.player = player
    }
    
    override func updateAVPlayerStatus(_ player: AVPlayer, status: AVPlayer.TimeControlStatus) {
        if status == .waitingToPlayAtSpecifiedRate {
            self.indicatorView.isHidden = false
            self.indicatorView.startAnimating()
        }
        else {
            self.indicatorView.isHidden = true
        }
        self.delegate?.onTimeControlStatus(self,status:status)
    }
    
    override func updateAVPlayerCurrentTime(_ player: AVPlayer, currentTime: TimeInterval) {
        self.delegate?.onCurrentTimeUpdate(self, currentTime: currentTime)
    }
    
    override func avplayerIsFinished(_ player: AVPlayer) {
        self.delegate?.onFinishPlay(self)
    }
}

