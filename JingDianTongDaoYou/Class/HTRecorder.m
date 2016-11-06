//
//  HTRecorder.m
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 16/7/9.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "HTRecorder.h"
#import "HTSpeexCodec.h"

@implementation HTRecorder {
    AudioStreamBasicDescription mDataFormat;//音频流描述对象  格式化音频数据
    AudioQueueRef               inputQueue;//音频队列
    AudioQueueBufferRef         inputBuffers[kNumberBuffers];//数据缓冲
    
    OSStatus errorStatus;
    
    dispatch_queue_t _encode_send_queue;
    
    GCDAsyncUdpSocket *udpSocket;
    HTSpeexCodec *spxCodec;
}

#pragma mark - life cycle

- (instancetype) init{
    self = [super init];
    if (self){
        
        self.isRecording = NO;
        
        spxCodec = [[HTSpeexCodec alloc] init];
        
        _encode_send_queue = dispatch_queue_create("com.JDKDaoYou.sendData", DISPATCH_QUEUE_SERIAL);
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:_encode_send_queue];
        
        NSError *error = nil;
        [udpSocket bindToPort:kDefaultPort error:&error];
        if (error != nil) {
            NSLog(@"error: %@",error.description);
        }
        
        [self setupAudioRecording];
     
    }
    return self;
}

- (void)dealloc {
    [udpSocket close];
    
    spxCodec = nil;
    udpSocket = nil;
    _encode_send_queue = nil;
}


#pragma mark - input callback

void inputCallback(void                               *inUserData,
                   AudioQueueRef                      inAQ,
                   AudioQueueBufferRef                inBuffer,
                   const AudioTimeStamp               *inStartTime,
                   unsigned long                      inNumPackets,
                   const AudioStreamPacketDescription *inPacketDesc)
{
    HTRecorder *recorder = (__bridge HTRecorder *) inUserData;
    
    if (inNumPackets > 0) {
        [recorder inputDataHandler:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize];
    }
    
    OSStatus errorStatus = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    if (errorStatus) {
        NSLog(@"MyInputBufferHandler error:%d", (int)errorStatus);
        return;
    }
}

- (void)inputDataHandler:(void *)bytes length:(UInt32)len {
    NSData *input = [NSData dataWithBytes:bytes length:len];
    
    NSData *speexData = [spxCodec encodeToSpeexDataFromData:input];
    
    [udpSocket sendData:speexData toHost:kDefaultIP port:kDefaultPort withTimeout:-1 tag:0];
}

#pragma mark - setup AudioQueue

- (void)setupAudioRecording{
    
    //设置录音格式
    [self setupAudioFormat:kAudioFormatLinearPCM andSampleRate:kSamplingRate];
    
    //创建一个录制音频队列
    errorStatus = AudioQueueNewInput(&mDataFormat, (void *)inputCallback, (__bridge void * _Nullable)(self), NULL, NULL, 0, &inputQueue);
    if (errorStatus) {
        NSLog(@"error:%d when AudioQueueNewInput ", (int)errorStatus);
    }
    
    //需要一个更具体的流描述,以创建编码器
    UInt32 size;
    size = sizeof(mDataFormat);
    errorStatus = AudioQueueGetProperty(inputQueue, kAudioQueueProperty_StreamDescription, &mDataFormat, &size);
    if (errorStatus) {
        NSLog(@"error:%d when AudioQueueGetProperty StreamDescription", (int)errorStatus);
    }
    UInt32 val = 1;
    errorStatus = AudioQueueSetProperty(inputQueue, kAudioQueueProperty_EnableLevelMetering, &val, sizeof(val));
    if (errorStatus) {
        NSLog(@"error:%d when AudioQueueGetProperty LevelMetering", (int)errorStatus);
    }
    
    //创建并分配音频队列缓冲区
    //    bufferByteSize = [self computeRecordBufferSizeWith:&mDataFormat and:kBufferDurationSeconds];
    for (int i = 0; i < kNumberBuffers; i++) {
        //        AudioQueueAllocateBuffer(_aqc.queue, bufferByteSize, &inputBuffers[i]); // kDefaultInputBufferSize
        AudioQueueAllocateBuffer(inputQueue, kDefaultInputBufferSize, &inputBuffers[i]); // kDefaultInputBufferSize
        AudioQueueEnqueueBuffer(inputQueue, inputBuffers[i], 0, NULL);//将 _audioBuffers[i]添加到队列中
    }
    
}

//设置录音格式
- (void)setupAudioFormat:(UInt32)inFormatID andSampleRate:(int)sampleRate{
    memset(&mDataFormat, 0, sizeof(mDataFormat));//重置
    mDataFormat.mSampleRate = sampleRate;// 采样率 (立体声 = 8000)
    mDataFormat.mFormatID = inFormatID;// PCM 格式 kAudioFormatLinearPCM
    mDataFormat.mChannelsPerFrame = 1;//设置通道数 1:单声道；2:立体声
    mDataFormat.mBytesPerFrame = 2;//每个通道里，一帧采集的bit数目
    mDataFormat.mBitsPerChannel = 16;// 语音每采样点占用位数/
    mDataFormat.mBytesPerPacket = 2;//mBitsPerChannel / 8 * mChannelsPerFrame
    mDataFormat.mFramesPerPacket = 1;  //每一个packet一帧数据
    if (inFormatID == kAudioFormatLinearPCM) {
        mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    }
}

#pragma mark - start and stop methods

//开始录音
- (void)startRecording{
    if (!self.isRecording){
        self.isRecording = YES;
        //开启录制队列
        errorStatus = AudioQueueStart(inputQueue, NULL);
        if (errorStatus) {
            NSLog(@"StartRecord error:%d", (int)errorStatus);
        }
    }
}
//停止录音
-(void)stopRecording{
    if (self.isRecording){
        self.isRecording = NO;
        
        [udpSocket close];
        //暂停录制队列
        AudioQueuePause(inputQueue);
    }
}

#pragma mark - Socket delegate method

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    //NSLog(@"发送数据");
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    NSLog(@"发送数据 Error");
}

@end
