//
//  VoiceLight.m
//  VoiceLight
//
//  Created by 刘浩浩 on 2016/12/27.
//  Copyright © 2016年 CodingFire. All rights reserved.
//

#import "VoiceLight.h"

#define VIEWWIDTH [[UIScreen mainScreen]bounds].size.width
#define VIEWHEIGHT [[UIScreen mainScreen]bounds].size.height
@implementation VoiceLight
{
    UIView *leftView;
    UIView *centerView;
    UIView *rightView;
    float leftCurrentY;
    float leftLastY;
    float rightCurrentY;
    float rightLastY;
    //亮度
    float light;
    //音量
    float voice;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addVoiceAndLight];
    }
    return self;
}
- (void)addVoiceAndLight
{
    _mpVC = [MPMusicPlayerController applicationMusicPlayer];
    voice = _mpVC.volume;
    leftCurrentY = 0.0f;
    leftLastY = 0.0f;

    rightCurrentY = 0.0f;
    rightLastY = 0.0f;
    light = [UIScreen mainScreen].brightness;
    
    leftView = [[UIView alloc]init];
//    leftView.backgroundColor = [UIColor orangeColor];
    [self addSubview:leftView];
    
    centerView = [[UIView alloc]init];
//    centerView.backgroundColor = [UIColor cyanColor];
    [self addSubview:centerView];
    
    rightView = [[UIView alloc]init];
//    rightView.backgroundColor = [UIColor blueColor];
    [self addSubview:rightView];
    
    
    [leftView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).offset(0);
        make.top.equalTo(self.mas_top).offset(0);
        make.bottom.equalTo(self.mas_bottom).offset(0);
        make.right.equalTo(centerView.mas_left).offset(0);
        make.width.lessThanOrEqualTo(centerView);
        make.height.equalTo(centerView);
    }];
    
    [centerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(leftView.mas_right).offset(0);
        make.top.equalTo(self.mas_top).offset(0);
        make.bottom.equalTo(self.mas_bottom).offset(0);
        make.right.equalTo(rightView.mas_left).offset(0);
        make.width.equalTo(self).multipliedBy(0.5);
        make.height.equalTo(rightView);
    }];
    
    [rightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.mas_right).offset(0);
        make.top.equalTo(self.mas_top).offset(0);
        make.bottom.equalTo(self.mas_bottom).offset(0);
        make.left.equalTo(centerView.mas_right).offset(0);
        make.width.equalTo(leftView);
        make.height.equalTo(leftView);
    }];
    
    
    _leftSwipeGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(leftSwipGes:)];
    [leftView addGestureRecognizer:_leftSwipeGestureRecognizer];
    
    
    _centerSwipeGestureRecognizerLeft = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(centerSwipGesLeft)];
    _centerSwipeGestureRecognizerLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [centerView addGestureRecognizer:_centerSwipeGestureRecognizerLeft];
    
    _centerSwipeGestureRecognizerRight = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(centerSwipGesRight)];
    _centerSwipeGestureRecognizerRight.direction = UISwipeGestureRecognizerDirectionRight;
    [centerView addGestureRecognizer:_centerSwipeGestureRecognizerRight];
    
    _rightSwipeGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(rightSwipGes:)];
    [rightView addGestureRecognizer:_rightSwipeGestureRecognizer];
    
    
    
    
    
}


- (void)leftSwipGes:(UIPanGestureRecognizer *)leftSwip
{
    //滑动方法获取到当前位置的y坐标
    leftCurrentY = [leftSwip translationInView:leftView].y;
    
    NSLog(@"left");
    //当前坐标大于上一次移动的坐标，为向下滑动
    if (leftCurrentY > leftLastY) {
        if (light > 0) {
            //向下滑动屏幕变暗，亮度下降
            light = light - 0.01;
        }
        else{
            //当亮度为0时固定为0，禁止为负值
            light = 0;
        }
    }
    else
    {
        if (light < 1) {
            //向上滑动亮度增加
            light = light + 0.01;
        }
        else{
            //当亮度为1时固定为1，禁止大于1
            light = 1;
        }
        
    }
    //设置屏幕亮度
    [UIScreen mainScreen].brightness = light;
    //当前位置的上一次移动的位置y坐标
    leftLastY = leftCurrentY;
}


//此处除参数外原理一样，不再额外注释
- (void)centerSwipGesLeft
{
    NSLog(@"swipLeft");
    if (_delegate && [_delegate respondsToSelector:@selector(fastBack)]) {
        [_delegate fastBack];
    }
}
- (void)centerSwipGesRight
{
    NSLog(@"swipRight");
    
    if (_delegate && [_delegate respondsToSelector:@selector(fastFont)]) {
        [_delegate fastFont];
    }
    
}
//此处除参数外原理一样，不再额外注释
- (void)rightSwipGes:(UIPanGestureRecognizer *)rightSwip
{
    NSLog(@"right");
    rightCurrentY = [rightSwip translationInView:rightView].y;
    
    if (rightCurrentY > rightLastY) {
        if (voice > 0) {
            voice = voice - 0.01;
        }
        else{
            voice = 0;
        }
    }
    else
    {
        if (voice < 1) {
            voice = voice + 0.01;
        }
        else{
            voice = 1;
        }
        
    }
    //设置系统音量
    _mpVC.volume = voice;
    rightLastY = rightCurrentY;
}


@end
