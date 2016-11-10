//
//  ViewController.m
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 16/7/8.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "HTShowStatusView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *recorderButton;
@property (weak, nonatomic) IBOutlet UILabel *recorderLable;

@property (nonatomic, assign) BOOL hasInterruptedWhenRecording;
@property (nonatomic, assign) BOOL hasHeadset;

@property (nonatomic, strong) HTShowStatusView *statusView;

@end

@implementation ViewController

- (instancetype)init {
    if (self = [super init]) {
        
        self.statusView = [[HTShowStatusView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-60-120-50, [UIScreen mainScreen].bounds.size.width, 60)];
        
        [self.view addSubview:self.statusView];
        
        self.recorder = [[HTRecorder alloc] init];
        
        self.hasInterruptedWhenRecording = NO;
        self.hasHeadset = NO;
        
        [self addListener];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - 开始对讲/结束对讲

- (IBAction)recordOrPause:(id)sender {
    if (self.recorder.isRecording) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.recorderButton setImage:[UIImage imageNamed:@"mic0"] forState:UIControlStateNormal];
            self.recorderLable.hidden = YES;
        });

        [self.recorder stopRecording];
        self.recorder.isRecording = NO;
    }
    else if (!self.recorder.isRecording) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.recorderButton setImage:[UIImage imageNamed:@"mic1"] forState:UIControlStateNormal];
            self.recorderLable.hidden = NO;
        });
        
        [self.recorder startRecording];
        self.recorder.isRecording = YES;
    }
}

#pragma mark - add listener

- (void)addListener {
    //被打断监听
    AudioSessionInitialize(NULL, NULL, interruptionListener, (__bridge void *)(self));
    //route改变监听
    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange,audioRouteChangeListenerCallback, (__bridge void *)(self));
}

//interrupt callback
void interruptionListener(void *inClientData, UInt32 inInterruptionState) {
    ViewController *appVC = (__bridge ViewController *)(inClientData);
    if (appVC) {
        if (kAudioSessionBeginInterruption == inInterruptionState) {
            NSLog(@"interruptionListenner state ================ %u", (unsigned int)inInterruptionState);
            if (appVC.recorder.isRecording) {
                [appVC recordOrPause:nil];
                NSLog(@"stop record");
                appVC.hasInterruptedWhenRecording = YES;
            }
        }
        else {
            NSLog(@"interruptionListenner state >>>>>>>>>>>>>>>> %u", (unsigned int)inInterruptionState);
            if (!appVC.recorder.isRecording && appVC.hasInterruptedWhenRecording) {
                [appVC recordOrPause:nil];
                NSLog(@"resume record");
                appVC.hasInterruptedWhenRecording = NO;
            }
        }
    }
}

//route change callback
void audioRouteChangeListenerCallback (void                    *inUserData,
                                       AudioSessionPropertyID  inPropertyID,
                                       UInt32                  inPropertyValueS,
                                       const void              *inPropertyValue)
{
    ViewController *vc = (__bridge ViewController *)(inUserData);
    if ([vc isHeadsetPluggedIn]) {
        NSLog(@"耳机插入");
        if (!vc.hasHeadset) {
            vc.hasHeadset = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [vc.statusView showWithText:@"耳机已插入"];
            });
        }
        
    }
    else {
        NSLog(@"启用扬声器模式");
        vc.hasHeadset = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [vc.statusView showWithText:@"启用扬声器模式"];
        });
    }
}

// check whether headset is plugged in
- (BOOL)isHeadsetPluggedIn {
#if TARGET_IPHONE_SIMULATOR
#warning *** Simulator mode: audio session code works only on a device
    return NO;
#else
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription *desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            return YES;
        }
    }
    return NO;
#endif
}


@end
