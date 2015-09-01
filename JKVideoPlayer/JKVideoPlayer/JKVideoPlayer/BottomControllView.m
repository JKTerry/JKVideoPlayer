//
//  BottomControllView.m
//  JKVideoPlayer
//
//  Created by mac on 15/8/28.
//  Copyright (c) 2015年 uupye. All rights reserved.
//

#import "BottomControllView.h"

#define kTimeLabelWidth 40.0
@implementation BottomControllView

#pragma mark - dealloc
- (void) dealloc
{
}

#pragma mark - PrivateMethods
- (void) addSubview
{
    self.currentTimeLabel = [[UILabel alloc] init];
    self.currentTimeLabel.text = @"--:--";
    self.currentTimeLabel.textColor = [UIColor whiteColor];
    self.currentTimeLabel.backgroundColor = [UIColor clearColor];
    self.currentTimeLabel.font = [UIFont systemFontOfSize:15.0];
    [self addSubview:_currentTimeLabel];
    
    self.totalDurationLabel = [[UILabel alloc] init];
    self.totalDurationLabel.text = @"--:--";
    self.totalDurationLabel.textColor = [UIColor whiteColor];
    self.totalDurationLabel.backgroundColor = [UIColor clearColor];
    self.totalDurationLabel.font = [UIFont systemFontOfSize:15.0];
    [self addSubview:_totalDurationLabel];
    
    self.sliderView = [[UISlider alloc] init];
    [self addSubview:_sliderView];
    
    [self setAllSubviewsFrame];
}

- (void) setAllSubviewsFrame
{
    //To Do , Use constraints
    self.currentTimeLabel.frame = CGRectMake(12.0, (self.frame.size.height-20.0)/2.0, kTimeLabelWidth, 20.0);
    self.sliderView.frame = CGRectMake(self.currentTimeLabel.frame.size.width+self.currentTimeLabel.frame.origin.x+5.0, (self.frame.size.height-20.0)/2.0, self.frame.size.width-(self.currentTimeLabel.frame.size.width+self.currentTimeLabel.frame.origin.x+5.0) * 2, 20.0);
    self.totalDurationLabel.frame = CGRectMake(self.frame.size.width-self.sliderView.frame.origin.x+5.0, self.currentTimeLabel.frame.origin.y, kTimeLabelWidth, 20.0);
}

#pragma mark - init
- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview];
    }
    return self;
}
#pragma mark - IBAction

@end
