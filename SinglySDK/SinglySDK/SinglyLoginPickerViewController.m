//
//  SinglyLoginPickerViewController.m
//  SinglySDK
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

#import <Accounts/Accounts.h>
#import <QuartzCore/QuartzCore.h>

#import "SinglyActivityIndicatorView.h"
#import "SinglyConnection.h"
#import "SinglyConstants.h"
#import "SinglyFacebookService.h"
#import "SinglyLoginPickerServiceCell.h"
#import "SinglyLoginPickerViewController.h"
#import "SinglyLoginPickerViewController+Internal.h"
#import "SinglyRequest.h"
#import "SinglyService.h"

@implementation SinglyLoginPickerViewController

- (void)authenticateWithService:(NSString *)serviceIdentifier
{
    SinglyService *service = [SinglyService serviceWithIdentifier:serviceIdentifier];
    [service requestAuthorizationFromViewController:self withScopes:nil completion:^(BOOL isSuccessful, NSError *error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(singlyLoginPickerViewController:didLoginForService:)])
            [self.delegate singlyLoginPickerViewController:self didLoginForService:[service serviceIdentifier]];
    }];
}

- (void)authenticateWithFacebook
{
    SinglyFacebookService *facebookService = [SinglyService serviceWithIdentifier:@"facebook"];
    [facebookService requestAuthorizationFromViewController:self withScopes:nil completion:^(BOOL isSuccessful, NSError *error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(singlyLoginPickerViewController:errorLoggingInToService:withError:)])
            [self.delegate singlyLoginPickerViewController:self errorLoggingInToService:[facebookService serviceIdentifier] withError:error];
    }];
}

#pragma mark - View Callbacks

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Customize Table View Appearance
    self.tableView.rowHeight = 54;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    //
    // Observe for changes to the session profiles and update the view when
    // changes occur (such as when a session is connected or disconnected).
    //
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView
                                             selector:@selector(reloadData)
                                                 name:kSinglySessionProfilesUpdatedNotification
                                               object:nil];

    // Load Services Dictionary
    if (!self.servicesDictionary)
    {

        // Display Activity Indicator
        [SinglyActivityIndicatorView showIndicator];

        // Clear Separator
        self.originalSeparatorColor = self.tableView.separatorColor;
        self.tableView.separatorColor = [UIColor clearColor];

        // Prepare the Request
        SinglyRequest *servicesRequest = [SinglyRequest requestWithEndpoint:@"services"];
        servicesRequest.isAuthorizedRequest = NO;

        // Perform the Request
        SinglyConnection *connection = [SinglyConnection connectionWithRequest:servicesRequest];
        [connection performRequestWithCompletion:^(id responseObject, NSError *error) {

            // Dismiss the Activity Indicator
            [SinglyActivityIndicatorView dismissIndicator];

            // Check for Errors
            if (error)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                        message:[error localizedDescription]
                                                                       delegate:self
                                                              cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
                    [alertView show];
                });
                return;
            }

            // Update Services
            _servicesDictionary = responseObject;
            if (!self.services)
                self.services = [[self.servicesDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];

            // Refresh the Table View
            dispatch_async(dispatch_get_main_queue(), ^{
                self.tableView.separatorColor = self.originalSeparatorColor;
                self.originalSeparatorColor = nil;
                [self.tableView reloadData];
            });

        }];

    }
    else if (self.servicesDictionary && !self.services)
    {
        self.services = [[self.servicesDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    }

    // Reload the Table View
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [SinglyActivityIndicatorView dismissIndicator];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    //
    // Stop observing for updates to the session profiles.
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView
                                                    name:kSinglySessionProfilesUpdatedNotification
                                                  object:nil];
}

#pragma mark - Table View DataSource & Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.services.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"com.singly.SinglyLoginPickerServiceCell";
    SinglyLoginPickerServiceCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell = [[SinglyLoginPickerServiceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSString *service = self.services[indexPath.row];
    NSDictionary *serviceInfoDictionary = self.servicesDictionary[service];

    cell.serviceIdentifier = service;
    cell.serviceInfoDictionary = serviceInfoDictionary;

    if (SinglySession.sharedSession.profiles[service])
        cell.isAuthenticated = YES;
    else
        cell.isAuthenticated = NO;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *service = self.services[indexPath.row];
    self.selectedService = service;

    // Do nothing if we are already authenticated against the selected service
    if (SinglySession.sharedSession.profiles[service])
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Disconnect from %@?", self.servicesDictionary[service][@"name"]]
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Disconnect", nil];
        [alertView show];
        return;
    }
    
    // Override the standard behavior for Facebook and Twitter
    if ([service isEqualToString:@"facebook"] || [service isEqualToString:@"twitter"])
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Display the standard login view controller
    [self authenticateWithService:service];
}

#pragma mark - Alert View Delegates

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag)
    {
        case 0: // Disconnect
            switch (buttonIndex)
        {
            case 0: // Cancel
                break;
            case 1: // Disconnect
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error;
                    [[SinglyService serviceWithIdentifier:self.selectedService] disconnect:&error];
                });
                break;
        }
            break;

        default:
            break;
    }
}

#pragma mark - Singly Login View Controller Delegates

- (void)singlyLoginViewController:(SinglyLoginViewController *)controller didLoginForService:(NSString *)service
{
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)singlyLoginViewController:(SinglyLoginViewController *)controller errorLoggingInToService:(NSString *)service withError:(NSError *)error
{
    if ([error.domain isEqualToString:kSinglyErrorDomain] && error.code == kSinglyLoginAbortedErrorCode)
        return;

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Error"
                                                    message:[error localizedDescription]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
