//
//  ChatViewController.h
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 11.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import "JSQMessagesViewController.h"

@class WSPeer;

@interface ChatViewController : JSQMessagesViewController

@property (nonatomic, strong) WSPeer* peer;

@end
