//
//  PlayerTableViewController.m
//  JKVideoPlayer
//
//  Created by mac on 15/8/27.
//  Copyright (c) 2015年 uupye. All rights reserved.
//

#import "PlayerTableViewController.h"
#import "JKVideoPlayerView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ControlledVideoPlayerView.h"
@interface PlayerTableViewController ()//<UITableViewDataSource,UITableViewDelegate>
{
    UITableView *myTableView;
    UIButton *btn;
    ControlledVideoPlayerView *controlledVideoPlayerView;
}

@end

@implementation PlayerTableViewController

#pragma mark - dealloc

#pragma mark - PrivateMethods

#pragma mark - init

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *superView = [[UIView alloc] initWithFrame:CGRectMake(100, 20, 200, 200)];
    [self.view addSubview:superView];
    
    controlledVideoPlayerView = [[ControlledVideoPlayerView alloc] init];//WithFrame:CGRectMake(0, 0, 200, 200) videoURL:[NSURL URLWithString:@"http://krtv.qiniudn.com/150522nextapp"]];//@"http://video-10002984.video.myqcloud.com/IMG_0510.mp4"]];//
    [controlledVideoPlayerView addToSuperView:superView];
    [controlledVideoPlayerView playWithUrl:[NSURL URLWithString:@"http://krtv.qiniudn.com/150522nextapp"]
                                   Success:^{
                                       
                                   } Failure:^(NSError *error) {
                                       
                                   }];
    
    btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setTitle:@"mgen" forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor greenColor];
    [self.view addSubview:btn];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.frame = CGRectMake(20, 400, 40, 40);
    [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:btn
//                                                          attribute:NSLayoutAttributeCenterX
//                                                          relatedBy:NSLayoutRelationEqual
//                                                             toItem:self.view
//                                                          attribute:NSLayoutAttributeCenterX
//                                                         multiplier:1
//                                                           constant:0]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction
- (IBAction)btnAction:(id)sender
{
    if (controlledVideoPlayerView)
    {
        [controlledVideoPlayerView RemoveFromSuperView];
        controlledVideoPlayerView = nil;
    }
}

@end
