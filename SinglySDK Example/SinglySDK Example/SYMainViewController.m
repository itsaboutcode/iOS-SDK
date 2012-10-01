//
//  SYMainViewController.m
//  SinglySDK Example
//
//  Created by Justin Mecham on 10/1/12.
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//

#import "SYMainViewController.h"

@interface SYMainViewController ()

@end

@implementation SYMainViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ServicesSegue"])
    {
        SinglyLoginPickerViewController *loginPickerViewController = (SinglyLoginPickerViewController *)segue.destinationViewController;
        loginPickerViewController.session = self.session;
    }
}

// TODO Use the session from the forthcoming singleton
- (SinglySession *)session
{
    if (!_session)
    {
        _session = [[SinglySession alloc] init];
//        _session.delegate = self;
        _session.clientID = CLIENT_ID;
        _session.clientSecret = CLIENT_SECRET;
    }
    NSLog(@"Session account is %@ and access token is %@", _session.accountID, _session.accessToken);
    return _session;
}

@end
