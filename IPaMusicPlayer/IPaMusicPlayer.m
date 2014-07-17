//
//  IPaMusicPlayer.m
//  IPaMusicPlayer
//
//  Created by IPaPa on 13/9/7.
//  Copyright 2013年 IPaPa. All rights reserved.
//

#import "IPaMusicPlayer.h"



@interface IPaMusicPlayer() <AVAudioSessionDelegate,AVAudioPlayerDelegate>
@property (nonatomic,readonly) AVPlayer *musicPlayer;
@property (nonatomic,assign) BOOL shouldResume;
@property (nonatomic,assign) BOOL isPlay;
@end
@implementation IPaMusicPlayer
{
    
}
+(IPaMusicPlayer*)defaultPlayer
{
    static IPaMusicPlayer *defaultIPaMusicPlayer = nil;
    if (defaultIPaMusicPlayer == nil) {
        defaultIPaMusicPlayer = [[IPaMusicPlayer alloc] init];
    }
    return defaultIPaMusicPlayer;
}
-(id)init
{
    self = [super init];
    self.shouldResume = NO;
    //initial AudioSession
    // Registers this class as the delegate of the audio session to listen for audio interruptions
    [[AVAudioSession sharedInstance] setDelegate: self];
    //Set the audio category of this app to playback.
    NSError *setCategoryError = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError];
    if (setCategoryError) {
        //RESPOND APPROPRIATELY
    }
    
    
    //Activate the audio session
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
    if (activationError) {
        //RESPOND APPROPRIATELY
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    return self;
}
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*-(void)setMusicPlayItems:(NSArray*)playerItems
 {
 [self.musicPlayer removeAllItems];
 self.musicPlayer = nil;
 self.musicPlayer = [AVQueuePlayer queuePlayerWithItems:playerItems];
 }*/
-(void)setMusicPlayItem:(AVPlayerItem*)playerItem
{
    if (_musicPlayer == nil)
    {
        _musicPlayer = [AVPlayer playerWithPlayerItem:playerItem];//[AVQueuePlayer playerWithPlayerItem:playerItem];
    }
    else {
        if (_musicPlayer.currentItem == playerItem) {
            [_musicPlayer seekToTime:CMTimeMake(0, 1)];
        }
        else {
            [_musicPlayer replaceCurrentItemWithPlayerItem:playerItem];
        }
        
        //        [self.musicPlayer insertItem:playerItem afterItem:nil];
        
    }
    
}
-(void)setMusicURL:(NSURL*)musicURL
{
    AVURLAsset *asset = [AVURLAsset assetWithURL:musicURL];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    [self setMusicPlayItem:item];
    
}

-(void)pause
{
    self.isPlay = NO;
    [_musicPlayer pause];
}
-(void)play
{
    self.isPlay = YES;
    [_musicPlayer play];
}


- (void)playerItemDidReachEnd:(NSNotification *)notification {
    //allow for state updates, UI changes
    //    NSLog(@"song over!");
    self.isPlay = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:IPAMUSICPLAYER_ITEM_FINISHED object:self userInfo:nil];
}

#pragma mark - Global

+(void)setMusicURL:(NSURL*)musicURL
{
    [[IPaMusicPlayer defaultPlayer] setMusicURL:musicURL];
}
+(void)setMusicPlayItem:(AVPlayerItem*)playerItem
{
    [[IPaMusicPlayer defaultPlayer] setMusicPlayItem:playerItem];
}
/*+(void)setMusicPlayItems:(NSArray*)playerItems
 {
 [[IPaMusicPlayer defaultPlayer] setMusicPlayItems:playerItems];
 }*/
+(void)pause
{
    [[IPaMusicPlayer defaultPlayer] pause];
}
+(void)play
{
    [[IPaMusicPlayer defaultPlayer] play];
}
+(double)currentMusicDuration
{
    AVPlayerItem *currentItem = [IPaMusicPlayer currentItem];
    return (currentItem == nil)?0:CMTimeGetSeconds(currentItem.asset.duration);
    
}
+(double)currentMusicProgress
{
    AVPlayerItem *currentItem = [IPaMusicPlayer currentItem];
    return (currentItem == nil)?0:CMTimeGetSeconds(currentItem.currentTime);
}
+(AVPlayerItem*)currentItem
{
    return [IPaMusicPlayer defaultPlayer].musicPlayer.currentItem;
}

+(BOOL)isPlaying
{
    return [IPaMusicPlayer defaultPlayer].isPlay;
}
+(void)seekToTime:(NSUInteger)time
{
    AVPlayer *player = [IPaMusicPlayer defaultPlayer].musicPlayer;
    [player seekToTime:CMTimeMake(time, 1)];
}
#pragma mark - AVAudioSessionDelegate

/* the interruption is over */
- (void)endInterruptionWithFlags:(NSUInteger)flags
{
    if (self.shouldResume) {
        
        [self play];
        self.shouldResume = NO;
    }
    
}


- (void)beginInterruption /* something has caused your audio session to be interrupted */
{
    if(self.isPlay) {
        [self pause];
        self.shouldResume = YES;
        
    }
}

@end
