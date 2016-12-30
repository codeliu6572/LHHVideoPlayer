//
//  ViewController.m
//  MyPlayer
//
//  Created by 刘浩浩 on 2016/12/26.
//  Copyright © 2016年 CodingFire. All rights reserved.
//

#import "ViewController.h"
#import "LHHPlayerControllerViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.view.backgroundColor=[UIColor cyanColor];
    //    1.隐藏原生导航条
    [self.navigationController setNavigationBarHidden:NO];
    self.view.backgroundColor = [UIColor whiteColor];
    UILabel *label = [[UILabel alloc]initWithFrame:self.view.bounds];
    label.text = @"CLICK";
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor orangeColor];
    label.font = [UIFont systemFontOfSize:20];
    [self.view addSubview:label];
    
}

- (void)creatPlayerVC
{
    LHHPlayerControllerViewController *movieVC = [[LHHPlayerControllerViewController alloc]initWithHTTMediaURL:[NSURL URLWithString:@"http://flv.bn.netease.com/videolib3/1610/12/vtfiM7162/HD/vtfiM7162-mobile.mp4"]];
//    movieVC.delegate = self;
    [self.navigationController pushViewController:movieVC animated:YES];
    
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{

    [self creatPlayerVC];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
