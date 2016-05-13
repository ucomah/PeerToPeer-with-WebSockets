//
//  MessagesStorage.m
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 11.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import "MessagesStorage.h"
#import "JSQMessage.h"
#import "JSQPhotoMediaItem.h"
#import "WSPeer.h"

@interface MessagesStorage()
@property (nonatomic, strong) NSMutableDictionary* allChats;
@end

@implementation MessagesStorage

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _allChats = [NSMutableDictionary new];
    }
    return self;
}

- (NSMutableArray*)messagesForRemoteSenderId:(NSString*)senderId {
    @synchronized (self) {
        NSMutableArray* allMessages = [_allChats objectForKey:senderId];
        if (!allMessages) {
            allMessages = [NSMutableArray new];
            [_allChats setObject:allMessages forKey:senderId];
        }
        return allMessages;
    }
}

- (void)addMessage:(NSString*)message
              from:(NSString*)senderId
                to:(NSString*)receiverId
        senderName:(NSString*)senderName
              date:(NSDate*)date
{
    if (!senderId || !message) {
        return;
    }
    @synchronized (self) {
        //Get chat for sender
        BOOL isMeSender = [_myUserId isEqualToString:senderId];
        NSMutableArray* allMessages = [self messagesForRemoteSenderId:(isMeSender ? receiverId : senderId )];
        JSQMessage* msg = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderName
                                                          date:(date ? date : [NSDate date])
                                                          text:message];
        [allMessages addObject:msg];
    }
}

- (void)addPhotoMediaMessage:(UIImage *)image
                        from:(NSString *)senderId
                          to:(NSString*)receiverId
                  senderName:(NSString *)senderName
{
    if (!image || !senderId) {
        return;
    }
    @synchronized (self) {
        BOOL isMeSender = [_myUserId isEqualToString:senderId];
        JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
        JSQMessage *photoMessage = [JSQMessage messageWithSenderId:senderId
                                                       displayName:senderName
                                                             media:photoItem];
        [[self messagesForRemoteSenderId:(isMeSender ? receiverId : senderId )] addObject:photoMessage];
    }
}

- (void)addMessage:(id)message fromPeer:(WSPeer*)peer {
    if (!message || !peer) {
        return;
    }
    if ([message isKindOfClass:[NSData class]]) { //Image
        UIImage* image = [UIImage imageWithData:message];
        [[MessagesStorage sharedInstance] addPhotoMediaMessage:image from:peer.host to:nil senderName:[peer preferredName]];
    }
    else if ([message isKindOfClass:[NSString class]]) { //Text
        [[MessagesStorage sharedInstance] addMessage:message from:peer.host to:nil senderName:[peer preferredName] date:nil];
    }
}

@end
