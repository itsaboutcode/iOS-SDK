//
//  SinglyFacebookService.m
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
#import "NSDictionary+QueryString.h"
#import "NSString+URLEncoded.h"
#import "SinglySession.h"
#import "SinglyFacebookService.h"

@implementation SinglyFacebookService

- (BOOL)appAuthorizationConfigured
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

- (BOOL)integratedAuthorizationConfigured
{
    BOOL isConfigured = NO;

    // TODO Need to update this method to work correctly on iOS 5 (i.e. return NO)

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    NSArray *accounts = [accountStore accountsWithAccountType:accountType];

    if ([accounts respondsToSelector:@selector(count)])
        isConfigured = YES;

    if (!isConfigured)
        NSLog(@"[SinglySDK] Integrated Facebook auth is not available because this device is not signed in to Facebook.");
    
    return isConfigured;
}

- (void)requestAuthorizationWithViewController:(UIViewController *)viewController
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
        if (!self.isAuthorized && [self integratedAuthorizationConfigured])
            [self requestIntegratedAuthorization];

        //
        // Step 3 - Attempt Native Application Authorization
        //
        BOOL isAuthorizingViaApplication = NO;
        if (!self.isAuthorized && [self appAuthorizationConfigured])
            isAuthorizingViaApplication = [self requestApplicationAuthorization];

        //
        // Step 4 - Fallback to Singly Authorization
        //
        if (!self.isAuthorized && !isAuthorizingViaApplication)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self requestAuthorizationViaSinglyWithViewController:viewController];
            });
        }

    });
    
}

- (void)requestIntegratedAuthorization
{
    NSLog(@"[SinglySDK] Attempting integrated authorization...");

    dispatch_semaphore_t authorizationSemaphore = dispatch_semaphore_create(0);

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

    NSArray *permissions = @[ @"email", @"user_location", @"user_birthday" ];
    NSDictionary *options = @{
        @"ACFacebookAppIdKey": self.clientID,
        @"ACFacebookPermissionsKey": permissions,
        @"ACFacebookAudienceKey": ACFacebookAudienceEveryone
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
        NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.singly.com/auth/facebook/apply?token=%@&client_id=%@&client_secret=%@",
                                                  account.credential.oauthToken,
                                                  [SinglySession sharedSession].clientID,
                                                  [SinglySession sharedSession].clientSecret]];

        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError)
        {
            // TODO Assume this means the token is expired. It may not be. Need to update how errors are returned from the apply endpoint for expired tokens.
            if (((NSHTTPURLResponse *)response).statusCode != 200)
            {
                [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
                    NSLog(@"Token is expired... Renewed!");
                    [[SinglySession sharedSession] applyService:self.serviceIdentifier withToken:account.credential.oauthToken];
                }];
            }

            else
            {
                NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
                [SinglySession sharedSession].accessToken = [responseDictionary objectForKey:@"access_token"];
                [SinglySession sharedSession].accountID = [responseDictionary objectForKey:@"account"];
                [[SinglySession sharedSession] updateProfiles];
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

- (BOOL)requestApplicationAuthorization
{

    NSLog(@"[SinglySDK] Attempting to authorize with the installed Facebook app...");

    NSArray *permissions = @[ @"email", @"user_location", @"user_birthday" ];
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

    return isAppInstalled;

}

- (void)requestAuthorizationViaSinglyWithViewController:(UIViewController *)viewController
{

    SinglyLoginViewController *loginViewController = [[SinglyLoginViewController alloc] initWithSession:[SinglySession sharedSession] forService:@"facebook"];
    loginViewController.delegate = self;
    [viewController presentModalViewController:loginViewController animated:YES];

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

#pragma mark - Login View Controller Delegates

- (void)singlyLoginViewController:(SinglyLoginViewController *)controller didLoginForService:(NSString *)service
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)singlyLoginViewController:(SinglyLoginViewController *)controller errorLoggingInToService:(NSString *)service withError:(NSError *)error
{
    [controller dismissViewControllerAnimated:NO completion:nil];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
