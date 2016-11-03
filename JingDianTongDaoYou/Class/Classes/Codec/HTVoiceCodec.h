//
//  HTVoiceCodec.h
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 2016/11/3.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpeexAllHeaders.h"

@interface HTVoiceCodec : NSObject
{
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
 * 初始化和销毁
 */
- (void)voice_encode_init;
- (void)voice_encode_release;
- (void)voice_decode_init;
- (void)voice_decode_release;
/*
 * 压缩编码
 * short lin[] 语音数据
 * int size 语音数据长度
 * char encoded[] 编码后保存数据的数组
 * int max_buffer_size 保存编码数据数组的最大长度
 */
- (int)voice_encode:(short *)lin andSize:(int)size toNew:(char *)encoded and:(int) max_buffer_size;
/*
 * 解码
 * char encoded[] 编码后的语音数据
 * int size 编码后的语音数据的长度
 * short output[] 解码后的语音数据
 * int max_buffer_size 保存解码后的数据的数组的最大长度
 */
- (int)voice_decode:(char *)encoded andSize:(int)size toNew:(short *)output and:(int)max_buffer_size;

@end
