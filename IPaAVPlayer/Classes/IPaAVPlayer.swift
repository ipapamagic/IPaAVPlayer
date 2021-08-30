//
//  IPaAVPlayer.swift
//  IPaAVPlayer
//
//  Created by IPa Chen on 2019/1/3.
//

import UIKit
import Combine
import AVFoundation
public class IPaAVPlayer: NSObject {
    public static let shared = IPaAVPlayer()
    public var playRate:Float = 1.0 {
        didSet {
            if self.isPlay {
                self.avPlayer?.rate = playRate
            }
            
        }
    }
    
    var timeObserver:Any?
    public class override func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if let value = ["isLoading":["_avPlayer.timeControlStatus","_isPlay"],"isPlay":["_isPlay"],"timeControlStatus":["_avPlayer.timeControlStatus"]][key] {
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
    public static let IPaAVPlayerItemFailedToReachEnd: NSNotification.Name = NSNotification.Name("IPaAVPlayerItemFailedToReachEnd")
    public static let IPaAVPlayerItemError: NSNotification.Name = NSNotification.Name("IPaAVPlayerItemError")
    @available(iOS 13.0, *)
    public static let itemFailedToReachEndPublisher = NotificationCenter.default.publisher(for: IPaAVPlayerItemFailedToReachEnd)
    @available(iOS 13.0, *)
    public static let itemFinishedPublisher = NotificationCenter.default.publisher(for: IPaAVPlayerItemFinished)
    @available(iOS 13.0, *)
    public static let itemErrorPublisher = NotificationCenter.default.publisher(for: IPaAVPlayerItemError)
    
    
    var playStatusObserver:NSKeyValueObservation?
    var playRateTimer:Timer?
    public var volumn:Float {
        get {
            return self.avPlayer?.volume ?? 0
        }
        set {
            self.avPlayer?.volume = newValue
        }
    }
    var currentItem:AVPlayerItem? {
        get {
            return self.avPlayer?.currentItem
        }
        set {
            
            guard let playerItem = newValue else {

                self.avPlayer?.replaceCurrentItem(with: nil)
                return
            }
            playerItem.preferredForwardBufferDuration = TimeInterval(1)
            
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
    @objc dynamic public var isLoading:Bool {
        get {
            return (self.timeControlStatus != .playing) && self.isPlay
            
        }
    }
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
                if let timeObserver = timeObserver {
                    _avPlayer?.removeTimeObserver(timeObserver)
                }
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
                
                if let playStatusObserver = playStatusObserver {
                    playStatusObserver.invalidate()
                }
                playStatusObserver = newValue.observe(\.status, options: [.new,.old], changeHandler: { (player, valueChanged) in
                    
                    if player.status == .readyToPlay,self.isPlay{
                        //add a delay for not playing bug
                        self.play()
                    }
                    else if player.status == .failed {
                        NotificationCenter.default.post(name: IPaAVPlayer.IPaAVPlayerItemError, object: self,userInfo: ["Error":player.error ?? NSError(domain: "com.IPaAVPlayer", code: -1000, userInfo: nil)])
                        self.pause()
                    }
                    else if player.status == .unknown {
                        NotificationCenter.default.post(name: IPaAVPlayer.IPaAVPlayerItemError, object: self,userInfo: ["Error":player.error ?? NSError(domain: "com.IPaAVPlayer", code: -1001, userInfo: [NSLocalizedDescriptionKey:"unknown error!"])])
                        self.pause()
                    }
                })
                if playRateTimer == nil {
                    //sometimes it won't play even the setting is correctly,this timer is trying to fix thisproblem
                    playRateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
                        guard let avPlayer = self.avPlayer, self.isPlay,avPlayer.status == .readyToPlay, avPlayer.rate == 0,avPlayer.timeControlStatus != .playing else {
                            return
                        }
//                        print("error:\(avPlayer.error) timeControlState:\(avPlayer.timeControlStatus.rawValue) status:\(avPlayer.status.rawValue)")
                        self.play()
                        
                    })
                }
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
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerItemFailedToReachEnd(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: nil)
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
    public func close() {
        self.currentTime = 0
        self._isPlay = false
        self.avPlayer = nil
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
    @objc func onPlayerItemFailedToReachEnd(_  notification:Notification) {
        guard let item = notification.object as? AVPlayerItem, item == self.currentItem else {
            return
        }
        self._isPlay = false
        NotificationCenter.default.post(name: IPaAVPlayer.IPaAVPlayerItemFailedToReachEnd, object: self)
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
    
}
