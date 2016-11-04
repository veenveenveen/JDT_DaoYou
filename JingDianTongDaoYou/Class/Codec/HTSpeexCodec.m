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
    int enh = 1;
    speex_bits_init(&dbits);
    dec_state = speex_decoder_init(&speex_nb_mode);
    speex_decoder_ctl(dec_state, SPEEX_GET_FRAME_SIZE, &dec_frame_size);
    //where enh is an int with value 0 to have the enhancer disabled and 1 to have it enabled. As of 1.2-beta1, the default is now to enable the enhancer.
    speex_decoder_ctl(dec_state, SPEEX_SET_QUALITY, &enh);
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
    NSMutableData *encodedData = [NSMutableData data];
    
    int size = (int)pcmData.length / sizeof(short);
    short *pcmSrc = (short *)[pcmData bytes];
    
    short input_frame[enc_frame_size];
    char cbits[200];
    int nbBytes;
    
    speex_bits_reset(&ebits);
    
    int nSamples = (int)ceil(size / enc_frame_size);
    
    for (int sampleIndex = 0; sampleIndex < nSamples; sampleIndex++) {
        
        memcpy(input_frame, pcmSrc + (sampleIndex * enc_frame_size * sizeof(short)), enc_frame_size * sizeof(short));
        speex_encode_int(enc_state, input_frame, &ebits);
        nbBytes = speex_bits_write(&ebits, cbits, enc_frame_size);
        
        [encodedData appendBytes:cbits length:nbBytes];
        
    }
    
    if (is_enc_init) {
        [self speexEncodeDestroy];
    }
    
    return encodedData;
}
//decode function
- (NSData *)decodeToPcmDataFromData: (NSData *)speexData {
    if (!is_dec_init) {
        [self speexDecodeInit];
    }
    
    NSMutableData *decodedData = [NSMutableData data];
    
    char *encoded = (char *)speexData.bytes;
    int size = (int)speexData.length;
    
    short decodedSrc[1024];
    
    speex_bits_read_from(&dbits, encoded, size);
    
    int a = speex_decode_int(dec_state, &dbits, decodedSrc);
    
    [decodedData appendBytes:decodedSrc length:sizeof(short) * dec_frame_size];
    if (is_dec_init) {
        [self speexDecodeDestroy];
    }
    
    return decodedData;
}

@end
