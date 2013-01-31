//
//  SinglyMainViewController.m
//  SinglySDK Example
//
//  Copyright (c) 2012-2013 Singly, Inc. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "SinglyMainViewController.h"

@implementation SinglyMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Override the default background
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background"]];
}

- (void)viewWillAppear:(BOOL)animated
{

    // Observe for changes to the profile data on the Singly session so that we
    // can active (or deactivate) the examples.
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView
                                             selector:@selector(reloadData)
                                                 name:kSinglySessionProfilesUpdatedNotification
                                               object:nil];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];

    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kSinglySessionProfilesUpdatedNotification
                                                  object:nil];

    [super viewDidDisappear:animated];
}

#pragma mark - Table View Data Source

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
//    if (section == 0 && ![SinglySession sharedSession].accessToken)
//    {
//        return @"You must authenticate with a service to access the following examples";
//    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    SinglySession *session = SinglySession.sharedSession;
    
    // Enable or disable table view cells based on the current application
    // and Singly session state.

    switch (indexPath.section)
    {
        // Examples
        case 1:
            if (session.isReady && session.profiles)
            {
                cell.userInteractionEnabled = YES;
                cell.textLabel.alpha = 1.0;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else
            {
                cell.userInteractionEnabled = NO;
                cell.textLabel.alpha = 0.25;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;

        // Sync Contacts
        case 2:
            if (session.isReady && !session.isSyncingDeviceContacts)
            {
                cell.userInteractionEnabled = YES;
                cell.textLabel.alpha = 1.0;
            }
            else
            {
                cell.userInteractionEnabled = NO;
                cell.textLabel.alpha = 0.25;
            }
            break;

        // Reset Application
        case 3:
            if (session.isReady)
            {
                cell.userInteractionEnabled = YES;
                cell.textLabel.alpha = 1.0;
            }
            else
            {
                cell.userInteractionEnabled = NO;
                cell.textLabel.alpha = 0.25;
            }
            break;

        default:
            break;
    }

    return cell;
}

#pragma mark - Table View Delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section)
    {
        // Sync Contacts
        case 2:
            [self syncContacts];
            break;

        // Reset Application
        case 3:
            [self resetApplicationState];
            break;

        default:
            break;
    }

}

#pragma mark -

- (void)syncContacts
{
    NSLog(@"Syncing Device Contacts with Singly API...");

    // Tell the current Singly Session to sync the contacts.
    [SinglySession.sharedSession syncDeviceContactsWithCompletion:^(BOOL isSuccessful, NSError *error) {

        // Reload the table view to re-enable the "Sync Contacts" option.
        [self.tableView reloadData];

        UIAlertView *notificationAlert = [[UIAlertView alloc] initWithTitle:@"Contacts Synced"
                                                                    message:[NSString stringWithFormat:@"Synced contacts with the Singly API."]
                                                                   delegate:self
                                                          cancelButtonTitle:@"Dismiss"
                                                          otherButtonTitles:nil];
        [notificationAlert show];

    }];

    // Reload the table view so that the "Sync Contacts" option will become
    // disabled...
    [self.tableView reloadData];
}

- (void)resetApplicationState
{

    NSLog(@"Resetting Application State ...");

    // Delete Cookies
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies])
        [storage deleteCookie:cookie];

    // Reset Session
    [SinglySession.sharedSession resetSession];

}

@end
