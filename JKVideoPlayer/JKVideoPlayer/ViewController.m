//
//  ViewController.m
//  JKVideoPlayer
//
//  Created by mac on 15/8/19.
//  Copyright (c) 2015年 uupye. All rights reserved.
//

#import "ViewController.h"
#import "JKVideoPlayerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 10;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    cell.textLabel.text = @"aaa";
    for (UIView *View in [cell.contentView subviews])
    {
        if ([View isKindOfClass:[JKVideoPlayerView class]])
        {
            JKVideoPlayerView *V = (JKVideoPlayerView *)View;
            [V setVideoURL:[NSURL URLWithString:@"http://krtv.qiniudn.com/150522nextapp"]];
            [V play];
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 200.0;
}

@end
