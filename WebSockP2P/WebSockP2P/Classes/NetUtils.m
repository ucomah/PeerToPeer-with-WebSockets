//
//  EMNetUtils.m
//  LightSpeed
//
//  Created by Evgeniy Melkov on 09.12.14.
//  Copyright (c) 2014 Evgeniy Melkov. All rights reserved.
//

#import "NetUtils.h"
#import <CFNetwork/CFNetwork.h>

//locating IPs
#include <netinet/in.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <netdb.h>

@implementation NetUtils

//-------------------------------------------------------------------------------
#pragma mark - Helpers
//-------------------------------------------------------------------------------

+ (void)clearAppCookies
{
    NSHTTPCookieStorage* allCookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie* cookie in [allCookies cookies]) {
        [allCookies deleteCookie:cookie];
    }
    NSLog(@"%@: Cookies cleaned", NSStringFromClass(self.class));
}

+ (void)dumpCookies:(NSString *)msgOrNil
{
    NSString*(^cookieDescription)(NSHTTPCookie*) = ^(NSHTTPCookie* cookie) {
        NSMutableString *cDesc      = [NSMutableString string];
        [cDesc appendString:@"[NSHTTPCookie]\n"];
        [cDesc appendFormat:@"  name            = %@\n",            [[cookie name] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [cDesc appendFormat:@"  value           = %@\n",            [[cookie value] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [cDesc appendFormat:@"  domain          = %@\n",            [cookie domain]];
        [cDesc appendFormat:@"  path            = %@\n",            [cookie path]];
        [cDesc appendFormat:@"  expiresDate     = %@\n",            [cookie expiresDate]];
        [cDesc appendFormat:@"  sessionOnly     = %d\n",            [cookie isSessionOnly]];
        [cDesc appendFormat:@"  secure          = %d\n",            [cookie isSecure]];
        [cDesc appendFormat:@"  comment         = %@\n",            [cookie comment]];
        [cDesc appendFormat:@"  commentURL      = %@\n",            [cookie commentURL]];
        [cDesc appendFormat:@"  version         = %lu\n",            (unsigned long)[cookie version]];
        
        //  [cDesc appendFormat:@"  portList        = %@\n",            [cookie portList]];
        //  [cDesc appendFormat:@"  properties      = %@\n",            [cookie properties]];
        
        return cDesc;
    };
    
    NSMutableString *cookieDescs    = [NSMutableString string];
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [cookieJar cookies]) {
        [cookieDescs appendString:cookieDescription(cookie)];
    }
    NSLog(@"------ [Cookie Dump: %@] ---------\n%@", msgOrNil, cookieDescs);
    NSLog(@"----------------------------------");
}

//-------------------------------------------------------------------------------
#pragma mark - IP Addresses
//-------------------------------------------------------------------------------

+ (NSString *)hostname
{
    char baseHostName[256];
    int success = gethostname(baseHostName, 255);
    
    if (success != 0) return @"";
    baseHostName[255] = '\0';
    
#if !TARGET_IPHONE_SIMULATOR
    return [NSString stringWithFormat:@"%s.local", baseHostName];
#else
    return [NSString stringWithFormat:@"%s", baseHostName];
#endif
}

+ (NSString *)localIPAddress
{
    struct hostent *host = gethostbyname([[self hostname] UTF8String]);
    if (!host) {herror("resolv"); return @"";}
    struct in_addr **list = (struct in_addr **)host->h_addr_list;
    NSString* s = [NSString stringWithCString:inet_ntoa(*list[0]) encoding:NSUTF8StringEncoding];
    return s;
}

+ (NSString*)getPublicIP
{
    NSUInteger  an_Integer;
    NSArray * ipItemsArray;
    NSString *externalIP;
    
    NSURL *iPURL = [NSURL URLWithString:@"http://www.dyndns.org/cgi-bin/check_ip.cgi"];
    
    if (iPURL) {
        NSError *error = nil;
        NSString *theIpHtml = [NSString stringWithContentsOfURL:iPURL encoding:NSUTF8StringEncoding error:&error];
        if (!error) {
            NSScanner *theScanner;
            NSString *text = nil;
            
            theScanner = [NSScanner scannerWithString:theIpHtml];
            
            while ([theScanner isAtEnd] == NO) {
                
                // find start of tag
                [theScanner scanUpToString:@"<" intoString:NULL] ;
                
                // find end of tag
                [theScanner scanUpToString:@">" intoString:&text] ;
                
                // replace the found tag with a space
                //(you can filter multi-spaces out later if you wish)
                theIpHtml = [theIpHtml stringByReplacingOccurrencesOfString:
                             [ NSString stringWithFormat:@"%@>", text]
                                                                 withString:@" "] ;
                ipItemsArray =[theIpHtml  componentsSeparatedByString:@" "];
                an_Integer=[ipItemsArray indexOfObject:@"Address:"];
                externalIP =[ipItemsArray objectAtIndex:  ++an_Integer];
            }
            NSLog(@"%@",externalIP);
        } else {
            NSLog(@"Oops... g %ld, %@", (long)[error code], [error localizedDescription]);
        }
    }
    return externalIP;
}


@end
