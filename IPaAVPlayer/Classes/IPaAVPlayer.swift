//
//  IPaAVPlayer.swift
//  IPaAVPlayer
//
//  Created by IPa Chen on 2019/1/3.
//

import UIKit
import AVFoundation
private var playerItemContext = 0
public class IPaAVPlayer: NSObject {
    public static let shared = IPaAVPlayer()
    public var playRate:Float = 1.0 {
        didSet {
            if self.isPlay {
                self.avPlayer?.rate = playRate
            }
            
        }
    }
    @objc dynamic public var playItemStatus:AVPlayerItem.Status = .unknown
    var timeObserver:Any?
    public class override func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if let value = ["isPlay":["_isPlay"],"timeControlStatus":["_avPlayer.timeControlStatus"]][key] {
            return Set(value)
        }
        return super.keyPathsForValuesAffectingValue(forKey: key)
    }
    var shouldResume:Bool = false
    @objc dynamic var _isPlay:Bool = false
    
    @objc dynamic public var timeControlStatus:AVPlayer.TimeControlStatus {
        get {
            return self.avPlayer?.timeControlStatus ?? AVPlayer.TimeControlStatus.paused
        }
    }
    public static let IPaAVPlayerItemFinished: NSNotification.Name = NSNotification.Name("IPaAVPlayerItemFinished")
    var currentItem:AVPlayerItem? {
        get {
            return self.avPlayer?.currentItem
        }
        set {
            self.playItemStatus = .unknown
            guard let playerItem = newValue else {
                if let playerItem = self.avPlayer?.currentItem {
                    playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
                }
                
                self.avPlayer?.replaceCurrentItem(with: nil)
                return
            }
            playerItem.preferredForwardBufferDuration = TimeInterval(1)
            playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new,.old], context: &playerItemContext)
            if let avPlayer = avPlayer {
                if avPlayer.currentItem == playerItem {
                    avPlayer.seek(to: CMTime(value: 0, timescale: 1))
                }
                else {
                    avPlayer.replaceCurrentItem(with: playerItem)
                }
            }
            else {
                avPlayer = AVPlayer(playerItem: playerItem)
            }
        }
    }
    public var playingUrl:URL? {
        get {
            return (self.currentItem?.asset as? AVURLAsset)?.url
        }
    }
    @objc dynamic public var currentTime:Double = 0
    @objc dynamic public var duration:Double = 0
    
    @objc dynamic public var isPlay:Bool {
        get {
            return _isPlay
        }
    }
    @objc dynamic fileprivate var _avPlayer:AVPlayer?
    var avPlayer:AVPlayer?
    {
        get {
            return _avPlayer
        }
        set {
            if let _avPlayer = _avPlayer {
                if let timeObserver = timeObserver {
                    _avPlayer.removeTimeObserver(timeObserver)
                }
            }
            if let newValue = newValue {
               timeObserver =  newValue.addPeriodicTimeObserver(forInterval: CMTime(value: 300, timescale: 600), queue: .main, using: { (currentTime) in
                    self.currentTime = currentTime.seconds
                
             
                    if let currentItem = self.currentItem {
                        var duration = CMTimeGetSeconds(currentItem.duration)
                        if duration.isNaN {
                            duration = 0
                        }
                        if duration != self.duration {
                            self.duration = duration
                        }
                    }
                
                })
            }
            newValue?.automaticallyWaitsToMinimizeStalling = false
           
            _avPlayer = newValue
       
        }
    }
    public var currentAVMetadataItem:[AVMetadataItem] {
        get {
            return self.currentItem?.asset.commonMetadata ?? [AVMetadataItem]()
        }
    }
    public override init() {
        super.init()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print(error)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerItemDidReachEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onAudioSessionInterruption(_:)) ,name: AVAudioSession.interruptionNotification, object: nil)
        
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
  
    
    public func setAVURL(_ url:URL) {
        let asset = AVURLAsset(url: url)
        self.currentItem = AVPlayerItem(asset: asset)
        
    }
    
    public func pause() {
        self._isPlay = false
        self.avPlayer?.pause()
    }
    public func play() {
        self._isPlay = true
        self.avPlayer?.play()
        self.avPlayer?.rate = self.playRate
    }
    
    public func seekToTime(_ time:Int,complete:((Bool) -> ())? = nil) {
        guard let avPlayer = avPlayer else {
            return
        }
        avPlayer.seek(to: CMTime(value: CMTimeValue(600 * time), timescale: 600), completionHandler: {
            success in
            if let complete = complete {
                complete(success)
            }
        })
        
        
    }
    @objc func onPlayerItemDidReachEnd(_ notification:Notification) {
        guard let item = notification.object as? AVPlayerItem, item == self.currentItem else {
            return
        }
        self._isPlay = false
        NotificationCenter.default.post(name: IPaAVPlayer.IPaAVPlayerItemFinished, object: self)
    }
    @objc func onAudioSessionInterruption(_ notification:Notification) {
        guard let interruptionType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType else {
            return
            
        }
        
        switch interruptionType {
            
        case .began:
            if self.isPlay {
                self.pause()
                self.shouldResume = true
            }
        case .ended:
            if self.shouldResume {
                self.play()
                
                self.shouldResume = false
            }
        @unknown default:
            break
        }
        
    }
    public override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {

        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }

        if keyPath == #keyPath(AVPlayerItem.status) {
            
            if let statusNumber = change?[.newKey] as? NSNumber {
                self.playItemStatus = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                self.playItemStatus = .unknown
            }
            
        }
    }
}
