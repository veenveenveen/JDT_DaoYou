//
//  HTVoiceCodec.m
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 2016/11/3.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "HTVoiceCodec.h"

@implementation HTVoiceCodec
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
- (void)voice_encode_init{
    int quality = 8;
    speex_bits_init(&ebits);
    enc_state = speex_encoder_init(&speex_nb_mode);
    speex_encoder_ctl(enc_state, SPEEX_SET_QUALITY, &quality);
    speex_encoder_ctl(enc_state, SPEEX_GET_FRAME_SIZE, &enc_frame_size);
    is_enc_init = YES;
}
//销毁压缩器
- (void)voice_encode_release{
    speex_bits_destroy(&ebits);
    speex_encoder_destroy(enc_state);
    is_enc_init = NO;
}
//初始化解压器
- (void)voice_decode_init{
    int enh = 1;
    speex_bits_init(&dbits);
    dec_state = speex_decoder_init(&speex_nb_mode);
    speex_decoder_ctl(dec_state, SPEEX_GET_FRAME_SIZE, &dec_frame_size);
    speex_decoder_ctl(dec_state, SPEEX_SET_QUALITY, &enh);
    is_dec_init = YES;
}
//销毁解压器
- (void)voice_decode_release{
    speex_bits_destroy(&dbits);
    speex_decoder_destroy(dec_state);
}
/*
 * 压缩编码
 * short lin[] 语音数据
 * int size 语音数据长度
 * char encoded[] 编码后保存数据的数组
 * int max_buffer_size 保存编码数据数组的最大长度
 */
- (int)voice_encode:(short *)lin andSize:(int)size toNew:(char *)encoded and:(int) max_buffer_size{
    if (!is_enc_init) {
        [self voice_encode_init];
    }
    short buffer[enc_frame_size];
    char output_buffer[1024+4];
    int n_samples = (size-1) / (enc_frame_size+1);
    int tot_bytes = 0;
    for (int i = 0; i < n_samples; i++) {
        speex_bits_reset(&ebits);
        memcpy(buffer, lin + i * enc_frame_size, enc_frame_size * sizeof(short));
        speex_encode_int(enc_state, buffer, &ebits);
        int nbBytes = speex_bits_write(&ebits, output_buffer + 4, 1024 - tot_bytes);
        int len = max_buffer_size >= tot_bytes + nbBytes + 4 ? nbBytes + 4 : max_buffer_size - tot_bytes;
        memcpy(encoded + tot_bytes, output_buffer, len * sizeof(char));
        tot_bytes += nbBytes + 4;
    }
    return tot_bytes;
}
/*
 * 解码
 * char encoded[] 编码后的语音数据
 * int size 编码后的语音数据的长度
 * short output[] 解码后的语音数据
 * int max_buffer_size 保存解码后的数据的数组的最大长度
 */
- (int)voice_decode:(char *)encoded andSize:(int)size toNew:(short *)output and:(int)max_buffer_size{
    if (!is_dec_init) {
        [self voice_decode_init];
    }
    char *buffer = encoded;
    short output_buffer[1024];
    int encoded_length = size;
    int decoded_length = 0;
    int i;
    for (i = 0; decoded_length < encoded_length; ++i) {
        speex_bits_reset(&dbits);
        int nbBytes = *(int*)(buffer + decoded_length);
        speex_bits_read_from(&dbits, (char *)buffer + decoded_length + 4,
                             nbBytes);
        speex_decode_int(dec_state, &dbits, output_buffer);
        decoded_length += nbBytes + 4;
        int len = (max_buffer_size >= dec_frame_size * (i + 1)) ?
        dec_frame_size : max_buffer_size - dec_frame_size * i;
        memcpy(output + dec_frame_size * i, output_buffer, len * sizeof(short));
    }
    return dec_frame_size * i;
}

@end
