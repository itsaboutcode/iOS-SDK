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
#import "SinglyConstants.h"
#import "SinglyFacebookService.h"
#import "SinglyLoginPickerServiceCell.h"
#import "SinglyLoginPickerViewController.h"
#import "SinglyLoginPickerViewController+Internal.h"
#import "SinglyRequest.h"
#import "SinglyService.h"

@implementation SinglyLoginPickerViewController

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
    [[NSNotificationCenter defaultCenter] addObserverForName:kSinglySessionProfilesUpdatedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notification)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];

    // Load Services Dictionary
    // TODO We may want to move this to SinglySession
    if (!self.servicesDictionary)
    {

        // Display Activity Indicator
        [SinglyActivityIndicatorView showIndicator];

        // Clear Separator
        self.originalSeparatorColor = self.tableView.separatorColor;
        self.tableView.separatorColor = [UIColor clearColor];

        // Configure the Services Request
        SinglyRequest *servicesRequest = [SinglyRequest requestWithEndpoint:@"services"];
        servicesRequest.isAuthorizedRequest = NO;

        // Load Services Dictionary
        [NSURLConnection sendAsynchronousRequest:servicesRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError)
        {
            if (requestError)
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:[requestError localizedDescription]
                                                                   delegate:self
                                                          cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
                [alertView show];
                return;
            }

            _servicesDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
            if (!self.services)
                self.services = [[self.servicesDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];

            // Dismiss the Activity Indicator
            [SinglyActivityIndicatorView dismissIndicator];

            // Restore Separator Colors
            self.tableView.separatorColor = self.originalSeparatorColor;
            self.originalSeparatorColor = nil;

            // Reload the Table View
            [self.tableView reloadData];
        }];

    }
    else if (self.servicesDictionary && !self.services)
    {
        self.services = [[self.servicesDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    }
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
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kSinglySessionProfilesUpdatedNotification
                                                  object:nil];
}

#pragma mark - Table View

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
    
    NSString *service = [self.services objectAtIndex:indexPath.row];
    cell.serviceIdentifier = service;
    NSDictionary *serviceInfoDictionary = [self.servicesDictionary objectForKey:service];
    cell.serviceInfoDictionary = serviceInfoDictionary;

    if ([SinglySession.sharedSession.profiles objectForKey:service])
        cell.isAuthenticated = YES;
    else
        cell.isAuthenticated = NO;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *service = [self.services objectAtIndex:indexPath.row];
    self.selectedService = service;

    // Do nothing if we are already authenticated against the selected service
    if ([SinglySession.sharedSession.profiles objectForKey:service])
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
    
    // Override the standard behavior for Facebook
    if ([service isEqualToString:@"facebook"])
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self authenticateWithFacebook];
        return;
    }
    
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
                        [[SinglyService serviceWithIdentifier:self.selectedService] disconnectWithCompletion:^(BOOL isSuccessful)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.tableView reloadData];
                            });
                        }];
                    });
                    break;
            }
            break;

        default:
            break;
    }
}

#pragma mark - Singly Login View Controller delegate

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

#pragma mark - Service-Specific Authentication

- (void)authenticateWithService:(NSString *)serviceIdentifier
{
    SinglyService *service = [SinglyService serviceWithIdentifier:serviceIdentifier];
    service.delegate = self;
    [service requestAuthorizationFromViewController:self];
}

- (void)authenticateWithFacebook
{
    SinglyFacebookService *facebookService = [SinglyService serviceWithIdentifier:@"facebook"];
    facebookService.delegate = self;
    [facebookService requestAuthorizationFromViewController:self];
}

#pragma mark - Singly Service Delegates

- (void)singlyServiceDidAuthorize:(SinglyService *)service
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(singlyLoginPickerViewController:didLoginForService:)])
        [self.delegate singlyLoginPickerViewController:self didLoginForService:[service serviceIdentifier]];
}

- (void)singlyServiceDidFail:(SinglyService *)service withError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(singlyLoginPickerViewController:errorLoggingInToService:withError:)])
        [self.delegate singlyLoginPickerViewController:self errorLoggingInToService:[service serviceIdentifier] withError:error];
}

@end
