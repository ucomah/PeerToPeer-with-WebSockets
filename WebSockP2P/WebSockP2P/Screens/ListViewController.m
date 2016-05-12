//
//  ListViewController.m
//  WebSockP2P
//
//  Created by Eugene Melkov on 07.05.16.
//  Copyright © 2016 Eugene Melkov. All rights reserved.
//

#import "ListViewController.h"
#import "DevicesListTableCell.h"
#import "WSPeer.h"
#import "ChatViewController.h"

@interface ListViewController () <WSAgentDelegate>

@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Discovered devices";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WSAgent sharedInstance].delegate = self;
    [[WSAgent sharedInstance] startBonjourDiscovering];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[WSAgent sharedInstance] stopBonjourDiscovering];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - WSAgent delegate

- (void)agent:(WSAgent *)agent didAddPeer:(WSPeer *)peer {
    [self.tableView reloadData];
}

- (void)agent:(WSAgent *)agent didUpdatePeer:(WSPeer *)peer {
    [self.tableView reloadData];
}

- (void)agent:(WSAgent *)agent didRemovePeer:(WSPeer *)peer {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [WSAgent sharedInstance].allPeers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DevicesListTableCell *cell = (DevicesListTableCell*)[tableView dequeueReusableCellWithIdentifier:@"DevicesListViewCell" forIndexPath:indexPath];
    
    if (indexPath.row % 2 == 0) {
        cell.backgroundView = nil;
    }
    else {
        UIView* bg = [[UIView alloc] initWithFrame:cell.contentView.bounds];
        bg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7f];
        cell.backgroundView = bg;
    }
    
    WSPeer* peer = [[WSAgent sharedInstance].allPeers objectAtIndex:indexPath.row];
    cell.hostNameLabel.text = [peer host];
    
    [cell setIsConnected:peer.isConnected];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        void(^showDetails)(WSPeer* peer) = ^(WSPeer* peer) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //Update table
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                //Show details controller
                ChatViewController* chatScreen = [self.storyboard instantiateViewControllerWithIdentifier:@"ChatScreen"];
                chatScreen.peer = peer;
                [self.navigationController pushViewController:chatScreen animated:YES];
            });
        };
        //Connect if not connected
        WSPeer* peer = [[WSAgent sharedInstance].allPeers objectAtIndex:indexPath.row];
        if (![peer isConnected]) {
            [[WSAgent sharedInstance] connectToHost:peer.host withCompletion:^(WSPeer *peer, NSError *error) {
                if (error) {
                    [UIAlertController alertWithError:error withCompletion:nil];
                    return ;
                }
                showDetails(peer);
            }];
        }
        showDetails(peer);
    });
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
