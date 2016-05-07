//
//  WSPeer.m
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 06.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import "WSPeer.h"
#import "SRWebSocket.h"
#import "PSWebSocket.h"

@interface WSPeer ()
@property (nonatomic, readonly) PSWebSocket* wsInPeer;
@property (nonatomic, readonly) SRWebSocket* wsOutPeer;
@end

@implementation WSPeer

- (instancetype)init {
    self = [super init];
    if (self) {
        _wsInPeer = nil;
        _wsOutPeer = nil;
    }
    return self;
}

- (instancetype)initWithIncomingConnection:(PSWebSocket*)sock {
    self = [self init];
    if (self) {
        _url = sock.url;
        _wsInPeer = sock;
    }
    return self;
}

- (instancetype)initWithOutgoingConnection:(SRWebSocket*)sock {
    self = [self init];
    if (self) {
        _url = sock.url;
        _wsOutPeer = sock;
    }
    return self;
}

- (BOOL)isIncomingPeer {
    return _wsInPeer ? YES : NO;
}

- (void)closeConnection {
    if (_wsInPeer) {
        [_wsInPeer close];
    }
    if (_wsOutPeer) {
        [_wsOutPeer close];
    }
}

- (NSString *)host {
    return self.url.host;
}

- (void)send:(id)data {
    if (self.isIncomingPeer) {
        [self.wsInPeer send:data];
    }
    else {
        [self.wsOutPeer send:data];
    }
}

@end
