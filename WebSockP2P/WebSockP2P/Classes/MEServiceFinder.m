//
//  MEServiceFinder.m
//
//  Created by Evgeniy Melkov on 14.05.14.
//  Copyright (c) 2014 Evgeniy Melkov. All rights reserved.
//

#import "MEServiceFinder.h"

#import <netinet/in.h>
#import <arpa/inet.h>


#if SERVICEFINDER_LOGGING_ENABLED
#define SFLog( s, ... ) NSLog( @"%@: %@", NSStringFromClass([MEServiceFinder class]), [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define SFLog( s, ... )
#endif


@interface MEServiceFinder () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property NSString*             type;
@property NSString*             domain;
@property NSNetServiceBrowser*  browser;
@property NSMutableArray*       resolving;
@property NSMutableDictionary*  services;

@end


@implementation MEServiceFinder

- (instancetype)initWithType:(NSString*)theType andDomain:(NSString*)theDomain
{
    self = [super init];
    if (self != nil)
    {
        self.type      = theType;
        self.domain    = theDomain;
        self.browser   = [[NSNetServiceBrowser alloc] init];
        self.resolving = [NSMutableArray new];
        self.services  = [NSMutableDictionary new];
        
        self.browser.delegate = self;
    }
    return self;
}

- (void)start
{
    SFLog(@"Started search for services: %@   in domain: %@", self.type, self.domain);
    [self.browser searchForServicesOfType:self.type inDomain:self.domain];
}

- (void)stop
{
    SFLog(@"Search stopped...");
    [self.browser stop];
}

- (NSDictionary*)allFoundServices
{
    return _services;
}

//-------------------------------------------------------------------------------
#pragma mark - NSNetServiceBrowser delegate
//-------------------------------------------------------------------------------

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)theBrowser
{
    SFLog(@"netServiceBrowserWillSearch:\n");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)theBrowser didNotSearch:(NSDictionary *)theErrors
{
    SFLog(@"netServiceBrowser:didNotSearch: %@", theErrors);
    
    if ([_delegate respondsToSelector:@selector(findServices:didFailToSearch:)]) {
        [_delegate findServices:self didFailToSearch:theErrors];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)theService moreComing:(BOOL)moreComing
{
    SFLog(@"netServiceBrowser:didFindService: %@", theService);
    
    [self.resolving addObject:theService];
    theService.delegate = self;
    [theService resolveWithTimeout:0.0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)theService moreComing:(BOOL)moreComing
{
    SFLog(@"netServiceBrowser:didRemoveService: %@", theService);
    
    if ([_delegate respondsToSelector:@selector(findServices:didLoseService:)]) {
        [_delegate findServices:self didLoseService:[[MEService alloc] initWithDomain:theService.domain type:theService.type name:theService.name port:theService.port]];
    }
    
    if ([_resolving containsObject:theService]) {
        [_resolving removeObject:theService];
    }
    if ([_services objectForKey:[self.services objectForKey:theService.name]]) {
        [_services removeObjectForKey:[self.services objectForKey:theService.name]];
    }
}

//-------------------------------------------------------------------------------
#pragma mark - NSNetService delegate
//-------------------------------------------------------------------------------

- (void)netServiceWillResolve:(NSNetService *)theService
{
    SFLog(@"netServiceWillResolve");
}

- (void)netServiceDidResolveAddress:(NSNetService *)theService
{
    NSUInteger nAddresses = [[theService addresses] count];
    SFLog(@"netServiceDidResolveAddress: %@ nAddresses == %lu", theService, (unsigned long)nAddresses);
    
    MEService* service = [[MEService alloc] initWithDomain:theService.domain type:theService.type name:theService.name port:theService.port];
    
    NSData             *address = nil;
    struct sockaddr_in *socketAddress = nil;
    NSString           *ipString = nil;
    int                port;
    
    //---get the IP address(es) of a service---
    for(int i=0;i < [[theService addresses] count]; i++ )
    {
        address = [[theService addresses] objectAtIndex: i];
        socketAddress = (struct sockaddr_in *) [address bytes];
        ipString = [NSString stringWithFormat: @"%s", inet_ntoa(socketAddress->sin_addr)];
        port = socketAddress->sin_port;
        if (![ipString isEqualToString:@"0.0.0.0"]) {
            [service setIpAddress:ipString];
        }
        NSString* s = [NSString stringWithFormat:@"Resolved: %@ — >%@ : %d", [theService hostName], ipString, port];
        SFLog(@"%@", s);
    }
    
    if (service.ipAddress) {
        [_services setObject:service forKey:[service name]];
        if ([_delegate respondsToSelector:@selector(findServices:didFindService:)]) {
            [_delegate findServices:self didFindService:service];
        }
    }
    
//    for (id obj in [theService addresses]) {
//        //NSLog(@"%@", [obj class]);
//        if ([obj isKindOfClass:[NSData class]]) {
//            NSLog(@"%@", [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding]);
//        }
//    }
    
//    if (nAddresses != 0)
//    {
//        MEService* service = [[MEService alloc] init:theService];
//        
//        [self.resolving removeObject:theService];
//        [self.services setObject:service forKey:theService.name];
//        [self.delegate findServices:self didFindService:service];
//    }
//    else
//    {
//        MEService* service = [self.services objectForKey:theService.name];
//        
//        if (service != nil)
//        {
//            NSLog(@"service %@ now has 0 addresses !", theService.name);
//        }
//        else
//        {
//            NSLog(@"resolve failed ? %@ has 0 addresses", theService.name);
//        }
//    }
}

- (void)netService:(NSNetService *)theService didNotResolve:(NSDictionary *)theErrors
{
    NSLog(@"netServiced:didNotResolve: %@ %@", theService, theErrors);
    
    [self.resolving removeObject:theService];
}

@end





@implementation MEService


@end