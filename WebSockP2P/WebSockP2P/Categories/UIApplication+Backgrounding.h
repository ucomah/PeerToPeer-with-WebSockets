//
//  UIApplication+Backgrounding.h
//
//  Created by Evgeniy Melkov on 04.12.14.
//  Copyright (c) 2014 Evgeniy Melkov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Backgrounding)

- (void)startFineLengthBackgroundBlock:(void(^)())backgroundBlock;
- (BOOL)backgroundTaskActive;
- (void)logBackgroundTask;
- (void)stopFineLengthBackground;
- (BOOL)isAppInBackground;

@end
