//
//  HTSpeexCodec.m
//  JingDianTongYouKe
//
//  Created by 黄启明 on 2016/11/4.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "HTSpeexCodec.h"

@implementation HTSpeexCodec {
    
    NSMutableData  *tempData;  //用于输入的data切割剩余
    
    int enc_frame_size;//压缩时的帧大小
    int dec_frame_size;//解压时的帧大小
    
    void *enc_state;
    SpeexBits ebits;
    BOOL is_enc_init;
    
    void *dec_state;
    SpeexBits dbits;
    BOOL is_dec_init;
}
/*
 *初始化方法
 */
- (instancetype)init {
    self = [super init];
    if (self) {
        is_enc_init = NO;
        is_dec_init = NO;
        tempData = [NSMutableData data];
    }
    return self;
}
//初始化压缩器
- (void)speexEncodeInit{
    int quality = 4;//设置压缩质量
    speex_bits_init(&ebits);
    enc_state = speex_encoder_init(&speex_nb_mode);
    speex_encoder_ctl(enc_state, SPEEX_SET_QUALITY, &quality);
    speex_encoder_ctl(enc_state, SPEEX_GET_FRAME_SIZE, &enc_frame_size);
    is_enc_init = YES;
}
//销毁压缩器
- (void)speexEncodeDestroy{
    speex_bits_destroy(&ebits);
    speex_encoder_destroy(enc_state);
    is_enc_init = NO;
}
//初始化解压器
- (void)speexDecodeInit{
    //int enh = 1;
    speex_bits_init(&dbits);
    dec_state = speex_decoder_init(&speex_nb_mode);
    speex_decoder_ctl(dec_state, SPEEX_GET_FRAME_SIZE, &dec_frame_size);
    //where enh is an int with value 0 to have the enhancer disabled and 1 to have it enabled. As of 1.2-beta1, the default is now to enable the enhancer.
    //speex_decoder_ctl(dec_state, SPEEX_SET_QUALITY, &enh);
    is_dec_init = YES;
}
//销毁解压器
- (void)speexDecodeDestroy{
    speex_bits_destroy(&dbits);
    speex_decoder_destroy(dec_state);
    is_dec_init = NO;
}
//encode function
- (NSData *)encodeToSpeexDataFromData:(NSData *)pcmData {
    if (!is_enc_init) {
        [self speexEncodeInit];
    }
    
    [tempData appendData:pcmData];
    //用于保存编码后的数据
    NSMutableData *encodedData = [NSMutableData data];
    
    short *pcmSrc = (short *)[pcmData bytes];
    
    short input_frame[enc_frame_size];
    float input[enc_frame_size];
    char cbits[200];
    int nbBytes;
    
    int packetSize = enc_frame_size * sizeof(short);
    int nSamples = (int)ceil((int)tempData.length / packetSize);
    
    for (int sampleIndex = 0; sampleIndex < nSamples; sampleIndex++) {
        //清空这个结构体里所有的字节,以便编码一个新的帧
        speex_bits_reset(&ebits);
        //将数据拷贝到 input_frame 数组中
        memcpy(input_frame, pcmSrc + (sampleIndex * enc_frame_size * sizeof(short)), enc_frame_size * sizeof(short));
        //把16bits的值转化为float,以便speex库可以在上面工作
        for (int i = 0; i < enc_frame_size; i++) {
            input[i] = input_frame[i];
        }
        speex_encode(enc_state, input, &ebits);
        //对帧进行编码
        //speex_encode_int(enc_state, input_frame, &ebits);
         //把bits拷贝到一个的char型数组中
        nbBytes = speex_bits_write(&ebits, cbits, enc_frame_size);
        //获取还未编码的数据
        Byte *dataPtr = (Byte *)[tempData bytes];
        dataPtr += packetSize;
        tempData = [NSMutableData dataWithBytesNoCopy:dataPtr length:tempData.length - packetSize freeWhenDone:NO];
        
        [encodedData appendBytes:cbits length:nbBytes];
    }
    //销毁编码器
    if (is_enc_init) {
        [self speexEncodeDestroy];
    }
    return encodedData;
}
//decode function//decode function
- (NSData *)decodeToPcmDataFromData: (NSData *)speexData {
    if (!is_dec_init) {
        [self speexDecodeInit];
    }
    
    char *encoded = (char *)speexData.bytes;
    int size = (int)speexData.length;
    
    short output_frame[dec_frame_size];
    //float output[dec_frame_size];
    
    NSMutableData *decodedData = [NSMutableData data];
    
    int nSamples = (int)ceil(size / 20);
    
    for (int sampleIndex = 0; sampleIndex < nSamples; sampleIndex++) {
        
        speex_bits_read_from(&dbits, encoded + sampleIndex * 20 * sizeof(char), 20 * sizeof(char));
        
        //speex_decode(dec_state, &dbits, output);
        
        //for (int i = 0 ; i < dec_frame_size; i++) {
        //    output_frame[i]=output[i];
        //}
        
        speex_decode_int(dec_state, &dbits, output_frame);
        
        [decodedData appendBytes:output_frame length:sizeof(short) * dec_frame_size];
        
    }
    if (is_dec_init) {
        [self speexDecodeDestroy];
    }
    return decodedData;
}

@end
