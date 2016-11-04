//
//  HTRecorder.m
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 16/7/9.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "HTRecorder.h"
#import "GCDAsyncUdpSocket.h"
#import "SpeexCodec.h"
#import "HTSpeexCodec.h"

#define kDefaultIP @"234.5.6.1"
//#define kDefaultIP @"255.255.255.255"
//#define kDefaultIP @"172.16.78.138"

//#define kDefaultPort 8090
//#define kDefaultPort 5760
//#define kDefaultPort 5761
#define kDefaultPort 9081


@interface HTRecorder () <GCDAsyncUdpSocketDelegate>
{
    NSMutableData *tempData;    //用于输入的pcm切割剩余
    NSMutableArray *pcmDatas;//保存切割的pcm数据块
    NSMutableData *speexData;//保存编码后的数据
    OSStatus errorStatus;
    
    SpeexCodec *codec;
    
    char encoded[FRAME_SIZE * 2];
    short decoded[FRAME_SIZE];
    
    size_t encoded_count;
    size_t decoded_count;
    
}

@property dispatch_queue_t m_queue;

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;

@property (nonatomic, strong) HTSpeexCodec *spxCodec;

//@property (nonatomic, strong) NSData *pcmData;

- (NSMutableArray *)getPCMDatas;

@end

@implementation HTRecorder

- (instancetype) init{
    self = [super init];
    if (self){
        _m_queue = dispatch_queue_create("com.JDKDaoYou.encode", DISPATCH_QUEUE_SERIAL);
        
        dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:global];
        NSError *error;
        [self.udpSocket bindToPort:kDefaultPort error:&error];
        if (error != nil) {
            NSLog(@"error: %@",error.description);
        }
        [self initAudioRecording];
        self.isRecording = NO;
        
        codec = [[SpeexCodec alloc] init];
        pcmDatas = [[NSMutableArray alloc] init];
        tempData = [[NSMutableData alloc] init];
        
        _spxCodec = [[HTSpeexCodec alloc] init];
        
    }
    return self;
}
- (void)initAudioRecording{
//    int bufferByteSize;
    UInt32 size;
    //设置录音格式
    [self setAudioFormat:kAudioFormatLinearPCM andSampleRate:kSamplingRate];
    //创建一个录制音频队列
    errorStatus = AudioQueueNewInput(&_aqc.mDataFormat, (void *)inputBufferHandler, (__bridge void * _Nullable)(self), NULL, NULL, 0, &_aqc.queue);
    if (errorStatus) {
        NSLog(@"error:%d when AudioQueueNewInput ", (int)errorStatus);
    }
    //需要一个更具体的流描述,以创建编码器
    //    mRecordPacket = 0;
    size = sizeof(_aqc.mDataFormat);
    errorStatus = AudioQueueGetProperty(_aqc.queue, kAudioQueueProperty_StreamDescription, &_aqc.mDataFormat, &size);
    if (errorStatus) {
        NSLog(@"error:%d when AudioQueueGetProperty StreamDescription", (int)errorStatus);
    }
    
    UInt32 val = 1;
    errorStatus = AudioQueueSetProperty(_aqc.queue, kAudioQueueProperty_EnableLevelMetering, &val, sizeof(val));
    if (errorStatus) {
        NSLog(@"error:%d when AudioQueueGetProperty LevelMetering", (int)errorStatus);
    }
    //创建 并 分配 音频队列缓冲区
//    bufferByteSize = [self computeRecordBufferSizeWith:&_aqc.mDataFormat and:kBufferDurationSeconds];
    for (int i = 0; i < kNumberBuffers; i++) {
        //        AudioQueueAllocateBuffer(_aqc.queue, bufferByteSize, &_aqc.mBuffers[i]); // kDefaultInputBufferSize
        AudioQueueAllocateBuffer(_aqc.queue, kDefaultInputBufferSize, &_aqc.mBuffers[i]); // kDefaultInputBufferSize
        AudioQueueEnqueueBuffer(_aqc.queue, _aqc.mBuffers[i], 0, NULL);//将 _audioBuffers[i]添加到队列中
    }
}

- (int)computeRecordBufferSizeWith:(const AudioStreamBasicDescription *)format and: (float)seconds {
    int packets, frames, bytes = 0;
    frames = (int)ceil(seconds * format->mSampleRate);
    
    if (format->mBytesPerFrame > 0)
        bytes = frames * format->mBytesPerFrame;
    else {
        UInt32 maxPacketSize;
        if (format->mBytesPerPacket > 0)
            maxPacketSize = format->mBytesPerPacket;	// constant packet size
        else {
            UInt32 propertySize = sizeof(maxPacketSize);
            errorStatus = AudioQueueGetProperty(_aqc.queue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize,
                                                &propertySize);
            if (errorStatus) {
                NSLog(@"ComputeRecordBufferSize error:%d", (int)errorStatus);
                return 0;
            }
        }
        if (format->mFramesPerPacket > 0) {
            packets = frames / format->mFramesPerPacket;
        }
        else {
            packets = frames;
        }// worst-case scenario: 1 frame in a packet
        if (packets == 0) {		// sanity check
            packets = 1;
        }
        bytes = packets * maxPacketSize;
    }
    return bytes;
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
        _aqc.mDataFormat.mFramesPerPacket = 1;  //每一个packet一侦数据
    }
    _aqc.mDataFormat.mBytesPerFrame = 2;
}

void inputBufferHandler(void                               *inUserData,
                        AudioQueueRef                      inAQ,
                        AudioQueueBufferRef                inBuffer,
                        const AudioTimeStamp               *inStartTime,
                        unsigned long                      inNumPackets,
                        const AudioStreamPacketDescription *inPacketDesc)
{
    
    @autoreleasepool {
    
        HTRecorder *recorder = (__bridge HTRecorder *) inUserData;
        
        if (inNumPackets > 0) {
            
//            dispatch_async(recorder.m_queue, ^{
            
                NSLog(@"在录音回调函数中。。。");
            
                NSData *pcmData = [NSData dataWithBytes:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize];
                
                // recorder->mRecordPacket += inNumPackets;
                NSLog(@"input buffer: %u", (unsigned int)inBuffer->mAudioDataByteSize);
                
                // encode data
                NSData *speexData = [recorder.spxCodec encodeToSpeexDataFromData:pcmData];
//                NSData *speexData = [recorder encodeDataToSpeexDataFromData: pcmData];
                
                NSLog(@"speexData length : %lu",speexData.length);
                
                [recorder.udpSocket sendData:speexData toHost:kDefaultIP port:kDefaultPort withTimeout:-1 tag:0];
//            });
        }
        
        OSStatus errorStatus = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
        if (errorStatus) {
            NSLog(@"MyInputBufferHandler error:%d", (int)errorStatus);
            return;
        }
    }
}


- (void)inputPCMDataFromBuffer:(void *)buffer size:(UInt32)dataSize {
    
    
    NSData *bufferData = [NSData dataWithBytes:buffer length:dataSize];
    
    @synchronized (pcmDatas) {
        [pcmDatas addObject:bufferData];
    }
    
    
    int packetSize = FRAME_SIZE * 2;
    @synchronized(pcmDatas) {
        
        [tempData appendBytes:buffer length:dataSize];
        
        while ([tempData length] >= packetSize) {
            @autoreleasepool {
                NSData *pcmData = [NSData dataWithBytes:[tempData bytes] length:packetSize];
                [pcmDatas addObject:pcmData];
                
                Byte *dataPtr = (Byte *)[tempData bytes];
                dataPtr += packetSize;
                tempData = [NSMutableData dataWithBytesNoCopy:dataPtr length:[tempData length] - packetSize freeWhenDone:NO];//????????????? NO
            }
        }
    }
}

- (NSData *)encodeDataToSpeexDataFromData:(NSData *)pcmData {
    
    [codec open:4];
    
    NSData *encodedData = [codec encode:(short *)[pcmData bytes] length:(int)[pcmData length]/sizeof(short)];
    
    NSLog(@"speex data length: %lu", encodedData.length);
    
    [codec close];
    
    return encodedData;
}

//不停从bufferData中获取数据构建paket
- (NSData *)encodeToSpeexData {
    speexData = nil;
    speexData = [[NSMutableData alloc] init];
    [codec open:4];     //压缩率为4
    while ([[self getPCMDatas] count] > 0) {
//        NSLog(@"pcmDatas count : %lu",(unsigned long)[[self getPCMDatas] count]);
        NSData *pcmData = [[self getPCMDatas] objectAtIndex:0];
//        NSLog(@"pcmData length === %lu",pcmData.length);
        NSData *spxData = [codec encode:(short *)[pcmData bytes] length:(int)[pcmData length]/sizeof(short)];
        
        
        short * bytes = (short *)[pcmData bytes];
        
        printf("bytes %lu :", pcmData.length);
        for (int i=0; i<pcmData.length; ++i) {
            printf("%d - ", bytes[i]);
        }
        printf("\n");
        
        
        
//        encoded_count = [voiceCodec voice_encode:pcmData.bytes andSize:pcmData.length toNew:encoded and:FRAME_SIZE * 2];
        [speexData appendBytes:spxData.bytes length:spxData.length];
        [[self getPCMDatas] removeObjectAtIndex:0];
    }
    [codec close];
    return speexData;
}

- (NSMutableArray *)getPCMDatas {
    @synchronized(pcmDatas) {
        return pcmDatas;
    }
}
//开始录音
- (void)startRecording{
    if (!self.isRecording){
        self.isRecording = YES;
        // 开启录制队列
        errorStatus = AudioQueueStart(_aqc.queue, NULL);
        if (errorStatus) {
            NSLog(@"StartRecord error:%d", (int)errorStatus);
        }
    }
}
//停止录音
-(void)stopRecording{    
    if (self.isRecording){
        [_udpSocket close];
        AudioQueuePause(_aqc.queue);
        
//        errorStatus = AudioQueueStop(_aqc.queue, true);
//        if (errorStatus) {
//            NSLog(@"StopRecord error:%d", (int)errorStatus);
//        }
//        AudioQueueDispose(_aqc.queue, true);
        
        self.isRecording = NO;
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
//    NSLog(@"发送数据");
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    NSLog(@"发送数据 Error");
}

- (void)dealloc {
    [_udpSocket close];
    _udpSocket = nil;
}

@end
