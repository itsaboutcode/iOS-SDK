//
//  SinglyLoginPickerViewController.m
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/29/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <Accounts/Accounts.h>
#import <QuartzCore/QuartzCore.h>

#import "SinglyConstants.h"
#import "SinglyLoginPickerViewController.h"
#import "SinglyLoginPickerServiceCell.h"

@interface SinglyLoginPickerViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
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
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicator.center = self.view.center;
        [self.activityIndicator startAnimating];
        [self.view addSubview:self.activityIndicator];
        
        // Load Services Dictionary
        NSURL *servicesURL = [NSURL URLWithString:@"https://api.singly.com/services"];
        NSURLRequest *servicesRequest = [NSURLRequest requestWithURL:servicesURL];
        [NSURLConnection sendAsynchronousRequest:servicesRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError) {
            _servicesDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
            if (!self.services)
                self.services = [self.servicesDictionary allKeys];
            [self.activityIndicator stopAnimating];
            [self.tableView reloadData];
        }];
        
    }
    else if (self.servicesDictionary && !self.services)
    {
        self.services = [self.servicesDictionary allKeys];
    }
    
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
    [self dismissViewControllerAnimated:FALSE completion:nil];
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
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

    NSURL *facebookClientIdURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.singly.com/v0/auth/%@/client_id/facebook", [[SinglySession sharedSession] clientID]]];
    NSURLRequest *facebookAppIdRequest = [NSURLRequest requestWithURL:facebookClientIdURL];
    [NSURLConnection sendAsynchronousRequest:facebookAppIdRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

        NSDictionary *options = @{
            @"ACFacebookAppIdKey": responseDictionary[@"facebook"],
            @"ACFacebookPermissionsKey": @[
                @"create_event",
                @"create_note",
                @"email",
                @"friends_about_me",
                @"friends_activities",
                @"friends_birthday",
                @"friends_checkins",
                @"friends_education_history",
                @"friends_events",
                @"friends_groups",
                @"friends_hometown",
                @"friends_interests",
                @"friends_likes",
                @"friends_location",
                @"friends_notes",
                @"friends_photos",
                @"friends_relationship_details",
                @"friends_relationships",
                @"friends_religion_politics",
                @"friends_status",
                @"friends_subscriptions",
                @"friends_videos",
                @"friends_website",
                @"friends_work_history",
                @"photo_upload",
                @"publish_actions",
                @"publish_checkins",
                @"publish_stream",
                @"read_stream",
                @"status_update",
                @"user_about_me",
                @"user_activities",
                @"user_birthday",
                @"user_checkins",
                @"user_education_history",
                @"user_events",
                @"user_groups",
                @"user_hometown",
                @"user_interests",
                @"user_likes",
                @"user_location",
                @"user_notes",
                @"user_photos",
                @"user_relationship_details",
                @"user_relationships",
                @"user_religion_politics",
                @"user_status",
                @"user_subscriptions",
                @"user_videos",
                @"user_website",
                @"user_work_history",
                @"video_upload"
            ],
            @"ACFacebookAudienceKey": ACFacebookAudienceEveryone
        };
        

        [accountStore requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError *error)
        {
            if (error)
            {
                if (error.code == ACErrorAccountNotFound)
                {
                    NSLog(@"Device is not authenticated with Facebook. Falling back...");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self authenticateWithService:kSinglyServiceFacebook];
                    });
                    return;
                }

                NSLog(@"Unhandled error: %@", error);

                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                        message:[error localizedDescription]
                                                                       delegate:self
                                                              cancelButtonTitle:@"Dismiss"
                                                              otherButtonTitles:nil];
                    [alertView show];
                });

                return;
            }
            
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            ACAccount *account = [accounts lastObject];
            
            // TODO Persist token...
            NSLog(@"%@", account.credential.oauthToken);
        }];
        
    }];
}

@end
