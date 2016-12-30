# LHHVideoPlayer
http链接的播放器，支持多种功能，你需要的就在这里




![image](https://github.com/codeliu6572/LHHVideoPlayer/blob/master/MyPlayer/2.gif)

由于亮度和音量只能在真机上显现效果，所以GIF未给出操作，其中快进快退区域为当前播放器宽度的一半，高度为播放器高度，
音量和亮度上下滑动区域总和为剩下的一半区域，且二者大小一样。

播放器基本功能：
<ol>
<li><a href="#a">视频播放和缓存（不支持流播放）；</a></li>
<li><a href="#b">双击屏幕全屏和竖屏；</a></li>
<li><a href="#c">快进快退；</a></li>
<li><a href="#d">滑动调节屏幕亮度和系统声音；</a></li>
<li><a href="#e">全屏按钮和返回按钮；</a></li>
<li><a href="#f">进度条拖动和点击定位播放；</a></li>
<li><a href="#g">完美适配横竖屏；</a></li>
<li><a href="#h">打断机制和监听机制；</a></li>
<li><a href="#i">dealloc；</a></li>
<li><a href="#j">总结；</a></li>
</ol>
<p id="a">1.视频播放和缓存（不支持流播放）;</p>
创建播放器：

```
  // 3.playerItem关联创建player
    self.player = [AVPlayer playerWithPlayerItem:self.playItem];
    self.playerView = [[LHHPlayerView alloc]initWithFrame:CGRectMake(0, 0, VIEWWIDTH, 240)];
    // 4.player关联创建playerView
    // 4.player关联创建playerView
    [self.playerView setPlayer:self.player];
    
    [self.playerView.layer setBackgroundColor:[UIColor blackColor].CGColor];


    //添加播放视图到self.view
    [self.view addSubview:self.playerView];
```
为了能够在播放器的表层加上控件（AVPlayer原生不能往上加控件无效且没有交互属性），需要对它进行一个小操作：

```
#import <UIKit/UIKit.h>
@class AVPlayer;

@interface LHHPlayerView : UIView

@property (nonatomic, strong) AVPlayer *player;
@end

#import "LHHPlayerView.h"
#import <AVFoundation/AVFoundation.h>

@interface LHHPlayerView ()

@end

@implementation LHHPlayerView

// 为了使PlayerView的layer为AVPlayerLayer类型
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

```

然后用这个处理过的View作为AVPlayerLayer，此时可以往上增加控件。关于缓存，系统的播放器对于http连接的视频是会自动缓存的，不需要我们做什么操作，不妨下载Demo断网试一试。

<p id="b">2.双击屏幕全屏和竖屏；</p>
这里的横竖屏机制请看这篇博客：
http://blog.csdn.net/codingfire/article/details/50387774
按照上面博客的配置好之后，需要设置如下代码：

```
#pragma mark - 屏幕方向
// 允许自动旋转，在支持的屏幕中设置了允许旋转的屏幕方向。
- (BOOL)shouldAutorotate
{
    return YES;
}

// 支持的屏幕方向，这个方法返回 UIInterfaceOrientationMaskAllButUpsideDown 类型的值。
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

// 视图展示的时候优先展示为 竖屏，可更改
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

```
博主这里屏幕给了小屏，没有直接全屏，按自己需求更改播放器的播放界面frame，同时在横竖屏切换时要适时的刷新界面上UI：

```
根据重力感应手机方向来切换屏幕需要用到这个方法：
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
```
下面是通过双击屏幕和全屏按钮来控制横竖屏（也可根据需要适时退出界面）：

```
#pragma mark - backAction 返回按钮功能
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
- (void)bigViewBtnAction  全屏按钮功能
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
```
改变UI其实不需要改变什么，就是刷新下控件的位置，淫秽横竖屏宽高交换原则，相当于重新给一个frame，原值保持不变，其中的变量随着播放器frame改变而改变：

```
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
```

<p id="c">3.快进快退；</p>

```
#pragma mark 快退
- (void)fastBackward {
    [self cancelPerformSelector:@selector(hideHeaderViewAndBottomView)];
    
    [self progressAdd:-OFFSET];
    
    [self delayHideHeaderViewAndBottomView];
}
#pragma mark 快进
- (void)fastForward {
    [self cancelPerformSelector:@selector(hideHeaderViewAndBottomView)];
    
    [self progressAdd:OFFSET];
    
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

```
利用Swipe滑动手势来设定播放节点，找到播放位置，手势和控制屏幕亮度封装在了一起，通过一个代理来调用。

<p id="d">4.滑动调节屏幕亮度和系统声音；</p>
关于这个，请查看下面这篇博客：
http://blog.csdn.net/codingfire/article/details/53810649
里面详细说明了怎么通过滑动来控制系统声音和屏幕亮度，并有Demo供参考。
<p id="e">5.全屏按钮和返回按钮；</p>
这里的功能上面已经给出，需要注意的就是因为没有使用约束，所以每次横竖屏切换都要用方法自动或者手动来刷新界面控件的位置甚至图片，在代码中可以查看。
<p id="f">6.进度条拖动和点击定位播放；</p>
进度条用slider来完成，自定义UI，通过拖动的位置value属性和视频总时间判断当前播放时间和进度条位置，slider增加点击手势，通过点击位置瞬间定位到所点击的位置播放：

```
 //progressView初始化
    _progressView = [[UISlider alloc]initWithFrame:CGRectMake(45, 21, VIEWWIDTH - 60 - 80, 10)];
    [_progressView addTarget:self action:@selector(slidingProgress:) forControlEvents:UIControlEventValueChanged];
    [_progressView addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpInside];
    [_progressView addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpOutside];
    [_bottomView addSubview:_progressView];

//进度条UI定制
  [self.progressView setMinimumTrackImage:[[UIImage imageNamed:@"video_num_front.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5) resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
    [self.progressView setMaximumTrackImage:[[UIImage imageNamed:@"video_num_bg.png"]  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5) resizingMode:UIImageResizingModeStretch] forState:UIControlStateNormal];
    [self.progressView setThumbImage:[UIImage imageNamed:@"progressThumb.png"] forState:UIControlStateNormal];

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
//进度条点击定位
- (void)sliderTapGesture:(UITapGestureRecognizer *)sender {
    [self cancelPerformSelector:@selector(hideHeaderViewAndBottomView)];
    
    CGFloat tapX = [sender locationInView:sender.view].x;
    CGFloat sliderWidth = sender.view.bounds.size.width;
    
    Float64 totalSeconds = CMTimeGetSeconds(self.duration); // 总时间
    CMTime dstTime = CMTimeMakeWithSeconds(totalSeconds * (tapX / sliderWidth), self.duration.timescale);
    
    [self seekToCMTime:dstTime progress:self.progressView.value];
    
    [self delayHideHeaderViewAndBottomView];
}

```

<p id="g">7.完美适配横竖屏；</p>
很多时候大家注意的是手机方向改变时横竖屏切换和整个项目内横竖屏的关系，上面给出了方法来解决，在Appdelegate中给属性来决定是否支持横屏，这里还有一个手动的通过代码来设置的方法：

```
[[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationLandscapeLeft]forKey:@"orientation"];

```
可以根据自己的需要设置屏幕方向，前提是Xcode中设置了支持该方向。

<p id="h">8.打断机制和监听机制；</p>

```
   // 监控 app 活动状态，打电话/锁屏 时暂停播放
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
- (void)appWillResignActive:(NSNotification *)aNotification {
    [self.player pause];
    self.isPlaying = NO;
}

- (void)appDidBecomActive:(NSNotification *)aNotification {
    //
    [self.player play];
    self.isPlaying = YES;
}
```

KVO监听

```
 // KVO观察self.isPlaying属性的变化以改变playButton的状态
    [self addObserver:self forKeyPath:@"isPlaying" options:NSKeyValueObservingOptionNew context:playerPlayingContext];
// 观察self.playItem.status属性变化，变为AVPlayerItemStatusReadyToPlay时就可以播放了
    [self addObserver:self forKeyPath:@"playItem.status" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:playerItemStatusContext];



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

```

<p id="i">9.dealloc；</p>
最后的最后，别忘了dealloc，虽然目前有自动回收机制，不过类似视频这种的，貌似是没用的，需要手动来释放内存，删除监听和通知。
```
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

```

<p id="j">10.总结;</p>

以上便是博主封装AVPlayer的过程，不过其中也借鉴了很多东西，有一个叫JRVideoPlayer的开源Demo，博主的内容很多都是从这里来的，有些方法因为写的很完善索性直接拿过来用了，基本上是在原基础上做了优化和新增功能，前人植树，后人乘凉，踩着大神的脚步前进，这里也是因为博主项目中需要用到缓存才去做了封装，功能都是另外加的，UI因为我们的设计就是这样，所以列为不要嫌丑，可自行更换UI，刚好这个播放器可塑性很强，还有下载地址：[点击下载](https://github.com/codeliu6572/LHHVideoPlayer)
博主没有做本地视频的播放，只有网络视频的方法，后续会补上，这部分也不复杂，也可自行加上去。

有一点要着重说明，如果你需要播放器进去就是全屏，就在播放器的VC中改变frame为全屏，同时根据第7条的方法设置默认为横屏，如果你愿意竖屏也行，另外还需要把layoutUI中竖屏的frame改成全屏或者直接删除。如果你的详情页需要现在这样的小窗，下面展示信息和评论等，你需要在外部创建一个UIView，在VC中视频下面的区域放置这个UIView不需要改变frame，视频全屏时会遮住这个View，不用怕下面的界面混乱，以上是两种情况的思路，各位请自便。


