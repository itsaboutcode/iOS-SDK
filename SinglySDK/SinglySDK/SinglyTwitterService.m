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

#import "SinglyConnection.h"
#import "SinglyLog.h"
#import "SinglyRequest.h"
#import "SinglyService+Internal.h"
#import "SinglySession.h"
#import "SinglySession+Internal.h"
#import "SinglyTwitterService.h"

@implementation SinglyTwitterService

- (BOOL)isIntegratedAuthorizationConfigured
{
    BOOL isConfigured = NO;

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    // iOS 5+
    if (accountType)
    {
        NSArray *accounts = [accountStore accountsWithAccountType:accountType];

        NSLog(@"Accounts: %@", accounts);

        if ([accounts respondsToSelector:@selector(count)])
            isConfigured = YES;

        if (!isConfigured)
            SinglyLog(@"Integrated Twitter auth is not available because this device is not signed in to Twitter.");
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
            [self fetchClientID:nil];

        //
        // Step 2 - Attempt Integrated Authorization
        //
        if (self.clientID && !self.isAuthorized && [self isIntegratedAuthorizationConfigured])
            [self requestIntegratedAuthorization:scopes];

        //
        // Step 3 - Fallback to Singly Authorization
        //
        if (!self.isAuthorized)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self requestAuthorizationViaSinglyFromViewController:viewController withScopes:scopes];
            });
        }

    });

}

- (void)requestIntegratedAuthorization:(NSArray *)scopes
{
    SinglyLog(@"Attempting integrated authorization...");

    dispatch_semaphore_t authorizationSemaphore = dispatch_semaphore_create(0);

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    if (!accountType)
    {
        SinglyLog(@"  No integrated accounts available.");
        return;
    }

    [accountStore requestAccessToAccountsWithType:accountType
                                          options:nil
                                       completion:^(BOOL granted, NSError *error)
    {

        NSLog(@"Granted? %d %@", granted, error);

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
                SinglyLog(@"Integrated authorization is not available because the device is not authenticated with Twitter.");
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

            dispatch_semaphore_signal(authorizationSemaphore);

            return;
        }

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

        // Select the Account
        #warning Implement a UI for slecting the Twitter account to use...
        NSArray *accounts = [accountStore accountsWithAccountType:accountType];
        ACAccount *account = [accounts lastObject];
        [accessTokenRequest setAccount:account];

        // Perform the Request
        [accessTokenRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
        {
            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSDictionary *responseDictionary = [NSDictionary dictionaryWithQueryString:responseString];

            NSLog(@"Response: %@", responseString);
            
            NSError *applyError;
            [SinglySession.sharedSession applyService:@"twitter"
                                            withToken:responseDictionary[@"oauth_token"]
                                          tokenSecret:responseDictionary[@"oauth_token_secret"]
                                                error:&applyError];

//        //
//    // Apply the Twitter service to our current session.
//    //
//SinglyRequest *request = [[SinglyRequest alloc] initWithEndpoint:@"auth/twitter/apply"];
//request.parameters = @{
//@"token": account.credential.oauthToken,
//@"client_id": SinglySession.sharedSession.clientID,
//@"client_secret": SinglySession.sharedSession.clientSecret
//};


            }];

         //         NSError *requestError;
         //         SinglyConnection *connection = [SinglyConnection connectionWithRequest:request];
         //         id responseObject = [connection performRequest:&requestError];
         //
         //         NSLog(@"Request Error: %@", requestError);
         //
         //         //        // TODO Assume this means the token is expired. It may not be. Need to update how errors are returned from the apply endpoint for expired tokens.
         //         //        if (((NSHTTPURLResponse *)response).statusCode != 200)
         //         //        {
         //         //            NSLog(@"Request Error: %@", requestError);
         //         //            [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
         //         //                NSLog(@"Token is expired... Renewed! %d", renewResult);
         //         //                NSLog(@"Error: %@", error);
         //         //                NSLog(@"Token: %@", account.credential.oauthToken);
         //         //                NSError *applyError;
         //         //                [SinglySession.sharedSession applyService:self.serviceIdentifier withToken:account.credential.oauthToken error:&applyError];
         //         //                if (applyError)
         //         //                {
         //         //                    // TODO Handle errors!
         //         //                }
         //         //            }];
         //         //        }
         //
         //         SinglySession.sharedSession.accessToken = responseObject[@"access_token"];
         //         SinglySession.sharedSession.accountID = responseObject[@"account"];
         //
         //         dispatch_async(dispatch_get_main_queue(), ^{
         //             [SinglySession.sharedSession updateProfilesWithCompletion:^(BOOL isSuccessful, NSError *error)
         //              {
         //                  if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidAuthorize:)])
         //                      [self.delegate singlyServiceDidAuthorize:self];
         //              }];
         //         });
         
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

- (void)handleServiceAppliedNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kSinglyServiceAppliedNotification object:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidAuthorize:)])
        [self.delegate singlyServiceDidAuthorize:self];
    [SinglySession sharedSession].authorizingService = nil;
}

//#pragma mark - get rid of these
//
//+ (NSString *)serializeURL:(NSString *)baseUrl
//                    params:(NSDictionary *)params {
////    return [self serializeURL:baseUrl params:params httpMethod:@"get"];
//}
//
//+ (NSString*)serializeURL:(NSString *)baseUrl
//                   params:(NSDictionary *)params
//               httpMethod:(NSString *)httpMethod {
//
////    NSURL* parsedURL = [NSURL URLWithString:baseUrl];
////    NSString* queryPrefix = parsedURL.query ? @"&" : @"?";
////    
////    NSMutableArray* pairs = [NSMutableArray array];
////    for (NSString* key in [params keyEnumerator]) {
////        id value = [params objectForKey:key];
////        if ([value isKindOfClass:[UIImage class]]
////            || [value isKindOfClass:[NSData class]]) {
////            if ([httpMethod isEqualToString:@"get"]) {
////                NSLog(@"can not use GET to upload a file");
////            }
////            continue;
////        }
////        
////        NSString *escaped_value = [value URLEncodedString];
////        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
////    }
////    NSString* query = [pairs componentsJoinedByString:@"&"];
////
////    return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
//}
//

- (NSString *)fetchReverseAuthParameters:(NSError **)error
{

    // If we already have the Client ID, do not attempt to fetch it again...
//    if (self.clientID) return self.clientID;

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

- (void)fetchReverseAuthParametersWithCompletion:(void (^)(NSString *accessToken, NSError *error))completionHandler
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSError *error;
        NSString *accessToken = [self fetchReverseAuthParameters:&error];

        if (completionHandler) dispatch_sync(currentQueue, ^{
            completionHandler(accessToken, error);
        });
        
    });
}

@end
