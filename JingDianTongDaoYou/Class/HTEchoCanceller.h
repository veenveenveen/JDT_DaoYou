//
//  HTEchoCancel.h
//  JingDianTongYouKe
//
//  Created by 黄启明 on 2016/11/4.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "speex_echo.h"
#include "speex_preprocess.h"

@interface HTEchoCanceller : NSObject

- (NSData *)doEchoCancellationWith:(NSData *)new and:(NSData *)old;

@end
