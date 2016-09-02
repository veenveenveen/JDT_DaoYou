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
#import "RecordAmrCode.h"

//定义的三个缓冲区
#define kNumberBuffers 3
//采样率为8000
#define kSamplingRate 8000

#define kDefaultInputBufferSize 7360

typedef struct AQCallbackStruct{
    AudioStreamBasicDescription mDataFormat;//音频流描述对象  格式化音频数据
    AudioQueueRef               queue;//音频队列
    AudioQueueBufferRef         mBuffers[kNumberBuffers];//数据缓冲
    AudioFileID                 outputFile;
    UInt32                      frameSize;
} AQCallbackStruct;

@interface HTRecorder : NSObject

@property (nonatomic, assign) AQCallbackStruct aqc;

@property (nonatomic, assign) BOOL isRecording;

- (void)startRecording;

- (void)stopRecording;

@end
