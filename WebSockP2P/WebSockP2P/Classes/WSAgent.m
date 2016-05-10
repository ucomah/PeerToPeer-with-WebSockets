//
//  WSAgent.m
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 06.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import "WSAgent.h"
#import "PSWebSocketServer.h"
#import "SRWebSocket.h"
#import "WSPeer.h"
#import "NetUtils.h"
#import "UIApplication+Backgrounding.h"
#import "MEServiceFinder.h"


@interface WSAgent () <NSNetServiceDelegate, PSWebSocketServerDelegate, SRWebSocketDelegate, MEServiceFinderDelegate>
@property (nonatomic, strong) NSMutableArray* allPeers;
@end

typedef void(^WSErrorBlock)(NSError* error);
typedef void(^WSVoidBlock)();

@implementation WSAgent {
    NSNetService* netService; //bonjour net service
    PSWebSocketServer* wsServer;
    WSErrorBlock socketServerLaunchBlock;
    WSVoidBlock socketServerStopBlock;
    WSErrorBlock bonjourLaunchBlock;
    WSVoidBlock bonjourStopBlock;
    BOOL isNetServiceRunning;
    BOOL isSocketServerRunning;
    NSMutableDictionary* allOutgoingSockets; //of SRWebSocket
    MEServiceFinder* finder; //Bonjour services finder
}

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.serverPort = WS_DEFAULT_SERVER_PORT;
        self.serverProtocol = WS_DEFAULT_SERVER_PROTOCOL;
        self.bonjourServiceType = DEFAULT_BONJOUR_SERVICE_TYPE;
        self.bonjourServiceName = DEFAULT_BONJOUR_SERVICE_NAME;
        self.bonjourServiceDomain = DEFAULT_BONJOUR_SERVICE_DOMAIN;
        _state = WSAgentState_Stopped;
        socketServerLaunchBlock = nil;
        bonjourLaunchBlock = nil;
        _allPeers = [NSMutableArray new];
        allOutgoingSockets = [NSMutableDictionary new];
    }
    return self;
}

//-------------------------------------------------------------------------------
#pragma mark - Core methods
//-------------------------------------------------------------------------------

+ (NSURL*)defaultPeerURLWithAddreessOrHost:(NSString*)addr {
    return [NSURL URLWithString:[NSString stringWithFormat:@"ws://%@:%d", addr, [[self sharedInstance] serverPort]]];
}

+ (NSError*)errorWithCode:(NSInteger)code description:(NSString*)descr {
    return [NSError errorWithDomain:NSStringFromClass([self class])
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: descr ? descr : @""}];
}

- (void)startListeningWithCompletion:(void(^)(NSError* error))handler {
    [self startWebSocketServerWithCompletion:^(NSError *error) {
        if (error) {
            if (handler) {
                handler(error);
            }
            return ;
        }
        [self startBonjourServiceWithCompletion:^(NSError *error) {
            if (handler) {
                handler(error);
            }
        }];
    }];
    [[UIApplication sharedApplication] startFineLengthBackgroundBlock:^{
        while (1) {
            [NSThread sleepForTimeInterval:1.0];
        }
    }];
}

- (void)stopListening {
    [self stopWebSocketServerWithCompletion:nil];
}

- (void)performStopActions {
    [self closeAllConnections];
    if ([self.delegate respondsToSelector:@selector(agentDidStop:withError:)]) {
        [self.delegate agentDidStop:self withError:nil];
    }
}

//-------------------------------------------------------------------------------
#pragma mark - Bonjour
//-------------------------------------------------------------------------------

- (void)startBonjourServiceWithCompletion:(WSErrorBlock)handler {
    if (!netService) {
        netService = [[NSNetService alloc] initWithDomain:self.bonjourServiceDomain
                                                     type:self.bonjourServiceType
                                                     name:self.bonjourServiceName
                                                     port:self.serverPort];
    }
    if (!netService) {
        if (handler) {
            handler([self.class errorWithCode:-3 description:@"Failed to initialize NSNetservice"]);
        }
        return;
    }
    bonjourLaunchBlock = [handler copy];
    [netService setDelegate:self];
    [netService publish];
}

- (void)stopBonjourServiceWithCompletion:(WSVoidBlock)handler {
    if (!netService || isNetServiceRunning) {
        if (handler) {
            handler();
        }
        return;
    }
    bonjourStopBlock = [handler copy];
    [netService stop];
}

#pragma mark NSNetService delegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, errorDict);
    if (bonjourLaunchBlock) {
        bonjourLaunchBlock([NSError errorWithDomain:NSStringFromClass([sender class])
                                               code:-1
                                           userInfo:errorDict]);
    }
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    NSLog(@"%s: %@  %@", __PRETTY_FUNCTION__, sender, [NetUtils localIPAddress]);
    if (bonjourLaunchBlock) {
        bonjourLaunchBlock(nil);
    }
    isNetServiceRunning = YES;
}

- (void)netServiceWillPublish:(NSNetService *)sender {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, sender);
}

- (void)netServiceDidStop:(NSNetService *)sender {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, sender);
    if (bonjourStopBlock) {
        bonjourStopBlock();
    }
    isNetServiceRunning = NO;
    
    [self stopWebSocketServerWithCompletion:^{
        [self performStopActions];
    }];
}

#pragma mark Discover devices

- (void)startBonjourDiscovering {
    if (finder) {
        [finder stop];
        finder = nil;
    }
    
    finder = [[MEServiceFinder alloc] initWithType:self.bonjourServiceType andDomain:self.bonjourServiceDomain];
    finder.delegate = self;
    [finder start];
}

- (void)stopBonjourDiscovering {
    [finder stop];
}

#pragma mark MEServiceFinderDelegate

- (void)findServices:(MEServiceFinder*)theFindServices didFindService:(MEService*)theService {
    //Forbid conencting to myself
    if ([theService.ipAddress isEqualToString:[NetUtils localIPAddress]]) {
        return;
    }
    
    //Check if new service ip address is present in the peers list already
    WSPeer* peer = [self peerForHost:theService.hostName];
    if (peer) {
        [self updatePeer:peer withBonjourServuce:theService];
        return;
    }
    peer = [self peerForHost:theService.ipAddress];
    if (peer) {
        [self updatePeer:peer withBonjourServuce:theService];
        return;
    }
    //If no peer found - create a new peer instance
    peer = [[WSPeer alloc] initWithBonjourService:theService];
    [self addPeer:peer];
}

- (void)findServices:(MEServiceFinder*)theFindServices didLoseService:(MEService*)theService {
    
}

- (void)findServices:(MEServiceFinder*)theFindServices didFailToSearch:(NSDictionary *)theErrors {
    NSLog(@"Failed to search for Baonjour services");
}

//-------------------------------------------------------------------------------
#pragma mark - Web Sockets Server
//-------------------------------------------------------------------------------

- (void)startWebSocketServerWithCompletion:(WSErrorBlock)handler {
    if (isSocketServerRunning) {
        if (handler) {
            handler([self.class errorWithCode:-5 description:@"Already running"]);
        }
        return;
    }
    if (!wsServer) {
        wsServer = [PSWebSocketServer serverWithHost:@"0.0.0.0" port:self.serverPort];
        wsServer.delegate = self;
    }
    socketServerLaunchBlock = [handler copy];
    [wsServer start];
}

- (void)stopWebSocketServerWithCompletion:(WSVoidBlock)handler {
    if (!wsServer || !isSocketServerRunning) {
        if (handler) {
            handler();
        }
        return;
    }
    [wsServer stop];
    socketServerStopBlock = [handler copy];
}

#pragma mark PSWebSocketServerDelegate

- (void)serverDidStart:(PSWebSocketServer *)server {
    NSLog(@"WebSocket server started on port: %d", self.serverPort);
    if (socketServerLaunchBlock) {
        socketServerLaunchBlock(nil);
    }
    isSocketServerRunning = YES;
}

- (void)serverDidStop:(PSWebSocketServer *)server {
    if (socketServerStopBlock) {
        socketServerStopBlock();
    }
    
    NSLog(@"WebSocket server stopped");
    
    //Bonjour stop
    [self stopBonjourServiceWithCompletion:^{
        [self performStopActions];
    }];
    
    isSocketServerRunning = NO;
}

- (BOOL)server:(PSWebSocketServer *)server acceptWebSocketWithRequest:(NSURLRequest *)request {
    NSLog(@"Server should accept request from: %@", request.URL);
    return YES;
}

- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    //Get peer by socket
    WSPeer* peer = [self peerForIncomingSocket:webSocket];
    
    if ([self.delegate respondsToSelector:@selector(agent:didReceiveMessage:fromPeer:)]) {
        [self.delegate agent:self didReceiveMessage:message fromPeer:peer];
    }
}

- (void)server:(PSWebSocketServer *)server webSocketDidOpen:(PSWebSocket *)webSocket {
    NSLog(@"Got new connection from user %@", webSocket.url.host);
    
    WSPeer* peer = [[WSPeer alloc] initWithIncomingConnection:webSocket];
    [self addPeer:peer];
}

- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code
        reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"Server websocket did close with code: %@, reason: %@, wasClean: %@", @(code), reason, @(wasClean));
    
    WSPeer* peer = [self peerForIncomingSocket:webSocket];
    [self removePeer:peer];
}

- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"Server websocket did fail with error: %@", error);
    
    if (error.code == 3) {
        [webSocket close];
        WSPeer* p = [self peerForIncomingSocket:webSocket];
        [self removePeer:p];
    }
}

//-------------------------------------------------------------------------------
#pragma mark - Web Sockets Client
//-------------------------------------------------------------------------------

- (void)connectToHost:(NSString*)host {
    //Check if already has a connection with this host
    WSPeer* peer = [self peerForHost:host];
    if (peer) {
        NSLog(@"Already connected to %@", host);
        return;
    }
    
    //Create a new WebSocket connection
    SRWebSocket* sock = [allOutgoingSockets objectForKey:host];
    if (sock) {
        if (sock.readyState != SR_CONNECTING && sock.readyState != SR_OPEN) {
            //connectToHost: will be called again after this -100 code
            [sock closeWithCode:-100 reason:@"reconnect"];
            return;
        }
    }
    //new connection
    NSURL* url = [self.class defaultPeerURLWithAddreessOrHost:host];
    sock = [[SRWebSocket alloc] initWithURL:url
                                  protocols:@[self.serverProtocol]];
    sock.delegate = self;
    [sock open];
    [allOutgoingSockets setObject:sock forKey:host];
}

- (void)sendSome:(id)data toPeer:(WSPeer*)peer {
    if (!data || !peer) {
        return;
    }
    [peer send:data];
}

- (void)disconnectPeer:(WSPeer*)peer {
    if (!peer) {
        return;
    }
    [peer closeConnection];
    [self removePeer:peer];
}

#pragma mark SRWebSocket delegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSString* logMessage = [NSString stringWithFormat:@"%@ :) Websocket Connected", NSStringFromClass(webSocket.class)];
    NSLog(@"%@", logMessage);
    
    WSPeer* peer = [[WSPeer alloc] initWithOutgoingConnection:webSocket];
    [self addPeer:peer];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"%@ :( Websocket Failed With Error: %@", NSStringFromClass(webSocket.class), error.description);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSString* logMessage = [NSString stringWithFormat:@"%@ : Received \"%@\"", NSStringFromClass(webSocket.class), message];
    NSLog(@"%@",logMessage);
    
    WSPeer* peer = [self peerForOutgoing:webSocket];
    if (!peer) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(agent:didReceiveMessage:fromPeer:)]) {
        [self.delegate agent:self didReceiveMessage:message fromPeer:peer];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSString* logMessage = [NSString stringWithFormat:@"%@ : WebSocket closed with code: %ld, reason: %@", NSStringFromClass(webSocket.class), (long)code, reason];
    NSLog(@"%@", logMessage);
    
    [allOutgoingSockets removeObjectForKey:webSocket.url.host];
    
    if (code == -100 && [reason isEqualToString:@"reconnect"]) {
        [self connectToHost:webSocket.url.host];
        return;
    }
    
    WSPeer* peer = [self peerForOutgoing:webSocket];
    [self removePeer:peer];
}

//-------------------------------------------------------------------------------
#pragma mark - Peers
//-------------------------------------------------------------------------------

- (WSPeer*)peerForIncomingSocket:(PSWebSocket*)socket {
    @synchronized (self) {
        if (socket) {
            for (WSPeer* peer in _allPeers) {
                if ([peer.url isEqual:socket.url]) {
                    return peer;
                }
            }
        }
        return nil;
    }
}

- (WSPeer*)peerForOutgoing:(SRWebSocket*)sock {
    @synchronized (self) {
        if (sock) {
            for (WSPeer* peer in _allPeers) {
                if ([peer.url isEqual:sock.url]) {
                    return peer;
                }
            }
        }
        return nil;
    }
}

- (void)closeAllConnections {
    @synchronized (self) {
        [_allPeers enumerateObjectsUsingBlock:^(__kindof WSPeer*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj closeConnection];
        }];
        [_allPeers removeAllObjects];
    }
}

- (void)addPeer:(WSPeer*)peer {
    if (peer) {
        @synchronized (self) {
            //Check if peers contains bonjour service
            WSPeer* existingPeer = nil;
            for (WSPeer* p in _allPeers) {
                if ([p.host isEqualToString:peer.host]) {
                    existingPeer = p;
                    break;
                }
            }
            if (existingPeer) {
                [self updatePeer:existingPeer withPeer:peer];
                return;
            }
            [_allPeers addObject:peer];
            if ([self.delegate respondsToSelector:@selector(agent:didAddPeer:)]) {
                [self.delegate agent:self didAddPeer:peer];
            }
        }
    }
}

- (void)removePeer:(WSPeer*)peer {
    if (peer) {
        @synchronized (self) {
            if ([_allPeers containsObject:peer]) {
                [_allPeers removeObject:peer];
                if ([self.delegate respondsToSelector:@selector(agent:didRemovePeer:)]) {
                    [self.delegate agent:self didRemovePeer:peer];
                }
            }
        }
    }
}

- (WSPeer*)peerForHost:(NSString*)host {
    if (!host) {
        return  nil;
    }
    @synchronized (self) {
        for (WSPeer* peer in _allPeers) {
            if ([peer.host isEqualToString:host]) {
                return peer;
            }
        }
        return nil;
    }
}

- (void)updatePeer:(WSPeer*)existingPeer withPeer:(WSPeer*)newPeer {
    if (!existingPeer || !newPeer) {
        return;
    }
    if ([existingPeer updateWithPeer:newPeer]) {
        if ([self.delegate respondsToSelector:@selector(agent:didUpdatePeer:)]) {
            [self.delegate agent:self didUpdatePeer:existingPeer];
        }
    }
}

- (void)updatePeer:(WSPeer*)peer withBonjourServuce:(MEService*)service {
    if (!peer) {
        return;
    }
    peer.bjService = service;
    if ([_delegate respondsToSelector:@selector(agent:didUpdatePeer:)]) {
        [_delegate agent:self didUpdatePeer:peer];
    }
}

@end
