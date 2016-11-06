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
/*
 * 编码
 * pcmData 需要编码的语音数据
 * return 编码后的语音数据
 */
- (NSData *)encodeToSpeexDataFromData:(NSData *)pcmData;
/*
 * 解码
 * speexData 需要解码的语音数据
 * return 解码后的语音数据
 */
- (NSData *)decodeToPcmDataFromData: (NSData *)speexData;
@end
