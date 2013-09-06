//
//  IPaMusicPlayer.m
//  IPaMusicPlayer
//
//  Created by IPaPa on 13/9/7.
//  Copyright 2013年 IPaPa. All rights reserved.
//

#import "IPaMusicPlayer.h"



@interface IPaMusicPlayer() <AVAudioSessionDelegate>
@property (nonatomic,readonly) AVPlayer *musicPlayer;
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
    [_musicPlayer pause];
}
-(void)play
{
    [_musicPlayer play];
}


- (void)playerItemDidReachEnd:(NSNotification *)notification {
    //allow for state updates, UI changes
    NSLog(@"song over!");
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
    return (currentItem == nil)?0:CMTimeGetSeconds(currentItem.duration);
    
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
    AVPlayer *player = [IPaMusicPlayer defaultPlayer].musicPlayer;
    
    return (player.currentItem == nil)? NO:(player.rate == 1);
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
    [self play];
}


- (void)beginInterruption; /* something has caused your audio session to be interrupted */
{
    [self pause];
}

@end
