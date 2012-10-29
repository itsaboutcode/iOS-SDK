//
//  SinglyLoginPickerViewController.m
//  SinglySDK
//
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
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
#import "FacebookSDK.h"

#import "SinglyConstants.h"
#import "SinglyLoginPickerViewController.h"
#import "SinglyLoginPickerServiceCell.h"
#import "SinglyActivityIndicatorView.h"

@interface SinglyLoginPickerViewController ()

@property (nonatomic, strong) NSString *selectedService;

@end

@implementation SinglyLoginPickerViewController

-(id)initWithSession:(SinglySession *)session
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _session = session;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Load Services Dictionary
    // TODO We may want to move this to SinglySession
    if (!self.servicesDictionary)
    {
        
        // Display Activity Indicator
        [SinglyActivityIndicatorView showIndicator];

        // Load Services Dictionary
        NSURL *servicesURL = [NSURL URLWithString:@"https://api.singly.com/services"];
        NSURLRequest *servicesRequest = [NSURLRequest requestWithURL:servicesURL];
        [NSURLConnection sendAsynchronousRequest:servicesRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError) {
            _servicesDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
            if (!self.services)
                self.services = [self.servicesDictionary allKeys];

            // Dismiss the Activity Indicator
            [SinglyActivityIndicatorView dismissIndicator];

            // Reload the Table View
            [self.tableView reloadData];
        }];

        // Customize Table View Appearance
        self.tableView.rowHeight = 54;

    }
    else if (self.servicesDictionary && !self.services)
    {
        self.services = [self.servicesDictionary allKeys];
    }

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [SinglyActivityIndicatorView dismissIndicator];
}

#pragma mark - SinglySession

- (SinglySession *)session
{
    if (!_session)
        _session = [SinglySession sharedSession];
    return _session;
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
    NSDictionary *serviceInfoDictionary = [self.servicesDictionary objectForKey:service];
    cell.serviceInfoDictionary = serviceInfoDictionary;
    
    if ([self.session.profiles objectForKey:service])
        cell.authenticated = YES;
    else
        cell.authenticated = NO;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *service = [self.services objectAtIndex:indexPath.row];
    self.selectedService = service;
    
    // Do nothing if we are already authenticated against the selected service
    if ([self.session.profiles objectForKey:service])
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    // Override the standard behavior for Facebook
    if ([service isEqualToString:kSinglyServiceFacebook])
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self authenticateWithFacebook];
        return;
    }
    
    // Display the standard login view controller
    [self authenticateWithService:service];
}

#pragma mark - Singly Login View Controller delegate

- (void)singlyLoginViewController:(SinglyLoginViewController *)controller didLoginForService:(NSString *)service;
{
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)singlyLoginViewController:(SinglyLoginViewController *)controller errorLoggingInToService:(NSString *)service withError:(NSError *)error;
{
    [self dismissViewControllerAnimated:NO completion:nil];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Service-Specific Authentication

- (void)authenticateWithService:(NSString *)service
{
    SinglyLoginViewController* loginViewController = [[SinglyLoginViewController alloc] initWithSession:self.session forService:service];
    loginViewController.delegate = self;
    [self presentViewController:loginViewController animated:YES completion:NULL];
}

- (void)authenticateWithFacebook
{

    NSURL *facebookClientIdURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.singly.com/v0/auth/%@/client_id/facebook", [[SinglySession sharedSession] clientID]]];
    NSURLRequest *facebookAppIdRequest = [NSURLRequest requestWithURL:facebookClientIdURL];
    [NSURLConnection sendAsynchronousRequest:facebookAppIdRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

        NSLog(@"Retrieved Facebook ID: %@", responseDictionary[@"facebook"]);

        NSArray *permissions = @[ @"email", @"user_location", @"user_birthday" ];

        [FBSession setDefaultAppID:responseDictionary[@"facebook"]];
        [FBSession openActiveSessionWithReadPermissions:permissions
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error)
        {
            if (error)
            {
                NSLog(@"Foo: %d", [error code]);
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unable to Authorize"
                                                                    message:@"Authorization request was declined or failed."
                                                                   delegate:self
                                                          cancelButtonTitle:@"Dismiss"
                                                          otherButtonTitles:nil];
                [alertView show];
                return;
            }

            NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.singly.com/auth/facebook/apply?token=%@&client_id=%@&client_secret=%@",
                                                      [session accessToken],
                                                      [SinglySession sharedSession].clientID,
                                                      [SinglySession sharedSession].clientSecret]];

            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError)
            {
                // TODO Handle request errors
                // TODO Handle JSON parse errors
                NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
                dispatch_async(dispatch_get_current_queue(), ^{
                    [SinglySession sharedSession].accessToken = [responseDictionary objectForKey:@"access_token"];
                    [SinglySession sharedSession].accountID = [responseDictionary objectForKey:@"account"];
                    [[SinglySession sharedSession] updateProfilesWithCompletion:^{
                        NSLog(@"All set to do requests as account %@ with access token %@", [SinglySession sharedSession].accountID, [SinglySession sharedSession].accessToken);
                        [self.tableView reloadData];
                    }];
                });
            }];
       }];
    }];




//      ACAccountStore *accountStore = [[ACAccountStore alloc] init];
//      ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
//
//      NSURL *facebookClientIdURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.singly.com/v0/auth/%@/client_id/facebook", [[SinglySession sharedSession] clientID]]];
//      NSURLRequest *facebookAppIdRequest = [NSURLRequest requestWithURL:facebookClientIdURL];
//      [NSURLConnection sendAsynchronousRequest:facebookAppIdRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
//
//        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
//        NSArray *permissions = @[ @"email", @"user_location", @"user_birthday" ];
//        NSDictionary *options = @{
//            @"ACFacebookAppIdKey": responseDictionary[@"facebook"],
//            @"ACFacebookPermissionsKey": permissions,
//            @"ACFacebookAudienceKey": ACFacebookAudienceEveryone
//        };
//
//        NSLog(@"Blah: %@",  responseDictionary[@"facebook"]);
//
//        [accountStore requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError *error)
//        {
//            if (error)
//            {
//                if (error.code == ACErrorAccountNotFound)
//                {
//                    NSLog(@"Device is not authenticated with Facebook. Falling back...");
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [self authenticateWithService:kSinglyServiceFacebook];
//                    });
//                    return;
//                }
//
//                NSLog(@"Unhandled error: %@", error);
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                        message:[error localizedDescription]
//                                                                       delegate:self
//                                                              cancelButtonTitle:@"Dismiss"
//                                                              otherButtonTitles:nil];
//                    [alertView show];
//                });
//
//                return;
//            }
//            
//            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
//            ACAccount *account = [accounts lastObject];
//
//          NSLog(@"Received Token from Facebook... %@", account.credential.oauthToken);
//
//            NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.singly.com/auth/facebook/apply?token=%@&client_id=%@&client_secret=%@",
//                                                      account.credential.oauthToken,
//                                                      [SinglySession sharedSession].clientID,
//                                                      [SinglySession sharedSession].clientSecret]];
//
//            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
//            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError)
//            {
//                // TODO Handle request errors
//                // TODO Handle JSON parse errors
//                NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
//                dispatch_async(dispatch_get_current_queue(), ^{
//
//
//                  NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
//                  NSLog(@"Apply Resplonse: %@", responseString);
//                  NSLog(@"Apply Resplonse: %@", responseDictionary);
//                    [SinglySession sharedSession].accessToken = [responseDictionary objectForKey:@"access_token"];
//                    [SinglySession sharedSession].accountID = [responseDictionary objectForKey:@"account"];
//                    [[SinglySession sharedSession] updateProfilesWithCompletion:^{
//                        NSLog(@"All set to do requests as account %@ with access token %@", [SinglySession sharedSession].accountID, [SinglySession sharedSession].accessToken);
//                        [self.tableView reloadData];
//                    }];
//                });
//            }];
//        }];
//    }];
}

@end
