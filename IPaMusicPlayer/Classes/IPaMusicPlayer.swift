//
//  IPaMusicPlayer.swift
//  IPaMusicPlayer
//
//  Created by IPa Chen on 2019/1/3.
//

import UIKit
import AVFoundation

public class IPaMusicPlayer: NSObject {
    public static let shared = IPaMusicPlayer()
    var shouldResume:Bool = false
    var _isPlay:Bool = false
    public var timeControlStatus:AVPlayer.TimeControlStatus? {
        get {
            return self.musicPlayer?.timeControlStatus
        }
    }
    public static let IPaMusicPlayerItemFinished: NSNotification.Name = NSNotification.Name("IPaMusicPlayerItemFinished")
    public static let IPaMusicPlayerTimeStatusChanged:NSNotification.Name = NSNotification.Name("IPaMusicPlayerTimeStatusChanged")
    
    var currentItem:AVPlayerItem? {
        get {
            return self.musicPlayer?.currentItem
            
        }
    }
    public var playingUrl:URL? {
        get {
            return (self.currentItem?.asset as? AVURLAsset)?.url
        }
    }
    public var musicDuration:Double {
        get {
            if let currentItem = self.currentItem {
                return CMTimeGetSeconds(currentItem.currentTime())
            }
            return 0
        }
    }
    
    public var isPlay:Bool {
        get {
            return _isPlay
        }
    }
    fileprivate var _musicPlayer:AVPlayer?
    var musicPlayer:AVPlayer?
    {
        get {
            return _musicPlayer
        }
        set {
            if let _musicPlayer = _musicPlayer {
                _musicPlayer.removeObserver(self, forKeyPath: "timeControlStatu")
            }
            if let newValue = newValue {
                newValue.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
            }
            _musicPlayer = newValue
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
    func setMusicPlayItem(_ playerItem:AVPlayerItem) {
        if let musicPlayer = musicPlayer {
            if musicPlayer.currentItem == playerItem {
                musicPlayer.seek(to: CMTime(value: 0, timescale: 1))
            }
            else {
                musicPlayer.replaceCurrentItem(with: playerItem)
            }
        }
        else {
            musicPlayer = AVPlayer(playerItem: playerItem)
        }
        
    }
    public func setMusicURL(_ musicURL:URL) {
        let asset = AVURLAsset(url: musicURL)
        let item = AVPlayerItem(asset: asset)
        self.setMusicPlayItem(item)
    }
    
    public func pause() {
        self._isPlay = false
        self.musicPlayer?.pause()
    }
    public func play() {
        self._isPlay = true
        self.musicPlayer?.play()
    }
    public func seekToTime(_ time:Int) {
        guard let musicPlayer = musicPlayer else {
            return
        }
        musicPlayer.seek(to: CMTime(value: CMTimeValue(time), timescale: 1))
    }
    @objc func onPlayerItemDidReachEnd(_ notification:Notification) {
        self._isPlay = false
        NotificationCenter.default.post(name: IPaMusicPlayer.IPaMusicPlayerItemFinished, object: self)
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
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
            let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            if newStatus != oldStatus {
                NotificationCenter.default.post(name: IPaMusicPlayer.IPaMusicPlayerTimeStatusChanged, object: nil)
            }
        }
    }
}
