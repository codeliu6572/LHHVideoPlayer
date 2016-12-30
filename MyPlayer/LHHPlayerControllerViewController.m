//
//  LHHPlayerControllerViewController.m
//  MyPlayer
//
//  Created by 刘浩浩 on 2016/12/26.
//  Copyright © 2016年 CodingFire. All rights reserved.
//

#import "LHHPlayerControllerViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "LHHPlayerView.h"
#import "AppDelegate.h"
#import "VoiceLight.h"
#define VIEWWIDTH [UIScreen mainScreen].bounds.size.width
#define VIEWHEIGTH [UIScreen mainScreen].bounds.size.height


#define OFFSET 5.0 // 快进和快退的时间跨度
#define ALPHA 0.7 // headerView和bottomView的透明度

static void * playerItemDurationContext = &playerItemDurationContext;
static void * playerItemStatusContext = &playerItemStatusContext;
static void * playerPlayingContext = &playerPlayingContext;

@interface LHHPlayerControllerViewController ()<FastForwardDelegate>


@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playItem;
@property (strong, nonatomic) LHHPlayerView *playerView;
@property (assign, nonatomic) BOOL bigView;
@property (strong, nonatomic) NSURL *mediaUrl;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UIImageView *bottomView;
@property (strong, nonatomic) UIButton *backBtn;
@property (strong, nonatomic) UIButton *bigViewBtn;

@property (nonatomic, assign) BOOL isPlaying; // 是否正在播放
@property (nonatomic, assign) BOOL canPlay; // 是否可以播放

@property (nonatomic, assign) CMTime duration; // 视频总时间
@property (strong, nonatomic) UIButton *fastBackwardButton; // 快退
@property (strong, nonatomic) UIButton *playButton; // 播放
@property (strong, nonatomic) UIButton *fastForwardButton; // 快进
@property (nonatomic, strong) id timeObserver;
@property (strong, nonatomic) UILabel *currentTimeLabel; // 当前播放的时间
@property (strong, nonatomic) UILabel *remainTimeLabel; // 剩余时间
@property (strong, nonatomic) UISlider *progressView; // 播放进度
@property (strong, nonatomic) VoiceLight *voiceLight; // 音量亮度

@end

@implementation LHHPlayerControllerViewController



- (instancetype)initWithHTTMediaURL:(NSURL *)url
{
    if (self = [super init]) {
        self.mediaUrl = url;
        [self createHLSPlayerItem];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    //    1.隐藏原生导航条
    [self.navigationController setNavigationBarHidden:YES];
    
    _bigView = NO;
    AppDelegate *appdelegate=(AppDelegate *)[UIApplication sharedApplication].delegate;
    appdelegate.allowRotation=YES;
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // iOS 7 以上
        [self prefersStatusBarHidden];
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    
    
    [self creatMVplayer];
    [self creatHeaderView];
    [self creatBottomView];
    [self.progressView setMinimumTrackImage:[[UIImage imageNamed:@"video_num_front.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5) resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
    [self.progressView setMaximumTrackImage:[[UIImage imageNamed:@"video_num_bg.png"]  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5) resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
    [self.progressView setThumbImage:[UIImage imageNamed:@"progressThumb.png"] forState:UIControlStateNormal];
    
    // KVO观察self.isPlaying属性的变化以改变playButton的状态
    [self addObserver:self forKeyPath:@"isPlaying" options:NSKeyValueObservingOptionNew context:playerPlayingContext];
    
    
    // 监控 app 活动状态，打电话/锁屏 时暂停播放
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    

}



- (void)appWillResignActive:(NSNotification *)aNotification {
    [self.player pause];
    self.isPlaying = NO;
}

- (void)appDidBecomActive:(NSNotification *)aNotification {
    //
    [self.player play];
    self.isPlaying = YES;
}

- (void)createHLSPlayerItem {
    // HTTPLiveStreaming视频流不能直接创建AVAsset，直接从url创建playerItem对象
    // When you associate the player item with a player, it starts to become ready to play. When it is ready to play, the player item creates the AVAsset and AVAssetTrack instances, which you can use to inspect the contents of the live stream.
    self.playItem = [AVPlayerItem playerItemWithURL:self.mediaUrl];
}
- (void)creatMVplayer
{
    
    
    // 观察self.playItem.status属性变化，变为AVPlayerItemStatusReadyToPlay时就可以播放了
    [self addObserver:self forKeyPath:@"playItem.status" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:playerItemStatusContext];
    // 监听播放到最后的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    // 3.playerItem关联创建player
    self.player = [AVPlayer playerWithPlayerItem:self.playItem];
    self.playerView = [[LHHPlayerView alloc]initWithFrame:CGRectMake(0, 0, VIEWWIDTH, 240)];
    // 4.player关联创建playerView
    [self.playerView setPlayer:self.player];
    
    [self.playerView.layer setBackgroundColor:[UIColor blackColor].CGColor];


    //添加播放视图到self.view
    [self.view addSubview:self.playerView];
    
    
    _voiceLight = [[VoiceLight alloc]initWithFrame:self.playerView.bounds];
    _voiceLight.delegate = self;
    [self.playerView addSubview:_voiceLight];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(bigViewBtnAction)];
    tapGes.numberOfTapsRequired = 2;
    [self.playerView addGestureRecognizer:tapGes];
    
    UITapGestureRecognizer *tapGesOne = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(headerAndBottomTagGes)];
    tapGesOne.numberOfTapsRequired = 1;
    [self.playerView addGestureRecognizer:tapGesOne];
    
    //解决手势冲突问题，当滑动时使点击手势失效
    [_voiceLight.centerSwipeGestureRecognizerLeft requireGestureRecognizerToFail:tapGesOne];
    [_voiceLight.centerSwipeGestureRecognizerRight requireGestureRecognizerToFail:tapGesOne];
    
    [self.player play];


}

#pragma mark - 上状态栏
- (void)creatHeaderView
{
    _headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, VIEWWIDTH, 40)];
    _headerView.userInteractionEnabled = YES;
    [self.playerView addSubview:_headerView];
    
    //BACK BUTTON
    _backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _backBtn.frame = CGRectMake(0, 0, 44, 40);
    [_backBtn setImage:[[UIImage imageNamed:@"detail_backbtn.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    _backBtn.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 24);
    [_backBtn addTarget:self action:@selector(backBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:_backBtn];
    
    //全屏按钮
    _bigViewBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _bigViewBtn.frame = CGRectMake(_headerView.bounds.size.width - 44 ,0, 44, 40);
    [_bigViewBtn setImage:[[UIImage imageNamed:@"detail_big.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    _bigViewBtn.contentEdgeInsets = UIEdgeInsetsMake(10, 14, 10, 10);
    [_bigViewBtn addTarget:self action:@selector(bigViewBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:_bigViewBtn];
}

#pragma mark - 下状态栏
- (void)creatBottomView
{
    _bottomView = [[UIImageView alloc]initWithFrame:CGRectMake(0, self.playerView.bounds.size.height - 50, VIEWWIDTH, 50)];
    _bottomView.alpha = ALPHA;
    _bottomView.userInteractionEnabled = YES;

    _bottomView.image = [UIImage imageNamed:@"detail_play_bg.png"];
    [self.playerView addSubview:_bottomView];
    
    //PLAY BUTTON
    _playButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _playButton.frame = CGRectMake(0, 5, 44, 40);
    [_playButton setImage:[[UIImage imageNamed:@"play_nor@2x.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_playButton];
    
    //progressView
    _progressView = [[UISlider alloc]initWithFrame:CGRectMake(45, 21, VIEWWIDTH - 60 - 80, 10)];
    [_progressView addTarget:self action:@selector(slidingProgress:) forControlEvents:UIControlEventValueChanged];
    [_progressView addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpInside];
    [_progressView addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpOutside];
    [_bottomView addSubview:_progressView];
    
    
    //TAP
    UITapGestureRecognizer *tapGeture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(sliderTapGesture:)];
    [_progressView addGestureRecognizer:tapGeture];
    
    _currentTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(VIEWWIDTH - 90, 5, 45, 40)];
    _currentTimeLabel.text = @"00:00";
    _currentTimeLabel.font = [UIFont systemFontOfSize:12];
    _currentTimeLabel.textColor = [UIColor whiteColor];
    _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    [_bottomView addSubview:_currentTimeLabel];
    
    _remainTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(VIEWWIDTH - 45, 5, 45, 40)];
    _remainTimeLabel.text = @"00:00";
    _remainTimeLabel.font = [UIFont systemFontOfSize:12];
    _remainTimeLabel.textColor = [UIColor whiteColor];
    _remainTimeLabel.textAlignment = NSTextAlignmentCenter;
    [_bottomView addSubview:_remainTimeLabel];
}


#pragma mark - backAction
- (void)backBtnAction
{
    if (_bigView == YES) {
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait]forKey:@"orientation"];
        self.playerView.frame = CGRectMake(0, 0, VIEWWIDTH, 220);
        _bigView = NO;
        [self layoutUI];

    }
    else
    {
        AppDelegate *appdelegate=(AppDelegate *)[UIApplication sharedApplication].delegate;
        appdelegate.allowRotation=NO;
        [self.player pause];
        [self.playerView removeFromSuperview];
        [self.navigationController popViewControllerAnimated:YES];
        
    }
  


}
#pragma mark - bigViewBtnAction
- (void)bigViewBtnAction
{
    if (_bigView == NO) {
        self.playerView.frame = CGRectMake(0, 0, VIEWWIDTH, VIEWHEIGTH);
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationLandscapeLeft]forKey:@"orientation"];
        _bigView = YES;
    }
    else
    {
        self.playerView.frame = CGRectMake(0, 0, VIEWWIDTH, 220);
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait]forKey:@"orientation"];
        _bigView = NO;
    }
    [self layoutUI];

}

#pragma mark layoutUI
- (void)layoutUI
{
    
    _headerView.frame = CGRectMake(0 ,0, VIEWWIDTH, 40);
    _bottomView.frame = CGRectMake(0 ,self.playerView.bounds.size.height - 50, VIEWWIDTH, 50);
    _bigViewBtn.frame = CGRectMake(_headerView.bounds.size.width - 44 ,0, 44, 40);
    _progressView.frame = CGRectMake(45, 21, VIEWWIDTH - 60 - 80, 10);
    _currentTimeLabel.frame = CGRectMake(VIEWWIDTH - 90, 5, 45, 40);
    _remainTimeLabel.frame = CGRectMake(VIEWWIDTH - 45, 5, 45, 40);
    _voiceLight.frame = self.playerView.bounds;
}
#pragma mark 播放到最后时
- (void)playerItemDidPlayToEnd:(NSNotification *)aNotification {
    [self.playItem seekToTime:kCMTimeZero];
    self.isPlaying = NO;
}

#pragma mark 快退
- (void)fastBackward {
    [self cancelPerformSelector:@selector(hideHeaderViewAndBottomView)];
    
    [self progressAdd:-OFFSET];
    
    [self delayHideHeaderViewAndBottomView];
}

#pragma mark 播放
- (void)play:(UIButton *)sender {
    [self cancelPerformSelector:@selector(hideHeaderViewAndBottomView)];
    
    if (!self.isPlaying) {
        [self.player play];
        
        self.isPlaying = YES; // KVO观察playing属性的变化
    } else {
        [self.player pause];
        
        self.isPlaying = NO;
    }
    
    [self delayHideHeaderViewAndBottomView];
}

#pragma mark 快进
- (void)fastForward {
    [self cancelPerformSelector:@selector(hideHeaderViewAndBottomView)];
    
    [self progressAdd:OFFSET];
    
    [self delayHideHeaderViewAndBottomView];
}
- (void)sliderTapGesture:(UITapGestureRecognizer *)sender {
    [self cancelPerformSelector:@selector(hideHeaderViewAndBottomView)];
    
    CGFloat tapX = [sender locationInView:sender.view].x;
    CGFloat sliderWidth = sender.view.bounds.size.width;
    
    Float64 totalSeconds = CMTimeGetSeconds(self.duration); // 总时间
    CMTime dstTime = CMTimeMakeWithSeconds(totalSeconds * (tapX / sliderWidth), self.duration.timescale);
    
    [self seekToCMTime:dstTime progress:self.progressView.value];
    
    [self delayHideHeaderViewAndBottomView];
}


- (void)progressAdd:(CGFloat)step {
    // 如果正在播放先暂停播放（但是不改变_playing的值为NO，因为快进或快退完成后要根据_playing来判断是否要继续播放），再进行播放定位
    if (_isPlaying) {
        [self.player pause];
    }
    
    Float64 currentSecond = CMTimeGetSeconds(self.player.currentTime); // 当前秒
    Float64 totalSeconds = CMTimeGetSeconds(self.duration); // 总时间
    
    CMTime dstTime; // 目标时间
    
    if (currentSecond + step >= totalSeconds) {
        dstTime = CMTimeSubtract(self.duration, CMTimeMakeWithSeconds(1, self.duration.timescale));
        self.progressView.value = dstTime.value / self.duration.value;
    } else if (currentSecond + step < 0.0) {
        dstTime = kCMTimeZero;
        self.progressView.value = 0.0;
    } else {
        dstTime = CMTimeMakeWithSeconds(currentSecond + step, self.player.currentTime.timescale);
        self.progressView.value += step / CMTimeGetSeconds(self.duration);
    }
    
    [self seekToCMTime:dstTime progress:self.progressView.value];
    if (_isPlaying) {
        [self.player play];
    }
}

// 调整播放点
- (void)seekToCMTime:(CMTime)time progress:(CGFloat)progress{
    
    
    [self.player seekToTime:time];
}

#pragma mark - 拖动进度条改变播放点(playhead)
// valueChanged
- (void)slidingProgress:(UISlider *)slider {
    
    // 取消调用hideHeaderViewAndBottomView方法，不隐藏
    [self cancelPerformSelector:@selector(hideHeaderViewAndBottomView)];
    
    Float64 totalSeconds = CMTimeGetSeconds(self.duration);
    
    CMTime time = CMTimeMakeWithSeconds(totalSeconds * slider.value, self.duration.timescale);
    
    [self seekToCMTime:time progress:self.progressView.value];
}

// touchUpInside/touchUpOutside
- (void)slidingEnded:(UISlider *)sender {
    // 拖动手势取消后延迟调用hideHeaderViewAndBottomView
    [self delayHideHeaderViewAndBottomView];


}



#pragma mark 根据CMTime生成一个时间字符串
- (NSString *)timeStringWithCMTime:(CMTime)time {
    Float64 seconds = time.value / time.timescale;
    // 把seconds当作时间戳得到一个date
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
    
    // 格林威治标准时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    // 设置时间显示格式
    [formatter setDateFormat:(seconds / 3600 >= 1) ? @"h:mm:ss" : @"mm:ss"];
    
    // 返回这个date的字符串形式
    return [formatter stringFromDate:date];
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == playerItemStatusContext) {
        
        if (self.playItem.status == AVPlayerItemStatusReadyToPlay) {
            // 视频准备就绪
            dispatch_async(dispatch_get_main_queue(), ^{
                [self readyToPlay];
            });
        } else {
            // 如果一个不能播放的视频资源加载进来会进到这里
            NSLog(@"视频无法播放");
            // 延迟dismiss播放器视图控制器
            [self performSelector:@selector(delayDismissPlayerViewController) withObject:nil afterDelay:3.0f];
        }
        
    } else if (context == playerPlayingContext){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[change objectForKey:@"new"] intValue] == 1) {
                // 如果playing变为YES就显示暂停按钮
                [self.playButton setImage:[[UIImage imageNamed:@"pause_nor@2x.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
            } else {
                // 如果playing变为NO就显示播放按钮
                [self.playButton setImage:[[UIImage imageNamed:@"play_nor@2x.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
            }
        });
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)delayDismissPlayerViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark AVPlayerItemStatusReadyToPlay
- (void)readyToPlay {
    
    // 视频可以播放时才自动延迟隐藏headerView和bottomView
    [self delayHideHeaderViewAndBottomView];
    
    // 可以播放
    self.canPlay = YES;
    [self.playButton setEnabled:YES];
    [self.fastBackwardButton setEnabled:YES];
    [self.fastForwardButton setEnabled:YES];
    [self.progressView setEnabled:YES];
    
    self.duration = self.playItem.duration;
    
    // 未播放前剩余时间就是视频长度
    self.remainTimeLabel.text = [NSString stringWithFormat:@"%@", [self timeStringWithCMTime:self.duration]];
    
    __weak typeof(self) weakSelf = self;
    // 更新当前播放条目的已播时间, CMTimeMake(3, 30) == (Float64)3/30 秒
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:nil usingBlock:^(CMTime time) {
        // 当前播放时间
        weakSelf.currentTimeLabel.text = [weakSelf timeStringWithCMTime:time];
        // 剩余时间
        NSString *text = [weakSelf timeStringWithCMTime:CMTimeSubtract(weakSelf.duration, time)];
        weakSelf.remainTimeLabel.text = [NSString stringWithFormat:@"%@", text];
        
        // 更新进度
        weakSelf.progressView.value = CMTimeGetSeconds(time) / CMTimeGetSeconds(weakSelf.duration);
        
    }];
    
    NSLog(@"状态准备就绪 -> %@", @(AVPlayerItemStatusReadyToPlay));
    [_playButton setImage:[[UIImage imageNamed:@"pause_nor@2x.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    self.isPlaying = YES; // KVO观察playing属性的变化

}

#pragma mark - touch
- (void)headerAndBottomTagGes
{

    
    
    // 显示或隐藏播放工具栏
    if (self.headerView.alpha == 0.0) {
        // 隐藏状态下就显示
        [self showHeaderViewAndBottomView];
        
    } else {
        // 显示状态下就隐藏
        [self hideHeaderViewAndBottomView];
        
        // 在显示状态下点击后就隐藏，那么之前的延迟调用就要取消，不取消也不会有问题
        [self cancelPerformSelector:@selector(hideHeaderViewAndBottomView)];
    }
    
   
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if (self.headerView.alpha == 0.0) { // 隐藏状态下
        
    } else { // 显示状态下
        
        // 手势取消后延迟调用hideHeaderViewAndBottomView
        [self delayHideHeaderViewAndBottomView];
    }
}

#pragma mark 延迟调用hideHeaderViewAndBottomView方法
- (void)delayHideHeaderViewAndBottomView {
    [self performSelector:@selector(hideHeaderViewAndBottomView) withObject:nil afterDelay:5.0f];
}

#pragma mark 取消调用某个方法
- (void)cancelPerformSelector:(SEL)selector {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:selector object:nil];
}

#pragma mark 隐藏headerView和bottomView
- (void)hideHeaderViewAndBottomView {
    [UIView animateWithDuration:0.5 animations:^{
        [self.headerView setAlpha:0.0];
        [self.bottomView setAlpha:0.0];
    }];
}

#pragma mark 显示headerView和bottomView
- (void)showHeaderViewAndBottomView {
    [UIView animateWithDuration:0.5 animations:^{
        [self.headerView setAlpha:ALPHA];
        [self.bottomView setAlpha:ALPHA];
    }];
}


#pragma mark - 状态栏
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - 屏幕方向
// 允许自动旋转，在支持的屏幕中设置了允许旋转的屏幕方向。
- (BOOL)shouldAutorotate
{
    return YES;
}

// 支持的屏幕方向，这个方法返回 UIInterfaceOrientationMask 类型的值。
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

// 视图展示的时候优先展示为 竖屏
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            //home健在下
            self.playerView.frame = CGRectMake(0, 0, VIEWWIDTH, 220);
            _bigView = NO;

            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            //home健在上
          
            break;
        case UIInterfaceOrientationLandscapeLeft:
            //home健在左
            self.playerView.frame = CGRectMake(0, 0, VIEWWIDTH, VIEWHEIGTH);
            _bigView = YES;

          
            break;
        case UIInterfaceOrientationLandscapeRight:
            //home健在右
            self.playerView.frame = CGRectMake(0, 0, VIEWWIDTH, VIEWHEIGTH);
            _bigView = YES;

            break;
        default:
            break;
            
            
    }
    [self layoutUI];

}

#pragma mark - FastForwardDeleget

- (void)fastFont
{
    [self fastForward];
}

- (void)fastBack
{
    [self fastBackward];
}

#pragma mark - dealloc

- (void)dealloc
{
    [self.player pause];
    
    [self removeObserver:self forKeyPath:@"playItem.status" context:playerItemStatusContext];
    
    [self removeObserver:self forKeyPath:@"isPlaying" context:playerPlayingContext];
    
    [self.player removeTimeObserver:self.timeObserver];
    self.timeObserver = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.player = nil;
    self.playItem = nil;
    self.mediaUrl = nil;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
