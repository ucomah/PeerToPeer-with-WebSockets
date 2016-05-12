//
//  MessagesStorage.h
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 11.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessagesStorage : NSObject

+ (instancetype)sharedInstance;

//Contains key: "host", object: NSMutableArray of JSQMessage
@property (nonatomic, readonly) NSMutableDictionary* allChats;

- (NSMutableArray*)messagesForRemoteSenderId:(NSString*)senderId;

- (void)addMessage:(NSString*)message
              from:(NSString*)senderId
        senderName:(NSString*)senderName
              date:(NSDate*)date;

- (void)addPhotoMediaMessage:(UIImage*)image
                        from:(NSString*)senderId
                  senderName:(NSString*)senderName;

@end
