//
//  DevicesListTableCell.h
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 09.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DevicesListTableCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIView* statuView;
@property (nonatomic, weak) IBOutlet UILabel* hostNameLabel;
@property (nonatomic, weak) IBOutlet UILabel* descriptionLabel;

- (void)setIsConnected:(BOOL)isConnected;

@end
