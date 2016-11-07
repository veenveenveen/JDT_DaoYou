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
    
    int frameSize;
    int filterLen;
    int sampleRate;
    
    int *pNoise;
}

#pragma mark - life circle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initWithFrameSize:160 andFilterLength:160*8 andSampleRate:8000];
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
        filterLen = 160*8;
        sampleRate = 8000;
    }
    else{
        frameSize = size;
        filterLen = length;
        sampleRate = rate;
    }
    echoState = speex_echo_state_init(frameSize, filterLen);
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
        [outputData appendBytes:output_frame length:packetSize];
    }
    
    return outputData;
}

@end
