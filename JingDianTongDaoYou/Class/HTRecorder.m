//
//  HTRecorder.m
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 16/7/9.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "HTRecorder.h"
#import "GCDAsyncUdpSocket.h"

#define kDefaultIP @"234.5.6.1"
#define kDefaultPort 8090

@interface HTRecorder () <GCDAsyncUdpSocketDelegate>

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (strong, nonatomic) RecordAmrCode *recordAmrCode;

@end

@implementation HTRecorder

- (RecordAmrCode *)recordAmrCode{
    if (_recordAmrCode == nil) {
        _recordAmrCode = [[RecordAmrCode alloc] init];
    }
    return _recordAmrCode;
}

- (instancetype) init{
    self = [super init];
    if (self){
        dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        GCDAsyncUdpSocket *udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:global];
        self.udpSocket = udpSocket;
        [self.udpSocket bindToPort:kDefaultPort error:nil];
        self.isRecording = NO;
    }
    
    return self;
}
//设置录音格式
- (void)setAudioFormat:(UInt32)inFormatID andSampleRate:(int)sampleRate{
    //重置
    memset(&_aqc.mDataFormat, 0, sizeof(_aqc.mDataFormat));
    _aqc.mDataFormat.mSampleRate = sampleRate;// 采样率 (立体声 = 8000)
    _aqc.mDataFormat.mFormatID = inFormatID;// PCM 格式 kAudioFormatLinearPCM
    _aqc.mDataFormat.mChannelsPerFrame = 1;//设置通道数 1:单声道；2:立体声
    if (inFormatID == kAudioFormatLinearPCM) {
        _aqc.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        //每个通道里，一帧采集的bit数目
        _aqc.mDataFormat.mBitsPerChannel = 16;// 语音每采样点占用位数//结果分析: 8bit为1byte，即为1个通道里1帧需要采集2byte数据，再*通道数，即为所有通道采集的byte
        _aqc.mDataFormat.mBytesPerPacket = 2;//(_recordFormat.mBitsPerChannel / 8) * _recordFormat.mChannelsPerFrame
        _aqc.mDataFormat.mFramesPerPacket = 1;//每一个packet一侦数据
    }
    _aqc.mDataFormat.mBytesPerFrame = 2;
}

//初始化会话
- (void)initSession
{
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;  //设置成话筒模式
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (audioRouteOverride),
                             &audioRouteOverride);
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setActive:YES error:nil];
    
}

void inputBufferHandler(void *inUserData, AudioQueueRef inAQ,AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, unsigned long inNumPackets, const AudioStreamPacketDescription *inPacketDesc){
    
    NSLog(@"在录音回调函数中。。。");
    
    HTRecorder *recorder = (__bridge HTRecorder *) inUserData;
    if (inNumPackets > 0) {
        NSLog(@"input buffer: %u", (unsigned int)inBuffer->mAudioDataByteSize);
        NSData *pcmData = [[NSData alloc] initWithBytes:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize];
        if (pcmData && pcmData.length > 0) {
            NSData *amrData = [recorder.recordAmrCode encodePCMDataToAMRData:pcmData];
            if (recorder.isRecording) {
                [recorder.udpSocket sendData:amrData toHost:kDefaultIP port:kDefaultPort withTimeout:-1 tag:0];
                pcmData = nil;
                amrData = nil;
            }
        }
    }
    if (recorder.isRecording) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

//开始录音
- (void)startRecording{
    //设置录音格式
    [self setAudioFormat:kAudioFormatLinearPCM andSampleRate:kSamplingRate];
    //初始化会话
    [self initSession];
    //创建一个录制音频队列
    AudioQueueNewInput(&_aqc.mDataFormat, (void *)inputBufferHandler, (__bridge void * _Nullable)(self), NULL, NULL, 0, &_aqc.queue);

    //创建录制音频队列缓冲区
    for (int i = 0; i < kNumberBuffers; i++) {
        AudioQueueAllocateBuffer(_aqc.queue, kDefaultInputBufferSize, &_aqc.mBuffers[i]);
        AudioQueueEnqueueBuffer(_aqc.queue, _aqc.mBuffers[i], 0, NULL);//将 _audioBuffers[i]添加到队列中
    }
    // 开启录制队列
    AudioQueueStart(_aqc.queue, NULL);
    self.isRecording = YES;
}

- (void)startAudioRecording{
   
}

//停止录音
-(void)stopRecording{
    
    NSLog(@"stop recording out\n");
    if (self.isRecording){
        self.isRecording = NO;
        
        //停止录音队列和移除缓冲区,以及关闭session，这里无需考虑成功与否
//        AudioQueueStop(_aqc.queue, true);
////        AudioQueueDispose(_aqc.queue, YES);
//        [[AVAudioSession sharedInstance] setActive:NO error:nil];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    NSLog(@"发送数据");
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    NSLog(@"发送数据 Error");
}




@end
