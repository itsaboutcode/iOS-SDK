//
//  SinglyFacebookService.m
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

#import "NSDictionary+QueryString.h"
#import "NSString+URLEncoding.h"

#import "SinglyAlertView.h"
#import "SinglyConnection.h"
#import "SinglyFacebookService.h"
#import "SinglyFacebookService+Internal.h"
#import "SinglyLog.h"
#import "SinglyRequest.h"
#import "SinglyService+Internal.h"
#import "SinglySession.h"
#import "SinglySession+Internal.h"

@implementation SinglyFacebookService

- (NSString *)serviceIdentifier
{
    return @"facebook";
}

#pragma mark -

- (BOOL)isAppAuthorizationConfigured
{
    BOOL isConfigured = YES;

    NSDictionary *urlTypesDictionary = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    if (!urlTypesDictionary)
        isConfigured = NO;

    NSArray *urlSchemesArray = urlTypesDictionary[@"CFBundleURLSchemes"];
    if (!urlSchemesArray)
        isConfigured = NO;
    else
        urlSchemesArray = urlSchemesArray[0];

    for (NSString *urlScheme in urlSchemesArray)
    {
        if ([urlScheme hasPrefix:@"fb"])
        {
            isConfigured = YES;
            break;
        }
        else
            isConfigured = NO;
    }

    if (!isConfigured)
        SinglyLog(@"Authorization via the installed Facebook app is not available because your Info.plist is not configured to handle Facebook URLs.");

    return isConfigured;
}

- (BOOL)isNativeAuthorizationConfigured
{
    BOOL isConfigured = NO;

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:@"com.apple.facebook"];

    // iOS 6+
    if (accountType)
    {
        NSArray *accounts = [accountStore accountsWithAccountType:accountType];

        if ([accounts respondsToSelector:@selector(count)])
            isConfigured = YES;

        if (!isConfigured)
            SinglyLog(@"Native Facebook authorization is not available because this device is not signed into Facebook.");
    }

    return isConfigured;
}

#pragma mark - Requesting Authorization

- (void)requestAuthorizationFromViewController:(UIViewController *)viewController
                                    withScopes:(NSArray *)scopes
                                    completion:(SinglyAuthorizationCompletionBlock)completionHandler
{

    self.isAuthorized = NO;

    dispatch_queue_t authorizationQueue;
    authorizationQueue = dispatch_queue_create("com.singly.AuthorizationQueue", NULL);

    dispatch_async(authorizationQueue, ^{

        //
        // Step 1 - Fetch the Client ID from Singly
        //
        if (!self.clientID)
            [self fetchClientID:nil];

        //
        // Step 2 - Attempt Native Authorization (iOS 6+)
        //
        if (self.clientID && !self.isAuthorized && [self isNativeAuthorizationConfigured])
            [self requestNativeAuthorization:scopes];

        //
        // Step 3 - Attempt Authorization via Facebook App
        //
        BOOL isAuthorizingViaApplication = NO;
        if (self.clientID && !self.isAuthorized && [self isAppAuthorizationConfigured])
            isAuthorizingViaApplication = [self requestApplicationAuthorization:scopes];

        //
        // Step 4 - Fallback to Singly Authorization
        //
        if (!self.isAuthorized && !isAuthorizingViaApplication)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self requestAuthorizationViaSinglyFromViewController:viewController withScopes:scopes completion:completionHandler];
            });
        }

    });
    
}

- (void)requestNativeAuthorization:(NSArray *)scopes
{
    dispatch_semaphore_t authorizationSemaphore = dispatch_semaphore_create(0);

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:@"com.apple.facebook"];

    if (!accountType)
    {
        SinglyLog(@"Native Facebook authorization is not available because this device is not signed into Facebook.");
        return;
    }

    NSArray *permissions = (scopes != nil) ? scopes : @[ @"email", @"user_location", @"user_birthday" ];
    NSDictionary *options = @{
        @"ACFacebookAppIdKey": self.clientID,
        @"ACFacebookPermissionsKey": permissions,
        @"ACFacebookAudienceKey": @"everyone"
    };

    [accountStore requestAccessToAccountsWithType:accountType
                                          options:options
                                       completion:^(BOOL granted, NSError *error)
    {
        if (error)
        {
            if (error.code == ACErrorAccountNotFound)
            {
                SinglyLog(@"Native Facebook authorization is not available because this device is not signed into Facebook.");
                return;
            }

            SinglyLog(@"Unhandled error! %@", error);

            // Inform the Delegate
            if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidFail:withError:)])
                [self.delegate singlyServiceDidFail:self withError:error];

            // Display an Alert to the User
            // TODO Remove this, errors should be displayed by the consuming apps, not us...
            dispatch_async(dispatch_get_main_queue(), ^{
                SinglyAlertView *alertView = [[SinglyAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription]];
                [alertView addCancelButtonWithTitle:@"Dismiss"];
                [alertView show];
            });

            return;
        }

        NSArray *accounts = [accountStore accountsWithAccountType:accountType];
        ACAccount *account = [accounts lastObject];

        //
        // Apply the Facebook service to our current session.
        //
        SinglyRequest *request = [SinglyRequest requestWithEndpoint:@"auth/facebook/apply"];
        request.parameters = @{
            @"token": account.credential.oauthToken,
            @"client_id": SinglySession.sharedSession.clientID,
            @"client_secret": SinglySession.sharedSession.clientSecret
        };

        NSError *requestError;
        SinglyConnection *connection = [SinglyConnection connectionWithRequest:request];
        id responseObject = [connection performRequest:&requestError];

//        NSLog(@"Request Error: %@", requestError);
//
//        // TODO Assume this means the token is expired. It may not be. Need to update how errors are returned from the apply endpoint for expired tokens.
//        if (((NSHTTPURLResponse *)response).statusCode != 200)
//        {
//            NSLog(@"Request Error: %@", requestError);
//            [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
//                NSLog(@"Token is expired... Renewed! %d", renewResult);
//                NSLog(@"Error: %@", error);
//                NSLog(@"Token: %@", account.credential.oauthToken);
//                NSError *applyError;
//                [SinglySession.sharedSession applyService:self.serviceIdentifier withToken:account.credential.oauthToken error:&applyError];
//                if (applyError)
//                {
//                    // TODO Handle errors!
//                }
//            }];
//        }

        SinglySession.sharedSession.accessToken = responseObject[@"access_token"];
        SinglySession.sharedSession.accountID = responseObject[@"account"];

        dispatch_async(dispatch_get_main_queue(), ^{
            [SinglySession.sharedSession updateProfilesWithCompletion:^(BOOL isSuccessful, NSError *error)
            {
                if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidAuthorize:)])
                    [self.delegate singlyServiceDidAuthorize:self];
            }];
        });

        //
        // We are now authorized. Do not attempt any further authorizations.
        //
        self.isAuthorized = YES;

        dispatch_semaphore_signal(authorizationSemaphore);
    }];

    dispatch_semaphore_wait(authorizationSemaphore, DISPATCH_TIME_FOREVER);
    #if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
        dispatch_release(authorizationSemaphore);
    #endif
}

- (BOOL)requestApplicationAuthorization:(NSArray *)scopes
{
    NSArray *permissions = (scopes != nil) ? scopes : @[ @"email", @"user_location", @"user_birthday" ];
    NSDictionary *params = @{
        @"client_id": self.clientID,
        @"type": @"user_agent",
        @"redirect_uri": @"fbconnect://success",
        @"display": @"touch",
        @"sdk": @"ios",
        @"scope": [permissions componentsJoinedByString:@","]
    };

    NSString *facebookAppURL = [NSString stringWithFormat:@"fbauth://authorize?%@", [params queryStringValue]];
    BOOL isAppInstalled = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:facebookAppURL]];

    if (!isAppInstalled)
    {
        SinglyLog(@"Authorization via the Facebook app is not possible because the Facebook app is not installed.");
    }
    else
    {
        SinglyLog(@"Attempting to authorize via the installed Facebook app...");

        [SinglySession sharedSession].authorizingService = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleServiceAppliedNotification:)
                                                     name:kSinglyServiceAppliedNotification
                                                   object:nil];
    }

    return isAppInstalled;
}

#pragma mark - Notifications

- (void)handleServiceAppliedNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kSinglyServiceAppliedNotification object:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidAuthorize:)])
        [self.delegate singlyServiceDidAuthorize:self];
    [SinglySession sharedSession].authorizingService = nil;
}

@end
