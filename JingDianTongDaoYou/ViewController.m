//
//  ViewController.m
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 16/7/8.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _recorder = [[HTRecorder alloc] init];
}

#pragma mark - 开始对讲/结束对讲

-(IBAction)startRecord:(id)sender{
    [_recorder startRecording];
}
-(IBAction)stopRecord:(id)sender{
    [_recorder stopRecording];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
