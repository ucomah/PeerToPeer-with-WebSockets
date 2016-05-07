//
//  InitialViewController.m
//  WebSockP2P
//
//  Created by Evgeniy Melkov on 06.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import "InitialViewController.h"

@interface InitialViewController () <UITextFieldDelegate, WSAgentDelegate>

@end

static int minLength = 5;

@implementation InitialViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nameField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.startButton.enabled = NO;
    //Stop server if started
    [WSAgent sharedInstance].delegate = self;
    [[WSAgent sharedInstance] stopListening];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //Wait to assign a default device name
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:1.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.nameField.isFirstResponder && self.nameField.text.length == 0) {
                [self assignDefaultDeviceName];
            }
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helpers

- (void)toggleStartButton {
    if (self.nameField.text.length > minLength) {
        self.startButton.enabled = YES;
    }
    else {
        self.startButton.enabled = NO;
    }
}

- (void)assignDefaultDeviceName {
    self.nameField.text = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] name], [[UIDevice currentDevice] systemVersion]];
    [self toggleStartButton];
}

#pragma mark - Actions

- (IBAction)goStart:(id)sender {
    self.nameField.enabled = NO;
    self.startButton.enabled = NO;
    [self.activity startAnimating];
    
    //Perform server start
    [[WSAgent sharedInstance] startListeningWithCompletion:^(NSError *error) {
        [self.activity stopAnimating];
        if (!error) {
            [self performSegueWithIdentifier:@"showList" sender:self];
        }
        self.startButton.enabled = YES;
    }];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self toggleStartButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
   [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self toggleStartButton];
    return YES;
}

#pragma mark - WSAgentDelegate 

- (void)agentDidStop:(WSAgent *)agent withError:(NSError *)error {
    self.nameField.enabled = YES;
    [self toggleStartButton];
}

@end
