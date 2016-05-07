//
//  UIApplication+Backgrounding.m
//
//  Created by Evgeniy Melkov on 04.12.14.
//  Copyright (c) 2014 Evgeniy Melkov. All rights reserved.
//

#import "UIApplication+Backgrounding.h"

@implementation UIApplication (Backgrounding)

static UIBackgroundTaskIdentifier bgTaskId;

- (void)startFineLengthBackgroundBlock:(void(^)())backgroundBlock
{
    if (floorf([UIDevice currentDevice].systemVersion.floatValue) >= 7) {
        switch ([[UIApplication sharedApplication] backgroundRefreshStatus]) {
            case UIBackgroundRefreshStatusRestricted:
                NSLog(@"Background updates are unavailable and the user cannot enable them again.");
                return;
                break;
                
            case UIBackgroundRefreshStatusDenied:
                NSLog(@"The user explicitly disabled background behavior for this app or for the whole system.");
                return;
                break;
            case UIBackgroundRefreshStatusAvailable: //all fine :)
                break;
        }
    }
    
    if (!backgroundBlock) {
        NSLog(@"No backgroundBlock!");
        return;
    }
    
    if ([self backgroundTaskActive]) {
        NSLog(@"BackgroundTask already started");
        return;
    }
    
//    if (bgTaskId != UIBackgroundTaskInvalid) {
//        NSLog(@"Background queue restarting...");
//        bgTaskId = UIBackgroundTaskInvalid;
//    }
    
    bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (bgTaskId != UIBackgroundTaskInvalid)
        {
            [[UIApplication sharedApplication] endBackgroundTask:bgTaskId];
            bgTaskId = UIBackgroundTaskInvalid;
        }
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), backgroundBlock);
}

- (BOOL)backgroundTaskActive
{
    return bgTaskId != UIBackgroundTaskInvalid;
}

- (void)logBackgroundTask
{
    if ([[UIApplication sharedApplication] isAppInBackground]) {
        NSTimeInterval timeLeft = [UIApplication sharedApplication].backgroundTimeRemaining;
        NSLog(@"Background time remaining: %f", timeLeft);
    }
    else {
        NSLog(@"I'm in foreground");
    }
}

- (void)stopFineLengthBackground
{
    NSLog(@"Stopping background queue...");
    [[UIApplication sharedApplication] endBackgroundTask:bgTaskId];
    bgTaskId = UIBackgroundTaskInvalid;
}

- (BOOL)isAppInBackground
{
    return [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground;
}

@end
