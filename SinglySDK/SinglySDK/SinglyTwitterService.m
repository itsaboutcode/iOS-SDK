//
//  SinglyTwitterService.m
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

#import <Twitter/Twitter.h>

#import "NSDictionary+QueryString.h"
#import "NSString+URLEncoding.h"

#import "SinglyAlertView.h"
#import "SinglyConnection.h"
#import "SinglyLog.h"
#import "SinglyRequest.h"
#import "SinglyService+Internal.h"
#import "SinglySession.h"
#import "SinglySession+Internal.h"
#import "SinglyTwitterService.h"
#import "SinglyTwitterService+Internal.h"

@implementation SinglyTwitterService

- (NSString *)serviceIdentifier
{
    return @"twitter";
}

- (BOOL)isNativeAuthorizationConfigured
{
    BOOL isConfigured = NO;

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *accounts = [accountStore accountsWithAccountType:accountType];

    if ([accounts respondsToSelector:@selector(count)])
        isConfigured = YES;

    if (!isConfigured)
        SinglyLog(@"Integrated Twitter auth is not available because this device is not signed in to Twitter.");

    return isConfigured;
}

#pragma mark - Authorization

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
        // Step 2 - Attempt Native Authorization
        //
        if (self.clientID && !self.isAuthorized && [self isNativeAuthorizationConfigured])
            [self requestNativeAuthorization:scopes];

        //
        // Step 3 - Fallback to Singly Authorization
        //
        if (!self.isAuthorized)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self requestAuthorizationViaSinglyFromViewController:viewController
                                                           withScopes:scopes
                                                           completion:completionHandler];
            });
        }

    });

}

- (void)requestNativeAuthorization:(NSArray *)scopes
{
    dispatch_semaphore_t authorizationSemaphore = dispatch_semaphore_create(0);

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    if (!accountType)
    {
        SinglyLog(@"Native Facebook authorization is not available because this device is not signed into Facebook.");
        return;
    }
    
    [accountStore requestAccessToAccountsWithType:accountType
                            withCompletionHandler:^(BOOL granted, NSError *error)
    {

        // Check for Access
        if (!granted)
        {
            SinglyLog(@"We were not granted access to the device accounts.");
            dispatch_semaphore_signal(authorizationSemaphore);
            return;
        }

        // Check for Errors
        if (error)
        {
            if (error.code == ACErrorAccountNotFound)
            {
                SinglyLog(@"Native Twitter authorization is not available because this device is not signed into Twitter.");
                dispatch_semaphore_signal(authorizationSemaphore);
                return;
            }

            SinglyLog(@"Unhandled error! %@", error);

            // Inform the Delegate
            if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidFail:withError:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate singlyServiceDidFail:self withError:error];
                });
            }

            // Display an Alert to the User
            // TODO Remove this, errors should be displayed by the consuming apps, not us...
            dispatch_async(dispatch_get_main_queue(), ^{
                SinglyAlertView *alertView = [[SinglyAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription]];
                [alertView addCancelButtonWithTitle:@"Dissmiss"];
                [alertView show];
            });

            dispatch_semaphore_signal(authorizationSemaphore);

            return;
        }

        // Select the Account
        NSArray *accounts = [accountStore accountsWithAccountType:accountType];
        __block ACAccount *account;

        if (accounts.count > 1)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(accountForTwitterAuthorization:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    account = [self.delegate accountForTwitterAuthorization:accounts];
                });
            }
            else
            {
                SinglyLog(@"You must implement the accountForTwitterAuthorization: delegate method and return the account to authorize.");
                dispatch_semaphore_signal(authorizationSemaphore);
                return;
            }
        }
        else
        {
            account = [accounts lastObject];
        }

        //
        // Request Access Token from Twitter
        //
        [self fetchAccessTokenForAccount:account completion:^(NSDictionary *accessToken, NSError *error)
        {

            // TODO Check for errors!

            id applyServiceHandler = ^(BOOL isSuccessful, NSError *applyError)
            {
                // TODO Check for errors!
                if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidAuthorize:)])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate singlyServiceDidAuthorize:self];
                    });
                }
            };

            // Apply Service to Singly
            [SinglySession.sharedSession applyService:self.serviceIdentifier
                                            withToken:accessToken[@"oauth_token"]
                                          tokenSecret:accessToken[@"oauth_token_secret"]
                                           completion:applyServiceHandler];

            dispatch_semaphore_signal(authorizationSemaphore);
        }];

        //
        // We are now authorized. Do not attempt any further authorizations.
        //
        self.isAuthorized = YES;
    }];

    dispatch_semaphore_wait(authorizationSemaphore, DISPATCH_TIME_FOREVER);
    #if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
        dispatch_release(authorizationSemaphore);
    #endif
}

#pragma mark - Reverse Authentication

- (NSString *)fetchReverseAuthParameters:(NSError **)error
{
    // Prepare the Request
    SinglyRequest *request = [SinglyRequest requestWithEndpoint:[NSString stringWithFormat:@"auth/%@/reverse_auth_parameters/%@", SinglySession.sharedSession.clientID, self.serviceIdentifier]];
    request.isAuthorizedRequest = NO;

    // Perform the Request
    NSError *requestError;
    SinglyConnection *connection = [SinglyConnection connectionWithRequest:request];
    id responseObject = [connection performRequest:&requestError];

    // Check for Errors
    if (requestError)
    {
        SinglyLog(@"A request error occurred while attempting to fetch the reverse access token from '%@': %@", request.URL, requestError);
        if (error) *error = requestError;
        return nil;
    }

    NSString *reverseAuthParameters = responseObject[self.serviceIdentifier];

    SinglyLog(@"Retrieved Reverse Auth Parameters for '%@': %@", self.serviceIdentifier, reverseAuthParameters);

    return reverseAuthParameters;
}

- (void)fetchReverseAuthParametersWithCompletion:(SinglyAuthParametersCompletionBlock)completionHandler
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSError *error;
        NSString *parameters = [self fetchReverseAuthParameters:&error];

        if (completionHandler) dispatch_sync(currentQueue, ^{
            completionHandler(parameters, error);
        });
        
    });
}

#pragma mark - Access Tokens

- (NSDictionary *)fetchAccessTokenForAccount:(ACAccount *)account error:(NSError **)error
{
    dispatch_semaphore_t accessTokenSemaphore = dispatch_semaphore_create(0);
    __block NSDictionary *accessTokenDictionary;

    // Configure the Request
    NSURL *accessTokenURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    NSString *reverseAuthParameters = [self fetchReverseAuthParameters:nil];
    NSDictionary *accessTokenParameters = @{
        @"x_reverse_auth_target": self.clientID,
        @"x_reverse_auth_parameters": reverseAuthParameters
    };
    TWRequest *accessTokenRequest = [[TWRequest alloc] initWithURL:accessTokenURL
                                                        parameters:accessTokenParameters
                                                     requestMethod:TWRequestMethodPOST];

    // Set the Account
    [accessTokenRequest setAccount:account];

    // Perform the Request
    [accessTokenRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
    {
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSDictionary dictionaryWithQueryString:responseString];

        accessTokenDictionary = responseDictionary;

        dispatch_semaphore_signal(accessTokenSemaphore);
    }];

    dispatch_semaphore_wait(accessTokenSemaphore, DISPATCH_TIME_FOREVER);
    #if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
        dispatch_release(accessTokenSemaphore);
    #endif

    return accessTokenDictionary;
}

- (void)fetchAccessTokenForAccount:(ACAccount *)account
                        completion:(SinglyTwitterAccessTokenCompletionBlock)completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        NSDictionary *accessToken = [self fetchAccessTokenForAccount:account error:&error];

        if (completionHandler) completionHandler(accessToken, error);
    });
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
