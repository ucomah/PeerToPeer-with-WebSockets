//
//  WSPeer.h
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 06.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRWebSocket;
@class PSWebSocket;

@interface WSPeer : NSObject

@property (nonatomic, readonly) NSURL* url;
@property (nonatomic, strong) NSString* bonjourName;
@property (nonatomic, readonly) BOOL isIncomingPeer;

- (instancetype)initWithIncomingConnection:(PSWebSocket*)sock;
- (instancetype)initWithOutgoingConnection:(SRWebSocket*)sock;

- (void)closeConnection;
- (NSString*)host;
- (void)send:(id)data;

@end
