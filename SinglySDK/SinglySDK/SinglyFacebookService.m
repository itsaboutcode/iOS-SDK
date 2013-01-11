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

#import "SinglyFacebookService.h"
#import "SinglyRequest.h"
#import "SinglyService+Internal.h"
#import "SinglySession.h"

@implementation SinglyFacebookService

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
        NSLog(@"[SinglySDK] Native Facebook auth is not available because Info.plist is not configured to handle Facebook URLs.");

    return isConfigured;
}

- (BOOL)isIntegratedAuthorizationConfigured
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
            NSLog(@"[SinglySDK] Integrated Facebook auth is not available because this device is not signed in to Facebook.");
    }

    return isConfigured;
}

- (void)requestAuthorizationFromViewController:(UIViewController *)viewController
{
    [self requestAuthorizationFromViewController:viewController withScopes:nil];
}

- (void)requestAuthorizationFromViewController:(UIViewController *)viewController withScopes:(NSArray *)scopes
{

    self.isAuthorized = NO;

    dispatch_queue_t authorizationQueue;
    authorizationQueue = dispatch_queue_create("com.singly.AuthorizationQueue", NULL);

    dispatch_async(authorizationQueue, ^{

        //
        // Step 1 - Fetch the Client ID from Singly
        //
        if (!self.clientID)
            [self fetchClientID];

        //
        // Step 2 - Attempt Integrated Authorization
        //
        if (self.clientID && !self.isAuthorized && [self isIntegratedAuthorizationConfigured])
            [self requestIntegratedAuthorization:scopes];

        //
        // Step 3 - Attempt Native Application Authorization
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
                [self requestAuthorizationViaSinglyFromViewController:viewController withScopes:scopes];
            });
        }

    });
    
}

- (void)requestIntegratedAuthorization:(NSArray *)scopes
{
    NSLog(@"[SinglySDK] Attempting integrated authorization...");

    dispatch_semaphore_t authorizationSemaphore = dispatch_semaphore_create(0);

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:@"com.apple.facebook"];

    if (!accountType)
        return;

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
                NSLog(@"[SinglySDK] Integrated authorization is not available because the device is not authenticated with Facebook. Skipping...");
                return;
            }

            NSLog(@"[SinglySDK] Unhandled error: %@", error);

            if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidFail:withError:)])
                [self.delegate singlyServiceDidFail:self withError:error];

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

        //
        // Apply the Facebook service to our current session.
        //
        SinglyRequest *request = [[SinglyRequest alloc] initWithEndpoint:@"auth/facebook/apply"];
        request.parameters = @{ @"token": account.credential.oauthToken, @"client_id": SinglySession.sharedSession.clientID, @"client_secret": SinglySession.sharedSession.clientSecret };
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError)
        {
            // TODO Assume this means the token is expired. It may not be. Need to update how errors are returned from the apply endpoint for expired tokens.
            if (((NSHTTPURLResponse *)response).statusCode != 200)
            {
                NSLog(@"Request Error: %@", requestError);
                [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
                    NSLog(@"Token is expired... Renewed! %d", renewResult);
                    NSLog(@"Error: %@", error);
                    NSLog(@"Token: %@", account.credential.oauthToken);
                    [SinglySession.sharedSession applyService:self.serviceIdentifier withToken:account.credential.oauthToken];
                }];
            }

            else
            {
                NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
                SinglySession.sharedSession.accessToken = responseDictionary[@"access_token"];
                SinglySession.sharedSession.accountID = responseDictionary[@"account"];
                [SinglySession.sharedSession updateProfilesWithCompletion:^(BOOL success)
                {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidAuthorize:)])
                        [self.delegate singlyServiceDidAuthorize:self];
                }];
            }
        }];

        //
        // We are now authorized. Do not attempt any further authorizations.
        //
        self.isAuthorized = YES;

        dispatch_semaphore_signal(authorizationSemaphore);
    }];

    dispatch_semaphore_wait(authorizationSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_release(authorizationSemaphore);
}

- (BOOL)requestApplicationAuthorization:(NSArray *)scopes
{

    NSLog(@"[SinglySDK] Attempting to authorize with the installed Facebook app...");

    NSArray *permissions = (scopes != nil) ? scopes : @[ @"email", @"user_location", @"user_birthday" ];
    NSDictionary *params = @{
        @"client_id": self.clientID,
        @"type": @"user_agent",
        @"redirect_uri": @"fbconnect://success",
        @"display": @"touch",
        @"sdk": @"ios",
        @"scope": [permissions componentsJoinedByString:@","]
    };

    NSString *urlPrefix = @"fbauth://authorize";
    NSString *fbAppUrl = [SinglyFacebookService serializeURL:urlPrefix params:params];

    BOOL isAppInstalled = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];

    if (!isAppInstalled)
        NSLog(@"[SinglySDK]   Facebook app is not installed.");
    else
    {
        [SinglySession sharedSession].authorizingService = self;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleServiceAppliedNotification:)
                                                     name:kSinglyServiceAppliedNotification
                                                   object:nil];
    }

    return isAppInstalled;

}

- (void)handleServiceAppliedNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kSinglyServiceAppliedNotification object:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidAuthorize:)])
        [self.delegate singlyServiceDidAuthorize:self];
    [SinglySession sharedSession].authorizingService = nil;
}

#pragma mark - get rid of these

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params {
    return [self serializeURL:baseUrl params:params httpMethod:@"get"];
}

+ (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params
               httpMethod:(NSString *)httpMethod {

    NSURL* parsedURL = [NSURL URLWithString:baseUrl];
    NSString* queryPrefix = parsedURL.query ? @"&" : @"?";

    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in [params keyEnumerator]) {
        id value = [params objectForKey:key];
        if ([value isKindOfClass:[UIImage class]]
            || [value isKindOfClass:[NSData class]]) {
            if ([httpMethod isEqualToString:@"get"]) {
                NSLog(@"can not use GET to upload a file");
            }
            continue;
        }

        NSString *escaped_value = [value URLEncodedString];
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
    }
    NSString* query = [pairs componentsJoinedByString:@"&"];

    return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

@end
