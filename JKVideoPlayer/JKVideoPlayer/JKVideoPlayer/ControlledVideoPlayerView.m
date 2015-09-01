//
//  ControlledVideoPlayerView.m
//  JKVideoPlayer
//
//  Created by mac on 15/8/27.
//  Copyright (c) 2015年 uupye. All rights reserved.
//

#import "ControlledVideoPlayerView.h"
#import "JKVideoPlayerView.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#define SECOND_FRAMENT(s,a) [self convertTime:s append:a];

@interface ControlledVideoPlayerView()<VideoPlayerViewDelegate>
{
    
}
@property (nonnull,nonatomic,strong) JKVideoPlayerView *videoPlayerView;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIImageView *loadingImageView;
/* 底部控制器视图 */
@property (nonatomic, retain) BottomControllView *bottomControlView;
/* 顶部控制器视图 */
@property (nonatomic, retain) TopControlView *topControlView;
@property (nonatomic, retain) UIView *superView;
@property (nonatomic, retain) UIImageView *firstFrameImageView;

@property (nonatomic, copy) void(^successBlock)(void);
@property (nonatomic, copy) void(^failureBlock)(NSError *error);
@end

@implementation ControlledVideoPlayerView

#pragma mark - dealloc
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"dealloc:%@",self);
}
#pragma mark - 时间转换
- (NSString *)convertTime:(CGFloat)second append:(NSString *)append
{
    NSMutableString *str = [NSMutableString string];
    int m = second/60;
    if (m <= 9)
    {
        [str appendFormat:@"0%d",m];
    }
    else
        [str appendFormat:@"%d",m];
    
    int s = (int)second%60;
    if (s <= 9)
    {
        [str appendFormat:@":0%d",s];
    }
    else
        [str appendFormat:@":%d",s];
    
    if (append)
    {
        [str appendString:append];
    }
    
    return str;
}

#pragma mark - Public Methods
- (void) playWithUrl:(NSURL *)videoURL Success:(void(^)(void))successBlock Failure:(void(^)(NSError* error))failureBlock
{
    self.videoPlayerView.videoURL = videoURL;
    [self.videoPlayerView play];
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
}
-(void)setFirstFramePic:(UIImage*)img
{
    if (img)
    {
        [self.firstFrameImageView setImage:img];
    }
}
- (void) addToSuperView:(UIView*)superView
{
    /* 先移除之前所加的view */
    [self removeFromSuperview];
    if ([superView isKindOfClass:[UIWindow class]])
    {
        /* 当加到window上时，控制条出现 */
        self.bottomControlView.hidden = NO;
    }
    else
    {
        self.bottomControlView.hidden = YES;
        self.superView = superView;
    }
    [superView addSubview:self];
    [superView bringSubviewToFront:self];
    self.frame = superView.bounds;
    [self resizeAllSubViews];
}

- (void) resizeAllSubViews
{
    self.videoPlayerView.frame = self.bounds;
    if (self.bottomControlView.hidden == NO)
    {
        self.playBtn.frame = CGRectMake((self.frame.size.height-self.playBtn.frame.size.width)/2.0, (self.frame.size.width-self.playBtn.frame.size.height)/2.0, self.playBtn.frame.size.width, self.playBtn.frame.size.height);
        self.loadingImageView.frame = CGRectMake((self.frame.size.height-self.loadingImageView.frame.size.width)/2.0, (self.frame.size.width-self.loadingImageView.frame.size.height)/2.0, self.loadingImageView.frame.size.width, self.loadingImageView.frame.size.height);
    }
    else
    {
        self.playBtn.frame = CGRectMake((self.frame.size.width-self.playBtn.frame.size.width)/2.0, (self.frame.size.height-self.playBtn.frame.size.height)/2.0, self.playBtn.frame.size.width, self.playBtn.frame.size.height);
        self.loadingImageView.frame = CGRectMake((self.frame.size.width-self.loadingImageView.frame.size.width)/2.0, (self.frame.size.height-self.loadingImageView.frame.size.height)/2.0, self.loadingImageView.frame.size.width, self.loadingImageView.frame.size.height);
    }
    self.bottomControlView.frame = CGRectMake(0.0, self.frame.size.width-40.0, self.frame.size.height, 40.0);
    [self.bottomControlView setAllSubviewsFrame];
}

- (void) RemoveFromSuperView
{
    [self.videoPlayerView reset];
    [self removeFromSuperview];
}

- (void) pause
{
    [self.videoPlayerView pause];
}

- (void) resume
{
    [self.videoPlayerView play];
}
#pragma mark - PrivateMethods(Add Subviews)

- (void) addJKVideoPlayerView
{
    JKVideoPlayerView *playerView = [[JKVideoPlayerView alloc] initWithFrame:self.bounds];
//    playerView.backgroundColor = [UIColor clearColor];
    playerView.delegate = self;
    self.videoPlayerView = playerView;
    [self addSubview:_videoPlayerView];
}

- (void) addFirstFrameImageView
{
    self.firstFrameImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.firstFrameImageView.image = [UIImage imageNamed:@"videoplayerDefaultImage.png"];
    self.firstFrameImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.firstFrameImageView];
}

- (void) addBottomControlView
{
    self.bottomControlView = [[BottomControllView alloc] initWithFrame:CGRectMake(0.0, self.frame.size.height-40.0, self.frame.size.width, 40.0)];
    [self addSubview:_bottomControlView]; 
    [self.bottomControlView.sliderView addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [self.bottomControlView.sliderView addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomControlView.sliderView addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
    [self.bottomControlView.sliderView addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchCancel];
    [self.bottomControlView.sliderView addTarget:self action:@selector(scrubbing:) forControlEvents:UIControlEventValueChanged];
}


- (void) addTopControlView
{
    
}

- (void) addPlayButton
{
    UIImage *playImage = [UIImage imageNamed:@"btn_play.png"];
    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playBtn.frame = CGRectMake((self.frame.size.width-playImage.size.width)/2.0, (self.frame.size.height-playImage.size.height)/2.0, playImage.size.width, playImage.size.height);
    [self.playBtn setImage:[UIImage imageNamed:@"btn_play.png"] forState:UIControlStateNormal];
    [self.playBtn addTarget:self action:@selector(playBtnAcion:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_playBtn];
    _playBtn.hidden = YES;
}
- (void) addLoadingImageView
{
    UIImage *loadingImage = [UIImage imageNamed:@"btn_loading.png"];
    self.loadingImageView = [[UIImageView alloc] initWithImage:loadingImage];
    self.loadingImageView.frame = CGRectMake((self.bounds.size.width-loadingImage.size.width)/2.0, (self.bounds.size.height-loadingImage.size.height)/2., loadingImage.size.width, loadingImage.size.height);
    [self addSubview:self.loadingImageView];
    self.loadingImageView.hidden = YES;
}

- (void) startLoading
{
    if (self.loadingImageView.hidden == YES)
    {
        [self.loadingImageView.layer removeAllAnimations];
        CABasicAnimation* rotationAnimation;
        rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
        rotationAnimation.duration = 1;
        rotationAnimation.cumulative = YES;
        rotationAnimation.repeatCount = MAXFLOAT;
        [self.loadingImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
        
        self.loadingImageView.hidden = NO;
        self.playBtn.hidden = YES;
    }
}

- (void) stopLoading
{
    self.loadingImageView.hidden = YES;
    [self.loadingImageView.layer removeAllAnimations];
    if (self.videoPlayerView.player.rate != 0)
    {
        self.playBtn.hidden = YES;
    }
    else
    {
        self.playBtn.hidden = NO;
    }
    
}

#pragma mark - 方向监听
- (void) addDeviceOrientationNotificationObserver
{
    /* 监听横竖屏 */
    [self removeDeviceOrientationNotificationObserver];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void) removeDeviceOrientationNotificationObserver
{
    /* 移除横竖屏监听 */
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}


#pragma mark - init
- (id) init
{
    if (self = [super init])
    {
        [self commonInit];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL
{
    if (self = [super initWithFrame:frame])
    {
        [self commonInit];
    }
    return self;
}
- (void) commonInit
{
    [self addJKVideoPlayerView];
    [self addFirstFrameImageView];
    [self addTopControlView];
    [self addBottomControlView];
    [self addLoadingImageView];
    [self addPlayButton];
    [self addDeviceOrientationNotificationObserver];
}

#pragma mark - UIDeviceOrientationDidChangeNotification
- (void) deviceOrientationDidChange : (NSNotification *)notification
{
    /* 收到旋转通知 */
    UIDeviceOrientation orientation= [[UIDevice currentDevice] orientation];
    switch (orientation)
    {
        case UIDeviceOrientationPortrait:
        {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
            [self setPlayerOrientation:UIInterfaceOrientationPortrait];
            break;
        }
        case UIDeviceOrientationPortraitUpsideDown:
        {
            break;
        }
        case UIDeviceOrientationLandscapeLeft:
        {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
            [self setPlayerOrientation:UIInterfaceOrientationLandscapeLeft];
            break;
        }
        case UIDeviceOrientationLandscapeRight:
        {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
            [self setPlayerOrientation:UIInterfaceOrientationLandscapeRight];
            break;
        }
        default:
            break;
    }
}

///设置播放器全屏旋转
-(void)setPlayerOrientation:(UIInterfaceOrientation)orientation
{
    switch (orientation)
    {
        case UIInterfaceOrientationPortrait:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                [self setTransform:CGAffineTransformMakeRotation(0)];
                                [self addToSuperView:self.superView];
                                
                            } completion:^(BOOL finished) {
                                //                    isPlayerFullScreen=NO;
                            }];
            break;
        }
        case UIInterfaceOrientationLandscapeLeft:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                [self setTransform:CGAffineTransformMakeRotation(M_PI_2)];
                                
                                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                UIWindow *appWindow = appDelegate.window;
                                [self addToSuperView:appWindow];
                                
                             }
                             completion:^(BOOL finished) {
                                
                             }];
            break;
        }
        case UIInterfaceOrientationLandscapeRight:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                [self setTransform:CGAffineTransformMakeRotation(M_PI_2*3)];
                                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                UIWindow *appWindow = appDelegate.window;
                                [self addToSuperView:appWindow];
                            }
                            completion:^(BOOL finished) {
                                 
                            }];
            break;
        }
        default:
            break;
    }
}

#pragma mark - UITouch
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self playBtnAcion:_playBtn];
}
- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

#pragma mark - VideoPlayerViewDelegate
- (void) videoPlayerViewIsReadyToPlayVideo:(JKVideoPlayerView *)videoPlayerView
{
    if (self.successBlock)
    {
        self.successBlock();
    }
    self.bottomControlView.totalDurationLabel.text = SECOND_FRAMENT(CMTimeGetSeconds(videoPlayerView.player.currentItem.duration), @"");
    self.playBtn.hidden = YES;
    self.firstFrameImageView.hidden = YES;
}
- (void) videoPlayerViewDidReachEnd:(JKVideoPlayerView *)videoPlayerView
{
    
}
- (void) videoPlayerView:(JKVideoPlayerView *)videoPlayerView timeDidChange:(CMTime)cmTime
{
    CGFloat currentTime = CMTimeGetSeconds(cmTime);
    CGFloat videoDuration = CMTimeGetSeconds(videoPlayerView.player.currentItem.duration);
    self.bottomControlView.sliderView.value = currentTime / videoDuration;
    self.bottomControlView.currentTimeLabel.text = SECOND_FRAMENT(CMTimeGetSeconds(cmTime), @"");
}
- (void) videoPlayerView:(JKVideoPlayerView *)videoPlayerView loadedTimeRangeDidChange:(float)duration
{
//    CGFloat videoDuration = CMTimeGetSeconds(videoPlayerView.player.currentItem.duration);
//    self.bottomControlView.sliderView.middleValue = duration / videoDuration;
}
- (void) videoPlayerView:(JKVideoPlayerView *)videoPlayerView didFailWithError:(NSError *)error
{
    [self stopLoading];
    self.playBtn.hidden = YES;
//    [self removeFromSuperview];
    
    if (self.failureBlock)
    {
        self.failureBlock(error);
    }
}

- (void) videoPlayerViewShouldShowLoadingIndicator:(JKVideoPlayerView *)videoPlayerView
{
    [self startLoading];
}

- (void) videoPlayerViewShouldHideLoadingIndicator:(JKVideoPlayerView *)videoPlayerView
{
    [self stopLoading];
}

- (void) videoPlayerViewNetworkNotBest:(JKVideoPlayerView *)videoPlayerView
{
    [self startLoading];
}

#pragma mark - IBAction
- (IBAction)playBtnAcion:(id)sender
{
    if (self.videoPlayerView.isPlaying == YES)
    {
        self.playBtn.hidden = NO;
        [self.videoPlayerView pause];
    }
    else
    {
        self.playBtn.hidden = YES;
        [self.videoPlayerView play];
    }
}
#pragma mark - UISliderAction
- (IBAction)beginScrubbing:(UISlider *)sender
{
    [self.videoPlayerView startScrubbing];
}
- (IBAction)endScrubbing:(UISlider *)sender
{
    [self.videoPlayerView stopScrubbing];
}
- (IBAction)scrubbing:(UISlider *)sender
{
    [self.videoPlayerView scrub:sender.value * CMTimeGetSeconds(self.videoPlayerView.player.currentItem.duration)];
}
@end
