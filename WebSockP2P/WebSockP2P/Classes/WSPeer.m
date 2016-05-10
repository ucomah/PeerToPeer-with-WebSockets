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
#import "MEServiceFinder.h"
#import "WSAgent.h"

@interface WSPeer ()

@end

@implementation WSPeer

#pragma mark - LifeCycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _wsInPeer = nil;
        _wsOutPeer = nil;
        _bjService = nil;
    }
    return self;
}

- (instancetype)initWithIncomingConnection:(PSWebSocket*)sock {
    self = [self init];
    if (self) {
        _wsInPeer = sock;
    }
    return self;
}

- (instancetype)initWithOutgoingConnection:(SRWebSocket*)sock {
    self = [self init];
    if (self) {
        _wsOutPeer = sock;
    }
    return self;
}

- (instancetype)initWithBonjourService:(MEService *)service {
    self = [self init];
    if (self) {
        _bjService = service;
    }
    return self;
}

#pragma mark - Setters / Getters

- (NSURL *)url {
    if (_wsInPeer) {
        return _wsInPeer.url;
    }
    else if (_wsOutPeer) {
        return _wsOutPeer.url;
    }
    else if (_bjService) {
        return [WSAgent defaultPeerURLWithAddreessOrHost:_bjService.ipAddress];
    }
    return nil;
}

- (NSString *)host {
    return self.url.host;
}

- (NSString *)bonjourName {
    if (_bjService) {
        return _bjService.name;
    }
    return nil;
}

- (BOOL)isIncomingPeer {
    return _wsInPeer ? YES : NO;
}

#pragma mark - Actions

- (void)closeConnection {
    if (_wsInPeer) {
        [_wsInPeer close];
    }
    if (_wsOutPeer) {
        [_wsOutPeer close];
    }
}

- (void)send:(id)data {
    if (self.isIncomingPeer) {
        [self.wsInPeer send:data];
    }
    else {
        [self.wsOutPeer send:data];
    }
}

- (BOOL)isConnected {
    return _wsInPeer || _wsOutPeer;
}

- (BOOL)updateWithPeer:(WSPeer *)peer {
    if (!peer) {
        return NO;
    }
    if (peer.wsInPeer && !_wsInPeer) {
        _wsInPeer = peer.wsInPeer;
        return YES;
    }
    if (peer.wsOutPeer && !_wsOutPeer) {
        _wsOutPeer = peer.wsOutPeer;
        return YES;
    }
    if (peer.bjService && !_bjService) {
        _bjService = peer.bjService;
        return YES;
    }
    return NO;
}

@end
