//
//  JKVideoPlayerView.h
//  JKCode
//
//  Created by mac on 15/8/17.
//  Copyright (c) 2015年 GoLuk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, VideoFillMode)
{
    VideoFillModeResizeAspect,
    VideoFillModeResizeAspectFill,
    VideoFillModeResize
};

@class AVPlayer;
@class JKVideoPlayerView;

@protocol VideoPlayerViewDelegate <NSObject>

@optional
- (void) videoPlayerViewShouldShowLoadingIndicator:(JKVideoPlayerView *)videoPlayerView;
- (void) videoPlayerViewShouldHideLoadingIndicator:(JKVideoPlayerView *)videoPlayerView;
- (void) videoPlayerViewIsReadyToPlayVideo:(JKVideoPlayerView *)videoPlayerView;
- (void) videoPlayerViewDidReachEnd:(JKVideoPlayerView *)videoPlayerView;
- (void) videoPlayerView:(JKVideoPlayerView *)videoPlayerView timeDidChange:(CMTime)cmTime;
- (void) videoPlayerView:(JKVideoPlayerView *)videoPlayerView loadedTimeRangeDidChange:(float)duration;
- (void) videoPlayerView:(JKVideoPlayerView *)videoPlayerView didFailWithError:(NSError *)error;
- (void) videoPlayerViewNetworkNotBest:(JKVideoPlayerView *)videoPlayerView;

@end

@interface JKVideoPlayerView : UIView

@property (nonatomic, weak) id<VideoPlayerViewDelegate> delegate;

@property (nonatomic, assign, getter = isPlaying) BOOL playing;
/* defaults is YES */
@property (nonatomic, assign, getter = isLooping) BOOL looping;
/* defaults is NO */
@property (nonatomic, assign, getter = isMuted) BOOL muted;
/* 设置填充模式 */
@property (nonatomic, assign) VideoFillMode videoFillMode;
/* 设置视频资源地址 */
@property (nonatomic, assign) NSURL *videoURL;
@property (nonatomic, strong) AVPlayer *player;

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

//Scrubbing
- (void) startScrubbing;
- (void) scrub:(float)time;
- (void) stopScrubbing;

//Volume
- (void) setVolume:(float)volume;
- (void) fadeInVolume;
- (void) fadeOutVolume;

@end
