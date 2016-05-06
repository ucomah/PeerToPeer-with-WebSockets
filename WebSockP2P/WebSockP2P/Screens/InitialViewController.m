//
//  InitialViewController.m
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 06.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import "InitialViewController.h"

@interface InitialViewController () <UITextFieldDelegate>

@end

static int minLength = 5;

@implementation InitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    self.startButton.enabled = NO;
    self.nameField.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)toggleStartButton {
    if (self.nameField.text.length > minLength) {
        self.startButton.enabled = YES;
    }
    else {
        self.startButton.enabled = NO;
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self toggleStartButton];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self toggleStartButton];
    return YES;
}

@end
