//
//  HTShowStatusView.m
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 2016/11/9.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "HTShowStatusView.h"

#define VIEW_W 240
#define VIEW_H 55

@interface HTShowStatusView ()

@property (nonatomic, strong) UIView *displayView;
@property (nonatomic, strong) UILabel *displayLable;

@end

@implementation HTShowStatusView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.displayView = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width-VIEW_W)*0.5, (frame.size.height-VIEW_H)*0.5, VIEW_W, VIEW_H)];
        [self setupDisplayView];
    }
    return self;
}

- (void)setupDisplayView {
    //毛玻璃效果
    //UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    //UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    //visualEffectView.frame = self.displayView.bounds;
    //visualEffectView.alpha = 0.98;
    //[self.displayView addSubview:visualEffectView];
    
    self.displayView.alpha = 0;
    
    self.displayView.layer.cornerRadius = 10;
    self.displayView.layer.masksToBounds = YES;
    
    self.displayView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:0.3];
    
    [self addSubview:self.displayView];
    
    self.displayLable = [[UILabel alloc] init];
    self.displayLable.frame = CGRectMake((self.displayView.frame.size.width-200)*0.5, (self.displayView.frame.size.height-50)*0.5, 200, 50);
    self.displayLable.textColor = [UIColor blackColor];
    self.displayLable.textAlignment = NSTextAlignmentCenter;
    self.displayLable.font = [UIFont systemFontOfSize:20];
    [self.displayView addSubview:self.displayLable];
}

- (void)showWithText:(NSString *)text {
    self.displayLable.text = text;
    [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.displayView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1 delay:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.displayView.alpha = 0;
        } completion:nil];
    }];
}


@end
