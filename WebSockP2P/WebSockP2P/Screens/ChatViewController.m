//
//  ChatViewController.m
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 11.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import "ChatViewController.h"
#import "WSPeer.h"
#import "JSQSystemSoundPlayer+JSQMessages.h"
#import "NetUtils.h"
#import "JSQMessage.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesTimestampFormatter.h"

@interface ChatViewController () <WSAgentDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) NSString* myHost;
@property (nonatomic, readonly) NSMutableArray* allMessages;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;
@end

@implementation ChatViewController

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self reloadTitle];
    
    _myHost = [NetUtils localIPAddress];
    
    self.senderId = _myHost;
    self.senderDisplayName = @"Me";
    
    self.showLoadEarlierMessagesHeader = NO;
    
    //Create message bubble images objects.
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor lightGrayColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor greenColor]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WSAgent sharedInstance].delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helpers

- (void)reloadTitle {
    self.title = [self.peer preferredName];
}

- (NSMutableArray *)allMessages {
    return [[MessagesStorage sharedInstance] messagesForRemoteSenderId:self.peer.host];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    __block __strong UIImage *image;
    if ([info objectForKey:UIImagePickerControllerEditedImage]) {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    } else {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    [[MessagesStorage sharedInstance] addPhotoMediaMessage:image from:self.senderId to:self.peer.host senderName:self.senderDisplayName];
    [picker dismissViewControllerAnimated:YES completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData* imageData = UIImagePNGRepresentation(image);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[WSAgent sharedInstance] sendSome:imageData toPeer:self.peer];
                [JSQSystemSoundPlayer jsq_playMessageSentSound];
                [self finishSendingMessage];
            });
        });
    }];
}

#pragma mark - WSAgent delegate

- (void)agent:(WSAgent *)agent didUpdatePeer:(WSPeer *)peer {
    if (![peer.host isEqualToString:self.peer.host]) {
        return;
    }
    self.peer = peer;
    [self reloadTitle];
}

- (void)agentDidStop:(WSAgent *)agent withError:(NSError *)error {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)agent:(WSAgent *)agent didReceiveMessage:(id)message fromPeer:(WSPeer *)peer {
    if (![peer.host isEqualToString:self.peer.host]) {
        return;
    }
    [[MessagesStorage sharedInstance] addMessage:message fromPeer:peer];
    [self finishReceivingMessage];
    if ([message isKindOfClass:[NSData class]]) {
        [self.collectionView layoutSubviews];
    }
}

- (void)agent:(WSAgent *)agent didReceiveError:(NSError *)error forPeer:(WSPeer *)peer {
}

- (void)agent:(WSAgent *)agent didRemovePeer:(WSPeer *)peer {
    if (![peer.host isEqualToString:self.peer.host]) {
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    if ([text containsString:@"*"]) {
        [self.navigationController popViewControllerAnimated:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [NSThread sleepForTimeInterval:2.0f];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didPressSendButton:button withMessageText:@"Test message" senderId:senderId senderDisplayName:senderDisplayName date:nil];
            });
        });
        return;
    }
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    [[WSAgent sharedInstance] sendSome:text toPeer:self.peer];
    [[MessagesStorage sharedInstance] addMessage:text from:senderId to:self.peer.host senderName:senderDisplayName date:nil];
    [self finishSendingMessageAnimated:YES];
}

- (void)didPressAccessoryButton:(UIButton *)sender {
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
    UIImagePickerController* picker = [UIImagePickerController new];
    picker.allowsEditing = NO;
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.allMessages objectAtIndex:indexPath.item];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath {
    [self.allMessages removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
             messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = [self.allMessages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    return self.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
                    avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.allMessages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = [self.allMessages objectAtIndex:indexPath.item];
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.allMessages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.allMessages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    JSQMessage *msg = [self.allMessages objectAtIndex:indexPath.item];
    if (!msg.isMediaMessage) {
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    return cell;
}

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *currentMessage = [self.allMessages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.allMessages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return 0.0f;
}



@end
