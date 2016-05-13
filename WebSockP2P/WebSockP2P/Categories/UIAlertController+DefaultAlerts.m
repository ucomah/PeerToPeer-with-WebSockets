//
//  UIAlertController+DefaultAlerts.m
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 10.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import "UIAlertController+DefaultAlerts.h"

@implementation UIAlertController (DefaultAlerts)

+ (void)alertWithError:(NSError*)error withCompletion:(void(^)())handler {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }]];
    [[[UIApplication sharedApplication] topMostController] presentViewController:alert animated:YES completion:handler];
}

@end
