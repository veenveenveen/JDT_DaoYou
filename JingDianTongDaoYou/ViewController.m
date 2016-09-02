//
//  ViewController.m
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 16/7/8.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *recorderButton;
@property (weak, nonatomic) IBOutlet UILabel *recorderLable;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _recorder = [[HTRecorder alloc] init];
}

#pragma mark - 开始对讲/结束对讲
- (IBAction)recordOrPause:(id)sender {
    if (_recorder.isRecording) {
        [self.recorderButton setImage:[UIImage imageNamed:@"record_false"] forState:UIControlStateNormal];
        self.recorderLable.hidden = YES;
        [_recorder stopRecording];
        _recorder.isRecording = NO;
    }
    else if (!_recorder.isRecording) {
        [self.recorderButton setImage:[UIImage imageNamed:@"record_true"] forState:UIControlStateNormal];
        self.recorderLable.hidden = NO;
        [_recorder startRecording];
        _recorder.isRecording = YES;
    }
}

//-(IBAction)startRecord:(id)sender{
//    [_recorder startRecording];
//}
//-(IBAction)stopRecord:(id)sender{
//    [_recorder stopRecording];
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
