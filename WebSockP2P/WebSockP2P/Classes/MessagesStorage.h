//
//  MessagesStorage.h
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 11.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WSPeer;

@interface MessagesStorage : NSObject

+ (instancetype)sharedInstance;

//Contains key: "host", object: NSMutableArray of JSQMessage
@property (nonatomic, readonly) NSMutableDictionary* allChats;
@property (nonatomic, strong) NSString* myUserId;

- (NSMutableArray*)messagesForRemoteSenderId:(NSString*)senderId;

- (void)addMessage:(NSString*)message
              from:(NSString*)senderId
                to:(NSString*)receiverId
        senderName:(NSString*)senderName
              date:(NSDate*)date;

- (void)addPhotoMediaMessage:(UIImage*)image
                        from:(NSString*)senderId
                          to:(NSString*)receiverId
                  senderName:(NSString*)senderName;

- (void)addMessage:(id)message fromPeer:(WSPeer*)peer;

@end
