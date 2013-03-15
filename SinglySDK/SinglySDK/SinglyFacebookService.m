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

#import "SinglyActivityIndicatorView.h"
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

@synthesize isAborted = _isAborted;
@synthesize isAuthorized = _isAuthorized;

- (NSString *)serviceIdentifier
{
    return @"facebook";
}

- (BOOL)isAppAuthorizationConfigured
{
    BOOL isConfigured = YES;

    NSDictionary *urlTypesDictionary = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    if (!urlTypesDictionary)
        isConfigured = NO;

    NSArray *urlSchemesArray = [urlTypesDictionary valueForKey:@"CFBundleURLSchemes"];
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

#pragma mark - Authorization

- (void)requestAuthorizationFromViewController:(UIViewController *)viewController
                                    withScopes:(NSArray *)scopes
                                    completion:(SinglyAuthorizationCompletionBlock)completionHandler
{

    _isAborted = NO;
    _isAuthorized = NO;

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
        if (self.clientID && !self.isAuthorized && !self.isAborted && [self isNativeAuthorizationConfigured])
            [self requestNativeAuthorizationFromViewController:viewController
                                                    withScopes:scopes
                                                    completion:completionHandler];

        //
        // Step 3 - Attempt Authorization via Facebook App
        //
        BOOL isAuthorizingViaApplication = NO;
        if (self.clientID && !self.isAuthorized && !self.isAborted && [self isAppAuthorizationConfigured])
            isAuthorizingViaApplication = [self requestApplicationAuthorization:scopes];

        //
        // Step 4 - Fallback to Singly Authorization
        //
        if (!self.isAuthorized && !self.isAborted && !isAuthorizingViaApplication)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self requestAuthorizationViaSinglyFromViewController:viewController
                                                           withScopes:scopes
                                                           completion:completionHandler];
            });
        }

    });
    
}

- (void)requestNativeAuthorizationFromViewController:(UIViewController *)viewController
                                          withScopes:(NSArray *)scopes
                                          completion:(SinglyAuthorizationCompletionBlock)completionHandler
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

    //
    // Post a notification that the authorization is being performed.
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:kSinglyServiceIsAuthorizingNotification
                                                        object:self];

    [accountStore requestAccessToAccountsWithType:accountType
                                          options:options
                                       completion:^(BOOL granted, NSError *accessError)
    {

        //
        // Check for Access
        //
        if (!granted)
        {
            SinglyLog(@"Access to the Facebook account on the device was denied.");

            // If there was an error object, it means that the user denied
            // access, so we should be in an aborted state...
            if (accessError)
            {
                _isAborted = YES;

                if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidFail:withError:)])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate singlyServiceDidFail:self withError:accessError];
                    });
                }
            }

            // If the error is nil, it means access was already denied (in
            // Settings) so we should fall-back to the next method.
            else
                _isAborted = NO;

            //
            // We do not call the callback or delegate methods because we want
            // to fallback to the standard web-based workflow.
            //

            dispatch_semaphore_signal(authorizationSemaphore);
            return;
        }

        //
        // Check for Access Errors
        //
        if (accessError)
        {
            if (accessError.code == ACErrorAccountNotFound)
            {
                SinglyLog(@"Native Facebook authorization is not available because this device is not signed into Facebook.");
                dispatch_semaphore_signal(authorizationSemaphore);
                return;
            }

            SinglyLog(@"Unhandled error! %@", accessError);

            //
            // Inform the Delegate
            //
            if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidFail:withError:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate singlyServiceDidFail:self withError:accessError];
                });
            }

            //
            // Call the Completion Handler
            //
            if (completionHandler)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(NO, accessError);
                });
            }

            dispatch_semaphore_signal(authorizationSemaphore);
            return;
        }

        NSArray *accounts = [accountStore accountsWithAccountType:accountType];
        ACAccount *account = [accounts lastObject];

        //
        // Apply the Facebook service to our current session.
        //
        NSError *applyError;
        [SinglySession.sharedSession applyService:self.serviceIdentifier
                                        withToken:account.credential.oauthToken
                                            error:&applyError];

        //
        // Handle Errors (Service, Token, etc)
        //
        if (applyError)
        {
            NSLog(@"Apply Error: %@", applyError);

            //
            // Parse Original Response from Singly
            //
            NSData *responseData = [applyError.userInfo[kSinglyResponseKey] dataUsingEncoding:NSUTF8StringEncoding];
            id responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];

            //
            // Check for Facebook Errors
            //
            if (responseObject && [responseObject isKindOfClass:[NSDictionary class]] && responseObject[@"originalError"])
            {
                NSDictionary *facebookError = responseObject[@"originalError"][@"error"];
                NSLog(@"Facebook Error: %@", facebookError);

                //
                // Handle Token Errors
                //
                if ([facebookError[@"code"] intValue] == 190)
                {
                    SinglyLog(@"Facebook token is invalid. Attempting to renew credentials...");
                    [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error)
                    {

                        // TODO Check for errors...
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSError *applyError;
                            [SinglySession.sharedSession applyService:self.serviceIdentifier
                                                            withToken:account.credential.oauthToken
                                                                error:&applyError];

                            if (applyError)
                            {
                                SinglyLog(@"Unhandled error: %@", applyError);
                                dispatch_semaphore_signal(authorizationSemaphore);
                                return;
                            }
                        });
                    }];
                }

            }
            else
            {
                dispatch_semaphore_signal(authorizationSemaphore);
                return;
            }
        }

        //
        // We are now authorized. Do not attempt any further authorizations.
        //
        _isAuthorized = YES;

        //
        // Inform the Delegate
        //
        if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidAuthorize:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate singlyServiceDidAuthorize:self];
            });
        }

        //
        // Call the Completion Handler
        //
        if (completionHandler)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(YES, nil);
            });
        }

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
