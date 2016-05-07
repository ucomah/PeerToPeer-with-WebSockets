//
//  MEServiceFinder.h
//  Amarant-TestTool
//
//  Created by Evgeniy Melkov on 14.05.14.
//  Copyright (c) 2014 Evgeniy Melkov. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SERVICEFINDER_LOGGING_ENABLED 1

@class MEServiceFinder;
@class MEService;

@protocol MEServiceFinderDelegate <NSObject>

- (void)findServices:(MEServiceFinder*)theFindServices didFindService:(MEService*)theService;
- (void)findServices:(MEServiceFinder*)theFindServices didLoseService:(MEService*)theService;
- (void)findServices:(MEServiceFinder*)theFindServices didFailToSearch:(NSDictionary *)theErrors;

@end



@interface MEServiceFinder : NSObject

@property (weak) id<MEServiceFinderDelegate>delegate;

- (instancetype)initWithType:(NSString*)theType andDomain:(NSString*)theDomain;
- (void)start;
- (void)stop;
- (NSDictionary*)allFoundServices;

@end








@interface MEService : NSNetService

@property (nonatomic, strong) NSString* ipAddress;

@end