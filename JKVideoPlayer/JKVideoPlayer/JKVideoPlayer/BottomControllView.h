//
//  BottomControllView.h
//  JKVideoPlayer
//
//  Created by mac on 15/8/28.
//  Copyright (c) 2015年 uupye. All rights reserved.
//
/* 自定义底部工具条 */

#import <UIKit/UIKit.h>

@interface BottomControllView : UIView

/* 当前播放时间 */
@property (nonatomic, retain) UILabel *currentTimeLabel;
/* 总的播放时间 */
@property (nonatomic, retain) UILabel *totalDurationLabel;
/* 播放进度条 */
@property (nonatomic, retain) UISlider *sliderView;

- (void) setAllSubviewsFrame;
@end
