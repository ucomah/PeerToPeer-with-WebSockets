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
@class MEService;

@interface WSPeer : NSObject

@property (nonatomic, strong) PSWebSocket* wsInPeer;
@property (nonatomic, strong) SRWebSocket* wsOutPeer;
@property (nonatomic, strong) MEService* bjService;

@property (nonatomic, readonly) NSURL* url;
@property (nonatomic, readonly) NSString* bonjourName;
@property (nonatomic, readonly) BOOL isIncomingPeer;
@property (nonatomic, readonly) NSString* host;

- (instancetype)initWithIncomingConnection:(PSWebSocket*)sock;
- (instancetype)initWithOutgoingConnection:(SRWebSocket*)sock;
- (instancetype)initWithBonjourService:(MEService*)service;

- (void)closeConnection;
- (void)send:(id)data;
- (BOOL)isConnected;

- (BOOL)updateWithPeer:(WSPeer*)inPeer;

@end
