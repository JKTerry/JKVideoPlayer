//
//  JKVideoPlayerView.h
//  JKCode
//
//  Created by mac on 15/8/17.
//  Copyright (c) 2015年 GoLuk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVPlayer;
@class JKVideoPlayerView;

@protocol VideoPlayerViewDelegate <NSObject>

@optional
- (void) videoPlayerViewIsReadyToPlayVideo:(JKVideoPlayerView *)videoPlayerView;
- (void) videoPlayerViewDidReachEnd:(JKVideoPlayerView *)videoPlayerView;
- (void) videoPlayerView:(JKVideoPlayerView *)videoPlayerView timeDidChange:(CMTime)cmTime;
- (void) videoPlayerView:(JKVideoPlayerView *)videoPlayerView loadedTimeRangeDidChange:(float)duration;
- (void) videoPlayerView:(JKVideoPlayerView *)videoPlayerView didFailWithError:(NSError *)error;

@end

@interface JKVideoPlayerView : UIView

@property (nonatomic, weak) id<VideoPlayerViewDelegate> delegate;

@property (nonatomic, assign, getter=isPlaying) BOOL playing;
/* defaults is YES */
@property (nonatomic, assign, getter=isLooping) BOOL looping;
/* defaults is NO */
@property (nonatomic, assign, getter=isMuted) BOOL muted;

/* 设置填充模式
 * AVLayerVideoGravityResizeAspect,
 * AVLayerVideoGravityResizeAspectFill
 * AVLayerVideoGravityResize.
 * AVLayerVideoGravityResizeAspect is default.
 */
- (void) setVideoFillMode:(NSString *)fillMode;

- (void) setURL:(NSURL *)URL;
- (void) setPlayerItem:(AVPlayerItem *)playerItem;
- (void) setAsset:(AVAsset *)asset;

//Playback
- (void) play;
- (void) pause;
- (void) seekToTime:(float)time;
- (void) reset;

//AirPlay
- (void) enableAirplay;
- (void) disableAirplay;
- (BOOL) isAirplayEnabled;

//Time Updates
- (void) enableTimeUpdates;
- (void) disableTimeUpdates;

//Scrubbing
- (void) startScrubbing;
- (void) scrub:(float)time;
- (void) stopScrubbing;

//Volume
- (void) setVolume:(float)volume;
- (void) fadeInVolume;
- (void) fadeOutVolume;

@end
