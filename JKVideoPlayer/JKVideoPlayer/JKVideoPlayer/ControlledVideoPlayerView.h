//
//  ControlledVideoPlayerView.h
//  JKVideoPlayer
//
//  Created by mac on 15/8/27.
//  Copyright (c) 2015年 uupye. All rights reserved.
//
/*  在JKVideoPlayerView上添加自定义播放控制器 */
#import <UIKit/UIKit.h>
#import "BottomControllView.h"
#import "TopControlView.h"
@interface ControlledVideoPlayerView : UIView 

//- (id) initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL;
- (id) init;
- (void) playWithUrl:(NSURL *)videoURL Success:(void(^)(void))successBlock Failure:(void(^)(NSError* error))failureBlock;

- (void) setFirstFramePic:(UIImage *)img;
- (void) addToSuperView:(UIView *)superView;//这里自动设置了frame
- (void) RemoveFromSuperView;

- (void) pause;
- (void) resume;

- (void) addDeviceOrientationNotificationObserver;
- (void) removeDeviceOrientationNotificationObserver;
@end
