//
//  VoiceLight.h
//  VoiceLight
//
//  Created by 刘浩浩 on 2016/12/27.
//  Copyright © 2016年 CodingFire. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Masonry.h>


@protocol FastForwardDelegate <NSObject>

- (void)fastFont;

- (void)fastBack;

@end
@interface VoiceLight : UIView
@property (nonatomic, strong) UIPanGestureRecognizer *leftSwipeGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *rightSwipeGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *centerSwipeGestureRecognizerLeft;
@property (nonatomic, strong) UISwipeGestureRecognizer *centerSwipeGestureRecognizerRight;
@property (nonatomic, strong) MPMusicPlayerController *mpVC;
@property (nonatomic, weak) id<FastForwardDelegate> delegate;


@end
