//
//  LHHPlayerView.m
//  MyPlayer
//
//  Created by 刘浩浩 on 2016/12/26.
//  Copyright © 2016年 CodingFire. All rights reserved.
//

#import "LHHPlayerView.h"
#import <AVFoundation/AVFoundation.h>

@interface LHHPlayerView ()

@end

@implementation LHHPlayerView

// 使PlayerView的layer为AVPlayerLayer类型
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (void)dealloc
{
    self.player = nil;
}

@end

