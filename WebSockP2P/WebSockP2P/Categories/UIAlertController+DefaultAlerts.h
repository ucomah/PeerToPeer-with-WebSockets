//
//  UIAlertController+DefaultAlerts.h
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 10.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (DefaultAlerts)

+ (void)alertWithError:(NSError*)error withCompletion:(void(^)())hadler;

@end
