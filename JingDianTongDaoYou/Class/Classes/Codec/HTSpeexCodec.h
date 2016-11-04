//
//  HTSpeexCodec.h
//  JingDianTongYouKe
//
//  Created by 黄启明 on 2016/11/4.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpeexAllHeaders.h"

@interface HTSpeexCodec : NSObject
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
//- (void)speexEncodeInit;
//- (void)speexEncodeDestroy;
//- (void)speexDecodeInit;
//- (void)speexDecodeDestroy;
/*
 * 编码
 * pcmData 语音数据
 * return 编码后的语音数据
 */
- (NSData *)encodeToSpeexDataFromData:(NSData *)pcmData;
/*
 * 解码
 * char encoded[] 编码后的语音数据
 * int size 编码后的语音数据的长度
 * return 解码后的语音数据
 */
- (NSData *)decodeToPcmDataFromData: (NSData *)speexData;

@end
