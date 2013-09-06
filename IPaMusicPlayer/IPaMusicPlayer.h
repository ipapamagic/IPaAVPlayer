//
//  IPaMusicPlayer.h
//  IPaMusicPlayer
//
//  Created by IPaPa on 13/9/7.
//  Copyright 2013年 IPaPa. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#define IPAMUSICPLAYER_ITEM_FINISHED @"IPAMUSICPLAYER_ITEM_FINISHED"
@interface IPaMusicPlayer : NSObject {
    
}
+(IPaMusicPlayer*)defaultPlayer;
+(void)setMusicURL:(NSURL*)musicURL;
+(void)setMusicPlayItem:(AVPlayerItem*)playerItem;
//+(void)setMusicPlayItems:(NSArray*)playerItems;
+(void)pause;
+(void)play;
//+(void)clearQueue;
+(double)currentMusicDuration;
+(double)currentMusicProgress;
+(AVPlayerItem*)currentItem;
+(BOOL)isPlaying;
+(void)seekToTime:(NSUInteger)time;
@end
