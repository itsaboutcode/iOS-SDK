//
//  SinglyViewController.m
//  SinglySDK Example
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

#import "SinglyViewController.h"
#import <Accounts/Accounts.h>
#include "ClientKeys.h"

@interface SinglyViewController ()
{
    SinglyLoginPickerViewController* _picker;
    SinglyLogInViewController* loginVC_;
    SinglySession* session_;
}
@end

@implementation SinglyViewController

-(void)viewWillAppear:(BOOL)animated
{
}

-(void) viewDidAppear:(BOOL)animated
{
    [session_ startSessionWithCompletionHandler:^(BOOL ready) {
        
        NSLog(@"Ready is %d", ready);
        //_picker = [[SinglyLoginPickerViewController alloc] initWithSession:session_];
        //[self presentModalViewController:_picker animated:YES];
        
        if (ready) {
            SinglyFriendModel* friendModel = [[SinglyFriendModel alloc] initWithSession:session_];
            [friendModel fetchDataWithCompletionHandler:^(NSError *err) {
                NSLog(@"Got %d friends", friendModel.friends.count);
            }];
#if 0
            SinglySharingViewController* sharingView = [[SinglySharingViewController alloc] initWithSession:session_ forService:kSinglyServiceTwitter];
            //[sharingView addImage:[UIImage imageNamed:@"typing.gif"]];
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
            [self presentModalViewController:sharingView animated:YES];
#endif
        } else {
            SinglyLoginViewController* login = [[SinglyLoginViewController alloc] initWithSession:session_ forService:kSinglyServiceTwitter];
            login.delegate = self;
            [self presentModalViewController:login animated:YES];
        }
        
        if(ready) {

#if 0
            SinglyFriendPickerViewController* friendPicker = [[SinglyFriendPickerViewController alloc] initWithSession:session_];
            [self presentModalViewController:friendPicker animated:YES];
            NSLog(@"We're already done!");
            [session_ requestAPI:[SinglyAPIRequest apiRequestForEndpoint:@"profiles"] withCompletionHandler:^(NSError *error, id json) {
                NSLog(@"The profiles result is: %@", json);
            }];
#endif
        }
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    session_ = [[SinglySession alloc] init];
    session_.delegate = self;
    session_.clientID = CLIENT_ID;
    session_.clientSecret = CLIENT_SECRET;
    NSLog(@"Session account is %@ and access token is %@", session_.accountID, session_.accessToken);
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
    NSLog(@"All done, telling it to dismiss");
}
-(void)singlySession:(SinglySession *)session errorLoggingInToService:(NSString *)service withError:(NSError *)error;
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - SinglyLoginViewControllerDelegate
-(void)singlyLoginViewController:(SinglyLoginViewController *)controller didLoginForService:(NSString *)service;
{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)singlyLoginViewController:(SinglyLoginViewController *)controller errorLoggingInToService:(NSString *)service withError:(NSError *)error
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}
@end
