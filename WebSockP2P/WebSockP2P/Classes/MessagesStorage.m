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
        senderName:(NSString*)senderName
              date:(NSDate*)date
{
    if (!senderId || !message) {
        return;
    }
    @synchronized (self) {
        //Get chat for sender
        NSMutableArray* allMessages = [self messagesForRemoteSenderId:senderId];
        JSQMessage* msg = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderName
                                                          date:(date ? date : [NSDate date])
                                                          text:message];
        [allMessages addObject:msg];
    }
}

- (void)addPhotoMediaMessage:(UIImage *)image
                        from:(NSString *)senderId
                  senderName:(NSString *)senderName
{
    if (!image || !senderId) {
        return;
    }
    @synchronized (self) {
        JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:image];
        JSQMessage *photoMessage = [JSQMessage messageWithSenderId:senderId
                                                       displayName:senderName
                                                             media:photoItem];
        [[self messagesForRemoteSenderId:senderId] addObject:photoMessage];
    }
}

@end
