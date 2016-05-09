//
//  WSAgent.h
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 06.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WSAgentState) {
    WSAgentState_Stopped = 0,
    WSAgentState_Listening,
    WSAgentState_Error
};

#define WS_DEFAULT_SERVER_PORT 9000
#define WS_DEFAULT_SERVER_PROTOCOL @"peertopeer_test_protocol"
#define DEFAULT_BONJOUR_SERVICE_TYPE @"_ws_peertopeer_test._tcp."
#define DEFAULT_BONJOUR_SERVICE_NAME @"TestServer"
#define DEFAULT_BONJOUR_SERVICE_DOMAIN @"local."



@class WSAgent;
@class WSPeer;

@protocol WSAgentDelegate <NSObject>
@optional
- (void)agentDidStop:(WSAgent*)agent withError:(NSError*)error;
- (void)agent:(WSAgent*)agent didReceiveMessage:(id)message fromPeer:(WSPeer*)peer;

- (void)agent:(WSAgent*)agent didAddPeer:(WSPeer*)peer;
- (void)agent:(WSAgent*)agent didRemovePeer:(WSPeer*)peer;
// In most cases, called when peer bonjour name is updated or vice versa
- (void)agent:(WSAgent*)agent didUpdatePeer:(WSPeer *)peer;

@end


@interface WSAgent : NSObject

+ (instancetype)sharedInstance;

/**
 Contains all peers (WSPeer object).
 Any peer can be identified as:
 - bonjour name discovered (found by Service finder)
 - is incoming (this peer has the client connection to Agent)
 - is outcoming (agent initialted coonection to Peer)
 This array items are bing refreshed asychronously every time:
 - someone connected
 - someone disconnected
 - bonjour name discovered
 */
@property (nonatomic, readonly) NSArray* allPeers;

// WebSocket server port. Default value is 'WS_DEFAULT_SERVER_PORT'
@property (nonatomic, assign) int serverPort;
// WebSocket server protocol. Default value is 'WS_DEFAULT_SERVER_PROTOCOL'
@property (nonatomic, strong) NSString* serverProtocol;
// Default value: 'DEFAULT_BONJOUR_SERVICE_TYPE'
@property (nonatomic, strong) NSString* bonjourServiceType;
// Default value: 'DEFAULT_BONJOUR_SERVICE_NAME'
@property (nonatomic, strong) NSString* bonjourServiceName;
// Default value: 'DEFAULT_BONJOUR_SERVICE_DOMAIN'
@property (nonatomic, strong) NSString* bonjourServiceDomain;
// Inticates the current agent state.
@property (nonatomic, readonly) WSAgentState state;

@property (nonatomic, assign) id<WSAgentDelegate>delegate;

+ (NSURL*)defaultPeerURLWithAddreessOrHost:(NSString*)addr;

- (void)startListeningWithCompletion:(void(^)(NSError* error))handler;
- (void)stopListening;

- (void)startBonjourDiscovering;
- (void)stopBonjourDiscovering;

@end
