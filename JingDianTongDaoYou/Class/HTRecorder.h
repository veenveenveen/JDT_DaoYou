//
//  HTRecorder.h
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 16/7/9.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "GCDAsyncUdpSocket.h"

//定义的三个缓冲区
#define kNumberBuffers 3
//采样率为8000
#define kSamplingRate 8000
#define kDefaultInputBufferSize 640//1200、960，1920，320,640
#define FRAME_SIZE 160 // PCM音频8khz*20ms -> 8000*0.02=160
//ip地址
#define kDefaultIP @"234.5.6.1"
//#define kDefaultIP @"255.255.255.255"
//#define kDefaultIP @"172.16.78.138"
//端口号
#define kDefaultPort 9081
//#define kDefaultPort 8090
//#define kDefaultPort 5760
//#define kDefaultPort 5761

@interface HTRecorder: NSObject <GCDAsyncUdpSocketDelegate>

@property (nonatomic, assign) BOOL isRecording;

- (void)startRecording;

- (void)stopRecording;

@end
