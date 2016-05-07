//
//  EMNetUtils.h
//  LightSpeed
//
//  Created by Evgeniy Melkov on 09.12.14.
//  Copyright (c) 2014 Evgeniy Melkov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetUtils : NSObject

+ (void)clearAppCookies;
+ (void)dumpCookies:(NSString *)msgOrNil;

+ (NSString *)hostname;
+ (NSString *)localIPAddress;
+ (NSString*)getPublicIP;

@end
