//
//  UIApplication+TopMostController.m
//  Musicam
//
//  Created by Evgeniy Melkov on 15.04.16.
//  Copyright © 2016 Ellisa. All rights reserved.
//

#import "UIApplication+TopMostController.h"

@implementation UIApplication (TopMostController)

- (UIViewController*)topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

@end
