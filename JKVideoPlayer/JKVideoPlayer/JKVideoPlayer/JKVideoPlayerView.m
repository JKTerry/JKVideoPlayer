//
//  JKVideoPlayerView.m
//  JKCode
//
//  Created by mac on 15/8/17.
//  Copyright (c) 2015年 GoLuk. All rights reserved.
//

#import "JKVideoPlayerView.h"

static const float DefaultPlayableBufferLength = 2.0f;
static const float DefaultVolumeFadeDuration = 1.0f;
static const float TimeObserverInterval = 0.01f;

NSString *const kVideoPlayerErrorDomain = @"kVideoPlayerErrorDomain";

static void *VideoPlayer_PlayerItemStatusContext = &VideoPlayer_PlayerItemStatusContext;
static void *VideoPlayer_PlayerExternalPlaybackActiveContext = &VideoPlayer_PlayerExternalPlaybackActiveContext;
static void *VideoPlayer_PlayerRateChangedContext = &VideoPlayer_PlayerRateChangedContext;
static void *VideoPlayer_PlayerItemPlaybackLikelyToKeepUp = &VideoPlayer_PlayerItemPlaybackLikelyToKeepUp;
static void *VideoPlayer_PlayerItemPlaybackBufferEmpty = &VideoPlayer_PlayerItemPlaybackBufferEmpty;
static void *VideoPlayer_PlayerItemLoadedTimeRangesContext = &VideoPlayer_PlayerItemLoadedTimeRangesContext;

@interface JKVideoPlayerView()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, assign, getter=isScrubbing) BOOL scrubbing;
@property (nonatomic, assign, getter=isSeeking) BOOL seeking;
@property (nonatomic, assign) BOOL isAtEndTime;
@property (nonatomic, assign) BOOL shouldPlayAfterScrubbing;

@property (nonatomic, assign) float volumeFadeDuration;
@property (nonatomic, assign) float playableBufferLength;

@property (nonatomic, assign) BOOL isTimingUpdateEnabled;
@property (nonatomic, strong) id timeObserverToken;

@end

@implementation JKVideoPlayerView

#pragma mark - dealloc
- (void) dealloc
{
    [self resetPlayerItemIfNecessary];
    [self removePlayerObservers];
    [self removeTimeObserver];
    [self cancelFadeVolume];
    [self detachPlayer];
    NSLog(@"dealloc:%@",self);
}

#pragma mark - Public Methods
+ (Class) layerClass
{
    return [AVPlayerLayer class];
}

- (void) setVideoFillMode:(NSString *)fillMode
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)[self layer];
    playerLayer.videoGravity = fillMode;
}

- (void) setURL:(NSURL *)URL
{
    if (URL == nil)
    {
        return;
    }
    [self resetPlayerItemIfNecessary];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:URL];
    if (!playerItem)
    {
        [self reportUnableToCreatePlayerItem];
        return;
    }
    [self preparePlayerItem:playerItem];
}

- (void) setPlayerItem:(AVPlayerItem *)playerItem
{
    if (playerItem == nil)
    {
        return;
    }
    [self resetPlayerItemIfNecessary];
    [self preparePlayerItem:playerItem];
}

- (void) setAsset:(AVAsset *)asset
{
    if (asset == nil)
    {
        return;
    }
    [self resetPlayerItemIfNecessary];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset automaticallyLoadedAssetKeys:@[NSStringFromSelector(@selector(tracks))]];
    if (!playerItem)
    {
        [self reportUnableToCreatePlayerItem];
        return;
    }
    [self preparePlayerItem:playerItem];
}

#pragma mark - Accessor Overrides
- (void) setMuted:(BOOL)muted
{
    if (self.player)
    {
        self.player.muted = muted;
    }
}
- (BOOL) isMuted
{
    return self.player.isMuted;
}

#pragma mark - Playback
- (void) play
{
    if (self.player.currentItem == nil)
    {
        return;
    }
    self.playing = YES;
    if ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)
    {
        if ([self isAtEndTime])
        {
            [self restart];
        }
        else
        {
            [self.player play];
        }
    }
}

- (void) pause
{
    self.playing = NO;
    [self.player pause];
}

- (void) seekToTime:(float)time
{
    if (_seeking)
    {
        return;
    }
    if (self.player)
    {
        CMTime cmTime = CMTimeMakeWithSeconds(time, self.player.currentTime.timescale);
        if (CMTIME_IS_INVALID(cmTime) || self.player.currentItem.status != AVPlayerStatusReadyToPlay)
        {
            return;
        }
        
        _seeking = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.player seekToTime:cmTime completionHandler:^(BOOL finished) {
                _isAtEndTime = NO;
                _seeking = NO;
                if (finished)
                {
                    _scrubbing = NO;
                }
            }];
        });
    }
}

- (void) reset
{
    [self pause];
    [self resetPlayerItemIfNecessary];
}

#pragma mark - Airplay
- (void) enableAirplay
{
    if (self.player)
    {
        self.player.allowsExternalPlayback = YES;
    }
}

- (void) disableAirplay
{
    if (self.player)
    {
        self.player.allowsExternalPlayback = NO;
    }
}

- (BOOL) isAirplayEnabled
{
    return (self.player && self.player.allowsExternalPlayback);
}

#pragma mark - Scrubbing
- (void) startScrubbing
{
    self.scrubbing = YES;
    if (self.isPlaying)
    {
        self.shouldPlayAfterScrubbing = YES;
        [self pause];
    }
}

- (void) scrub:(float)time
{
    if (self.scrubbing == NO)
    {
        [self startScrubbing];
    }
    [self.player.currentItem cancelPendingSeeks];
    [self seekToTime:time];
}

- (void) stopScrubbing
{
    if (self.shouldPlayAfterScrubbing)
    {
        [self play];
        self.shouldPlayAfterScrubbing = NO;
    }
    self.scrubbing = NO;
}

#pragma mark - Time Updates
- (void) enableTimeUpdates
{
    self.isTimingUpdateEnabled = YES;
    [self addTimeObserver];
}

- (void) disableTimeUpdates
{
    self.isTimingUpdateEnabled = NO;
    [self removeTimeObserver];
}

#pragma mark - Volume
- (void) setVolume:(float)volume
{
    [self cancelFadeVolume];
    self.player.volume = volume;
}

- (void) cancelFadeVolume
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeInVolume) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutVolume) object:nil];
}

- (void) fadeInVolume
{
    if (self.player == nil)
    {
        return;
    }
    [self cancelFadeVolume];
    if (self.player.volume >= 1.0f - 0.01f)
    {
        self.player.volume = 1.0f;
    }
    else
    {
        self.player.volume += 1.0f / 10.0f;
        [self performSelector:@selector(fadeInVolume) withObject:nil afterDelay:self.volumeFadeDuration/10.0f];
    }
}

- (void) fadeOutVolume
{
    if (self.player == nil)
    {
        return;
    }
    
    [self cancelFadeVolume];
    if (self.player.volume <= 0.01f)
    {
        self.player.volume = 0.0f;
    }
    else
    {
        self.player.volume -= 1.0f/10.0f;
        [self performSelector:@selector(fadeOutVolume) withObject:nil afterDelay:self.volumeFadeDuration/10.0f];
    }
}

#pragma mark - Setup
- (void) setupPlayer
{
    self.player = [AVPlayer playerWithPlayerItem:nil];
    self.player.muted = NO;
    self.player.allowsExternalPlayback = YES;
}

- (void) setupAudioSession
{
    NSError *categoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                                          error:&categoryError];
    if (!success)
    {
        NSLog(@"Error settting audio session category:%@",categoryError);
    }
    NSError *activeError = nil;
    success = [[AVAudioSession sharedInstance] setActive:YES error:&activeError];
    if (!success)
    {
        NSLog(@"Error setting audio session active:%@",activeError);
    }
}

#pragma mark - Private Methods
- (void) reportUnableToCreatePlayerItem
{
    if ([self.delegate respondsToSelector:@selector(videoPlayerView:didFailWithError:)])
    {
        NSError *error = [NSError errorWithDomain:kVideoPlayerErrorDomain
                                             code:0 userInfo:@{NSLocalizedDescriptionKey:@"Unable to create AVPlayerItem."}];
        [self.delegate videoPlayerView:self didFailWithError:error];
    }
}

- (void) resetPlayerItemIfNecessary
{
    if (self.player.currentItem)
    {
        [self removePlayerItemObservers:self.player.currentItem];
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
    _volumeFadeDuration = DefaultVolumeFadeDuration;
    _playableBufferLength = DefaultPlayableBufferLength;
    
    _playing = NO;
    _isAtEndTime = NO;
    _scrubbing = NO;
}

- (void) preparePlayerItem:(AVPlayerItem *)playerItem
{
    [self addPlayerItemObservers:playerItem];
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
}

- (void) restart
{
    [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        _isAtEndTime = NO;
        if (self.isPlaying)
        {
            [self play];
        }
    }];
}

/* 这里计算播放结束的方式正确？ */
- (BOOL) isAtEndTime
{
    if (self.player && self.player.currentItem)
    {
        if (_isAtEndTime)
        {
            return _isAtEndTime;
        }
        
        float currentTime = 0.0f;
        if (CMTIME_IS_INVALID(self.player.currentTime) == NO)
        {
            currentTime = CMTimeGetSeconds(self.player.currentTime);
        }
        
        float videoDuration = 0.0f;
        if (CMTIME_IS_INVALID(self.player.currentItem.duration) == NO)
        {
            videoDuration = CMTimeGetSeconds(self.player.currentItem.duration);
        }
        if (currentTime > 0.0f && videoDuration > 0.0f)
        {
            if (fabs(currentTime-videoDuration) <= 0.01f)
            {
                return YES;
            }
        }
    }
    return NO;
}

- (float) calcLoadedDuration
{
    float loadedDuration = 0.0f;
    if (self.player && self.player.currentItem)
    {
        NSArray *loadedTimeRanges = self.player.currentItem.loadedTimeRanges;
        if (loadedTimeRanges && [loadedTimeRanges count])
        {
            CMTimeRange timeRange = [[loadedTimeRanges firstObject] CMTimeRangeValue];
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationseconds = CMTimeGetSeconds(timeRange.duration);
            
            loadedDuration = startSeconds + durationseconds;
        }
    }
    
    return loadedDuration;
}

#pragma mark - Player Observers
- (void) addPlayerObservers
{
    [self.player addObserver:self
                  forKeyPath:NSStringFromSelector(@selector(isExternalPlaybackActive))
                     options:NSKeyValueObservingOptionNew
                     context:VideoPlayer_PlayerExternalPlaybackActiveContext];
    [self.player addObserver:self
                  forKeyPath:NSStringFromSelector(@selector(rate))
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:VideoPlayer_PlayerRateChangedContext];
}

- (void) removePlayerObservers
{
    @try
    {
        [self.player removeObserver:self
                         forKeyPath:NSStringFromSelector(@selector(isExternalPlaybackActive))
                            context:VideoPlayer_PlayerExternalPlaybackActiveContext];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer:%@",exception);
    }
    @finally
    {
        
    }
    
    @try
    {
        [self.player removeObserver:self
                         forKeyPath:NSStringFromSelector(@selector(rate))
                            context:VideoPlayer_PlayerRateChangedContext];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception removing observer:%@",exception);
    }
    @finally {
        
    }
}

#pragma mark - PlayerItem Observers
- (void) addPlayerItemObservers:(AVPlayerItem *)playerItem
{
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(status))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                    context:VideoPlayer_PlayerItemStatusContext];
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(isPlaybackLikelyToKeepUp))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:VideoPlayer_PlayerItemPlaybackLikelyToKeepUp];
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(isPlaybackBufferEmpty))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:VideoPlayer_PlayerItemPlaybackBufferEmpty];
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(loadedTimeRanges))
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:VideoPlayer_PlayerItemLoadedTimeRangesContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidPlayToEndTime:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
}

- (void) removePlayerItemObservers:(AVPlayerItem *)playerItem
{
    [playerItem cancelPendingSeeks];
    @try {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(status))
                           context:VideoPlayer_PlayerItemStatusContext];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception removing observer:%@",exception);
    }
    @finally {
        
    }
    
    @try
    {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(isPlaybackLikelyToKeepUp))
                           context:VideoPlayer_PlayerItemPlaybackLikelyToKeepUp];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }
    
    @try
    {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(isPlaybackBufferEmpty))
                           context:VideoPlayer_PlayerItemPlaybackBufferEmpty];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }
    
    @try
    {
        [playerItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(loadedTimeRanges))
                           context:VideoPlayer_PlayerItemLoadedTimeRangesContext];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
}

#pragma mark - Time Observer
- (void) addTimeObserver
{
    if (self.timeObserverToken || self.player == nil)
    {
        return;
    }
    
    __weak typeof (self) weakSelf = self;
    self.timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(TimeObserverInterval, NSEC_PER_SEC)
                                                                       queue:dispatch_get_main_queue()
                                                                  usingBlock:^(CMTime time) {
                                                                      __strong typeof (self) strongSelf = weakSelf;
                                                                      if (!strongSelf)
                                                                      {
                                                                          return;
                                                                      }
                                                                      if ([strongSelf.delegate respondsToSelector:@selector(videoPlayerView:timeDidChange:)])
                                                                      {
                                                                          [strongSelf.delegate videoPlayerView:strongSelf timeDidChange:time];
                                                                      }
                                                                  }];
}

- (void) removeTimeObserver
{
    if (self.timeObserverToken == nil)
    {
        return;
    }
    if (self.player)
    {
        [self.player removeTimeObserver:self.timeObserverToken];
    }
    self.timeObserverToken = nil;
}

#pragma mark - Observer Response
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == VideoPlayer_PlayerRateChangedContext)
    {
        if (self.isScrubbing == NO && self.isPlaying && self.player.rate == 0.0f)
        {
            //TODO: Show loading indicator
        }
    }
    else if (context == VideoPlayer_PlayerItemStatusContext)
    {
        AVPlayerStatus newStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        AVPlayerStatus oldStatus = [[change objectForKey:NSKeyValueChangeOldKey] integerValue];
        if (newStatus != oldStatus)
        {
            switch (newStatus)
            {
                case AVPlayerStatusUnknown:
                {
                    NSLog(@"Video playerStatus Unknown");
                    break;
                }
                case AVPlayerStatusReadyToPlay:
                {
                    if ([self.delegate respondsToSelector:@selector(videoPlayerViewIsReadyToPlayVideo:)])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate videoPlayerViewIsReadyToPlayVideo:self];
                        });
                    }
                    if (self.isPlaying)
                    {
                        [self play];
                    }
                    break;
                }
                case AVPlayerStatusFailed:
                {
                    NSLog(@"Video player Status Failed: player item error = %@",self.player.currentItem.error);
                    NSLog(@"Video player Status Failed: player error = %@",self.player.error);
                    [self reset];
                    if ([self.delegate respondsToSelector:@selector(videoPlayerView:didFailWithError:)])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (self.player.error)
                            {
                                [self.delegate videoPlayerView:self didFailWithError:self.player.error];
                            }
                            else if (self.player.currentItem.error)
                            {
                                [self.delegate videoPlayerView:self didFailWithError:self.player.currentItem.error];
                            }
                            else
                            {
                                NSError *error = [NSError errorWithDomain:kVideoPlayerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"unknown player error, status == AVPlayerItemStatusFailed"}];
                                [self.delegate videoPlayerView:self didFailWithError:error];
                            }
                        });
                    }
                    break;
                }
                    
                default:
                    break;
            }
        }
    }
    else if (context == VideoPlayer_PlayerItemPlaybackBufferEmpty)
    {
        if (self.player.currentItem.playbackBufferEmpty)
        {
            if (self.isPlaying)
            {
                //TODO : show Loading indicator
            }
        }
    }
    else if (context == VideoPlayer_PlayerItemPlaybackLikelyToKeepUp)
    {
        if (self.player.currentItem.playbackLikelyToKeepUp)
        {
            //TODO : hide loading indicator
            
            if (self.isScrubbing == NO && self.isPlaying && self.player.rate == 0.0f)
            {
                [self play];
            }
        }
    }
    else if (context == VideoPlayer_PlayerItemLoadedTimeRangesContext)
    {
        float loadedDuration = [self calcLoadedDuration];
        if (self.isScrubbing == NO && self.isPlaying && self.player.rate == 0.0f)
        {
            if (loadedDuration >= CMTimeGetSeconds(self.player.currentTime) + self.playableBufferLength)
            {
                self.playableBufferLength *= 2;
                if (self.playableBufferLength > 64)
                {
                    self.playableBufferLength = 64;
                }
                [self play];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(videoPlayerView:loadedTimeRangeDidChange:)])
        {
            [self.delegate videoPlayerView:self loadedTimeRangeDidChange:loadedDuration];
        }
    }
    else if (context == VideoPlayer_PlayerExternalPlaybackActiveContext)
    {
        
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - init
- (instancetype) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _volumeFadeDuration = DefaultVolumeFadeDuration;
    _playableBufferLength = DefaultPlayableBufferLength;
    [self setupPlayer];
    [self addPlayerObservers];
    [self setupAudioSession];
    
    self.muted = NO;
    self.looping = YES;
    [self attachPlayer];
}

#pragma mark - Player
- (void) attachPlayer
{
    if (self.player)
    {
        [(AVPlayerLayer *)[self layer] setPlayer:self.player];
    }
}

- (void) detachPlayer
{
    if (self.player)
    {
        [(AVPlayerLayer *)[self layer] setPlayer:nil];
    }
}

#pragma mark - AVPlayerItemDidPlayToEndTimeNotification

- (void) playerItemDidPlayToEndTime:(NSNotification *)notification
{
    if (notification.object != self.player.currentItem)
    {
        return;
    }
    if (self.isLooping)
    {
        [self restart];
    }
    else
    {
        _isAtEndTime = YES;
        self.playing = NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(videoPlayerViewDidReachEnd:)])
    {
        [self.delegate videoPlayerViewDidReachEnd:self];
    }
}

@end
