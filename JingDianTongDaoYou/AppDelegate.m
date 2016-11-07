//
//  AppDelegate.m
//  JingDianTongDaoYou
//
//  Created by 黄启明 on 16/7/8.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <AudioToolbox/AudioSession.h>

@interface AppDelegate ()

@property (nonatomic, strong) ViewController *vc;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.vc = [[ViewController alloc] init];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = self.vc;
    
    [self.window makeKeyAndVisible];
    
    //来电监听
    AudioSessionInitialize(NULL, NULL, interruptionListenner, (__bridge void *)(self));
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

void interruptionListenner(void *inClientData, UInt32 inInterruptionState) {
    AppDelegate *app = (__bridge AppDelegate *)(inClientData);
    if (app) {
        
        if (kAudioSessionBeginInterruption == inInterruptionState) {
            NSLog(@"interruptionListenner state =========================== %u", (unsigned int)inInterruptionState);
            [app.self.vc recordOrPause:nil];
        }
        else {
            NSLog(@"interruptionListenner state ------------ %u", (unsigned int)inInterruptionState);
            [app.self.vc recordOrPause:nil];
        }
    }
}

@end
