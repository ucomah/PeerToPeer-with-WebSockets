//
//  DevicesListTableCell.m
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 09.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import "DevicesListTableCell.h"

@implementation DevicesListTableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.statuView.layer.cornerRadius = (self.statuView.frame.size.width + self.statuView.frame.size.height) / 4;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setIsConnected:(BOOL)isConnected {
    UIColor* color = isConnected ? [UIColor greenColor] : [UIColor redColor];
    self.statuView.backgroundColor = color;
    self.descriptionLabel.text = isConnected ? @"Connected" : @"Not connected";
}

- (void)setMessagesCount:(NSUInteger)count {
    self.messagesCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)count];
}

@end
