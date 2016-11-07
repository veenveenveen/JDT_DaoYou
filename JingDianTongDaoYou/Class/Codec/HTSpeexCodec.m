//
//  HTSpeexCodec.m
//  JingDianTongYouKe
//
//  Created by 黄启明 on 2016/11/4.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "HTSpeexCodec.h"

@implementation HTSpeexCodec {
    int enc_frame_size;//压缩时的帧大小
    int dec_frame_size;//解压时的帧大小
    
    void *enc_state;
    SpeexBits ebits;
    
    void *dec_state;
    SpeexBits dbits;
}

#pragma mark - life circle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self speexEncodeInit];
        [self speexDecodeInit];
    }
    return self;
}

-(void)dealloc {
    [self speexEncodeDestroy];
    [self speexDecodeDestroy];
}

#pragma mark - 编码器和解码器 初始化 和 销毁 方法

//初始化编码器
- (void)speexEncodeInit{
    int quality = 4;
    
    enc_state = speex_encoder_init(&speex_nb_mode);
    
    speex_encoder_ctl(enc_state, SPEEX_SET_QUALITY, &quality);
    speex_encoder_ctl(enc_state, SPEEX_GET_FRAME_SIZE, &enc_frame_size);
    
    speex_bits_init(&ebits);
}
//销毁编码器
- (void)speexEncodeDestroy{
    speex_encoder_destroy(enc_state);
    speex_bits_destroy(&ebits);
}
//初始化解码器
- (void)speexDecodeInit{
    int enh = 1;
    
    dec_state = speex_decoder_init(&speex_nb_mode);
    
    speex_decoder_ctl(dec_state, SPEEX_GET_FRAME_SIZE, &dec_frame_size);
    speex_decoder_ctl(dec_state, SPEEX_SET_ENH, &enh);
    
    speex_bits_init(&dbits);
}
//销毁解码器
- (void)speexDecodeDestroy{
    speex_decoder_destroy(dec_state);
    speex_bits_destroy(&dbits);
}


#pragma mark - api methods

//编码
- (NSData *)encodeToSpeexDataFromData:(NSData *)pcmData {
    
    NSMutableData *encodedData = [NSMutableData data];//用于保存编码后的数据
    
    short input_frame[enc_frame_size];
    char cbits[200];
    int nbBytes;
    NSUInteger packetSize = enc_frame_size * sizeof(short);
    
    NSData *data = nil;
    
    for (NSUInteger i=0; i<pcmData.length; i=i+packetSize) {
        NSUInteger remain = pcmData.length - i;
        
        if (remain < packetSize) {
            data = [pcmData subdataWithRange:NSMakeRange(i, remain)];
        } else {
            data = [pcmData subdataWithRange:NSMakeRange(i, packetSize)];
        }
        memcpy(input_frame, data.bytes, packetSize);
    
        //encode data
        
        speex_bits_reset(&ebits);
        
        speex_encode_int(enc_state, input_frame, &ebits);
        
        nbBytes = speex_bits_write(&ebits, cbits, 200);
        
        [encodedData appendBytes:cbits length:nbBytes];
        
    }
    
    return encodedData;

}

//解码
- (NSData *)decodeToPcmDataFromData: (NSData *)speexData {
    NSMutableData *decodedData = [NSMutableData data];
    
    short output_frame[dec_frame_size];
    
    NSUInteger perSize = 20 * sizeof(char);
    
    NSData *data = nil;
    
    for (NSUInteger i=0; i<speexData.length; i=i+perSize) {
        NSUInteger remain = speexData.length - i;
        
        if (remain < perSize) {
            data = [speexData subdataWithRange:NSMakeRange(i, remain)];
        } else {
            data = [speexData subdataWithRange:NSMakeRange(i, perSize)];
        }
        
        //decode data
        
        speex_bits_read_from(&dbits, (char *)data.bytes, (int)perSize);
        speex_decode_int(dec_state, &dbits, output_frame);
        
        [decodedData appendBytes:output_frame length:sizeof(short) * dec_frame_size];
    }
    
    return decodedData;
    
}

@end
