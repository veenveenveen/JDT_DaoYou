//
//  HTEchoCancel.m
//  JingDianTongYouKe
//
//  Created by 黄启明 on 2016/11/4.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "HTEchoCanceller.h"

@implementation HTEchoCanceller {
    
    
    SpeexEchoState *echoState;
    SpeexPreprocessState *preprocessState;
    
    /* 初始化回音消除参数
     *  frameSize      帧长      一般都是  80,160,320
     *  filterLen      尾长      一般都是  80*25 ,160*25 ,320*25
     *  sampleRate     采样频率   一般都是  8000，16000，32000
     * 比如初始化
     *  InitAudioAEC(80, 80*25,8000)   //8K，10毫秒采样一次
     *  InitAudioAEC(160,160*25,16000) //16K，10毫秒采样一次
     *  InitAudioAEC(320,320*25,32000) //32K，10毫秒采样一次
     */
    int frameSize;
    int filterLen;
    int sampleRate;
    
//    int sampleTimeLong;//采样时长
    
    int arg;
    
    int *pNoise;
}

#pragma mark - life circle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initWithFrameSize:160 andFilterLength:80*25 andSampleRate:8000];
    }
    return self;
}

- (void)dealloc {
    speex_echo_state_destroy(echoState);
    speex_echo_state_reset(echoState);
}

- (void)initWithFrameSize:(int)size andFilterLength:(int)length andSampleRate:(int)rate {
    if (size <= 0 || length <= 0 || rate <= 0){
        frameSize = 160;
        filterLen = 80*25;
        sampleRate = 8000;
    }
    else{
        frameSize = size;
        filterLen = length;
        sampleRate = rate;
    }
    
    //计算采样时长，即是10毫秒，还是20毫秒，还是30毫秒
//    sampleTimeLong = (frameSize / (sampleRate / 100)) * 10;
    

    echoState = speex_echo_state_init(frameSize, filterLen);
    
    preprocessState = speex_preprocess_state_init(frameSize, sampleRate);
    
    arg = sampleRate;
    
    speex_echo_ctl(echoState, SPEEX_ECHO_SET_SAMPLING_RATE, &arg);
    
    speex_preprocess_ctl(preprocessState, SPEEX_PREPROCESS_SET_ECHO_STATE, echoState);
}

#pragma mark - 回声消除方法

- (NSData *)doEchoCancellationWith:(NSData *)new and:(NSData *)old {
    
    
    short input_frame[160];
    
    short echo_frame[160];
    
    short output_frame[160];
    
    NSUInteger packetSize = 160 * sizeof(short);
    
    NSData *newdata = nil;
    NSData *olddata = nil;
    
    NSMutableData *outputData = [NSMutableData data];
    
    for (NSUInteger i=0; i<new.length; i=i+packetSize) {
        
        NSUInteger remain = new.length - i;
        
        if (remain < packetSize) {
            newdata = [new subdataWithRange:NSMakeRange(i, remain)];
            olddata = [old subdataWithRange:NSMakeRange(i, remain)];
        } else {
            newdata = [new subdataWithRange:NSMakeRange(i, packetSize)];
            olddata = [old subdataWithRange:NSMakeRange(i, packetSize)];
        }
        
        memcpy(input_frame, newdata.bytes, packetSize);
        memcpy(echo_frame, olddata.bytes, packetSize);
        speex_echo_cancel(echoState, input_frame, echo_frame, output_frame, NULL);
        speex_preprocess_run(preprocessState, output_frame);
        [outputData appendBytes:output_frame length:packetSize];
    }
    
    return outputData;
}

@end
