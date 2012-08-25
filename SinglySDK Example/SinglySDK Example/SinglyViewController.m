//
//  SinglyViewController.m
//  SinglySDK Example
//
//  Created by Thomas Muldowney on 8/22/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import "SinglyViewController.h"

@interface SinglyViewController ()
{
    SinglyLogInViewController* loginVC_;
    SinglySession* session_;
}
@end

@implementation SinglyViewController

-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"View will appear for app");
}

-(void) viewDidAppear:(BOOL)animated
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    session_ = [[SinglySession alloc] init];
    session_.delegate = self;
    NSLog(@"Session account is %@ and access token is %@", session_.accountID, session_.accessToken);
    [session_ checkReadyWithCompletionHandler:^(BOOL ready){
        if(!ready) {
            loginVC_ = [[SinglyLogInViewController alloc] initWithSession:session_ forService:kSinglyServiceFoursquare];
            loginVC_.clientID = @"<client id here>";
            loginVC_.clientSecret = @"<client secret here>";
            [self presentModalViewController:loginVC_ animated:YES];
        } else {
            NSLog(@"We're already done!");
            [session_ requestAPI:[SinglyAPIRequest apiRequestForEndpoint:@"profiles"] withCompletionHandler:^(NSError *error, id json) {
                NSLog(@"The profiles result is: %@", json);
            }];
        }
    }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - SinglySessionDelegate
-(void)singlySession:(SinglySession *)session didLogInForService:(NSString *)service;
{
    [self dismissModalViewControllerAnimated:YES];
    loginVC_ = nil;
}
-(void)singlySession:(SinglySession *)session errorLoggingInToService:(NSString *)service withError:(NSError *)error;
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [self dismissModalViewControllerAnimated:YES];
    loginVC_ = nil;
}
@end
