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
    public class override func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if let value = ["isLoading":["avPlayer.timeControlStatus","_isPlay"],"isPlay":["_isPlay"],"timeControlStatus":["avPlayer.timeControlStatus"]][key] {
            return Set(value)
        }
        return super.keyPathsForValuesAffectingValue(forKey: key)
    }
    public var playRate:Float = 1.0 {
        didSet {
            if self.isPlay {
                self.avPlayer.rate = playRate
            }
            
        }
    }
    var looper:AVPlayerLooper? {
        willSet {
            looper?.disableLooping()
        }
    }
    public var isLoop:Bool = false {
        didSet {
            if !isLoop {
                if self.isPlay,let url = self.playUrl {
                    let currentTime = self.currentItem?.currentTime() ?? CMTime(value: CMTimeValue(0), timescale: 600)
                    let item = AVPlayerItem(url: url)
                    self.avPlayer.replaceCurrentItem(with: item)
                    self.avPlayer.seek(to: currentTime)
                    self.avPlayer.play()
                }
                self.looper = nil
            }
            else {
                guard self.isPlay,let url = self.playUrl else {
                    return
                }
                
                let item = AVPlayerItem(url: url)
                self.looper = AVPlayerLooper(player: self.avPlayer, templateItem: item)
            }
            
            
        }
    }
    var timeObserver:Any?
    public var playUrl:URL? {
        didSet {
            self.close()
        }
    }
    var shouldResume:Bool = false
    @objc dynamic var _isPlay:Bool = false
    
    @objc dynamic public var timeControlStatus:AVPlayer.TimeControlStatus {
        get {
            return self.avPlayer.timeControlStatus
        }
    }
    public static let IPaAVPlayerItemFinished: NSNotification.Name = NSNotification.Name("IPaAVPlayerItemFinished")
    public static let IPaAVPlayerItemFailedToReachEnd: NSNotification.Name = NSNotification.Name("IPaAVPlayerItemFailedToReachEnd")
    public static let IPaAVPlayerItemStalled: NSNotification.Name = NSNotification.Name("IPaAVPlayerItemStalled")
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
            return self.avPlayer.volume
        }
        set {
            self.avPlayer.volume = newValue
        }
    }
    var currentItem:AVPlayerItem? {
        get {
            return self.avPlayer.currentItem
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
    
    @objc dynamic lazy var avPlayer:AVQueuePlayer =
    {
        let player = AVQueuePlayer()
        timeObserver =  player.addPeriodicTimeObserver(forInterval: CMTime(value: 300, timescale: 600), queue: .main, using: { (currentTime) in
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
         
        playStatusObserver = player.observe(\.status, options: [.new,.old], changeHandler: { (player, valueChanged) in
            
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
    
        //sometimes it won't play even the setting is correctly,this timer is trying to fix thisproblem
        playRateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
            guard player.status == .readyToPlay, player.rate == 0,player.timeControlStatus != .playing ,self.isPlay  else {
                return
            }
            self.play()
            
        })
        player.automaticallyWaitsToMinimizeStalling = false
        return player
    }()
    public var currentAVMetadataItem:[AVMetadataItem] {
        get {
            return self.currentItem?.asset.commonMetadata ?? [AVMetadataItem]()
        }
    }
    convenience public init(_ url:URL) {
        self.init()
        self.playUrl = url
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
        NotificationCenter.default.addObserver(self, selector: #selector(onPlayerItemStalled(_:)), name: .AVPlayerItemPlaybackStalled, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onAudioSessionInterruption(_:)) ,name: AVAudioSession.interruptionNotification, object: nil)
        
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    public func pause() {
        self._isPlay = false
        self.avPlayer.pause()
    }
    fileprivate func prepareUrlItem(_ url:URL) {
        let item = AVPlayerItem(url: url)
        if self.isLoop {
            
            self.looper = AVPlayerLooper(player: self.avPlayer, templateItem: item)
        }
        else {
            self.looper = nil
            self.avPlayer.replaceCurrentItem(with: item)
        }
    }
    public func play() {
        guard !self.isPlay ,let url = self.playUrl else {
            return
        }
        self._isPlay = true
        if self.avPlayer.currentItem == nil {
            //resume
            self.prepareUrlItem(url)
        }
        self.avPlayer.play()
        self.avPlayer.rate = self.playRate
       
    }
    public func close() {
        self.currentTime = 0
        self._isPlay = false
        self.avPlayer.removeAllItems()
        
    }
    public func seekToTime(_ time:Int,complete:((Bool) -> ())? = nil) {
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
    @objc func onPlayerItemStalled(_ notification:Notification) {
        guard let item = notification.object as? AVPlayerItem, item == self.currentItem else {
            return
        }
        self._isPlay = false
        NotificationCenter.default.post(name: IPaAVPlayer.IPaAVPlayerItemStalled, object: self)
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
