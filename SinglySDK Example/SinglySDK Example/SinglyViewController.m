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
    NSLog(@"View did appear");
    [session_ checkReadyWithCompletionHandler:^(BOOL ready){
        if(!ready) {
            loginVC_ = [[SinglyLogInViewController alloc] initWithSession:session_ forService:kSinglyServiceFoursquare];
            loginVC_.clientID = @"5ed51f6c9760d9faa499c793611d2cd3";
            loginVC_.clientSecret = @"ac2f8fafa8463e2f1322883bc17f51ec";
            [self presentModalViewController:loginVC_ animated:YES];
        } else {
            NSLog(@"We're already done!");
            [session_ requestAPI:@"profiles" withParameters:nil];
        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    session_ = [[SinglySession alloc] init];
    session_.delegate = self;
    session_.accessToken = nil;
    session_.accountID = nil;
    NSLog(@"Session account is %@ and access token is %@", session_.accountID, session_.accessToken);
	// Do any additional setup after loading the view, typically from a nib.
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
-(void)singlySession:(SinglySession*)session resultForAPI:(NSString *)api withJSON:(id)json;
{
    NSLog(@"Got a result for %@:\n%@", api, json);
}
-(void)singlySession:(SinglySession*)session errorForAPI:(NSString *)api withError:(NSError *)error;
{
    NSLog(@"Error for api(%@): %@", api, error);
}
-(void)singlySession:(SinglySession *)session didLogInForService:(NSString *)service;
{
    [self dismissModalViewControllerAnimated:loginVC_];
    loginVC_ = nil;
}
-(void)singlySession:(SinglySession *)session errorLoggingInToService:(NSString *)service withError:(NSError *)error;
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}
@end
