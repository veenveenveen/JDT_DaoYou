//
//  HTRecorder.h
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 16/7/9.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioFile.h>

//定义的三个缓冲区
#define kNumberBuffers 3
//采样率为8000
#define kSamplingRate 8000

#define kDefaultInputBufferSize 320//1200
//#define kDefaultInputBufferSize 18000//1200

//#define kBufferDurationSeconds 0.5

#define FRAME_SIZE 160 // PCM音频8khz*20ms -> 8000*0.02=160

typedef struct AQCallbackStruct{
    AudioStreamBasicDescription mDataFormat;//音频流描述对象  格式化音频数据
    AudioQueueRef               queue;//音频队列
    AudioQueueBufferRef         mBuffers[kNumberBuffers];//数据缓冲
} AQCallbackStruct;

@interface HTRecorder : NSObject

@property (nonatomic, assign) AQCallbackStruct aqc;

@property (nonatomic, assign) BOOL isRecording;

- (void)startRecording;

- (void)stopRecording;

@end
