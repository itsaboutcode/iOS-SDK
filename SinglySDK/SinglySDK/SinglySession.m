//
//  SinglySession.m
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

#import "NSURL+AccessToken.h"
#import "SinglyFacebookService.h"
#import "SinglySession.h"

static NSString *kSinglyAccountIDKey = @"com.singly.accountID";
static NSString *kSinglyAccessTokenKey = @"com.singly.accessToken";

@implementation SinglySession

static SinglySession *sharedInstance = nil;

+ (SinglySession*)sharedSession
{
    if (sharedInstance == nil)
        sharedInstance = [[SinglySession alloc] init];
    return sharedInstance;
}

- (void)setAccountID:(NSString *)accountID
{
    [[NSUserDefaults standardUserDefaults] setValue:accountID forKey:kSinglyAccountIDKey];
}

- (NSString *)accountID
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kSinglyAccountIDKey];
}

- (void)setAccessToken:(NSString *)accessToken
{
    [[NSUserDefaults standardUserDefaults] setValue:accessToken forKey:kSinglyAccessTokenKey];
}

- (NSString *)accessToken
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kSinglyAccessTokenKey];
}

- (void)startSessionWithCompletionHandler:(void (^)(BOOL))block
{
    // If we don't have an accountID or accessToken we're definitely not ready
    if (!self.accountID || !self.accessToken) return block(NO);

    dispatch_queue_t resultQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateProfilesWithCompletion:^{
            NSString *foundAccountID = [self.profiles objectForKey:@"id"];
            BOOL isReady = ([foundAccountID isEqualToString:self.accountID]);
            dispatch_sync(resultQueue, ^{
                block(isReady);
            });
        }];
    });
}

- (void)requestAPI:(SinglyAPIRequest *)request withDelegate:(id<SinglyAPIRequestDelegate>)delegate
{
    [self requestAPI:request withCompletionHandler:^(NSError *error, id json) {
        if (error) {
            [delegate singlyAPIRequest:request failedWithError:error];
        } else {
            [delegate singlyAPIRequest:request succeededWithJSON:json];
        }
    }];
}

- (void)requestAPI:(SinglyAPIRequest *)request withCompletionHandler:(void (^)(NSError *, id))block
{
    if (!self.accessToken) {
        NSError* error = [NSError errorWithDomain:@"SinglySDK" code:100 userInfo:[NSDictionary dictionaryWithObject:@"Access token is not yet set" forKey:NSLocalizedDescriptionKey]];
        block(error, nil);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL* reqURL = [NSURL URLWithString:[request completeURLForToken:self.accessToken]];
        NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:reqURL];
        urlRequest.HTTPMethod = request.method;
        if (request.body) urlRequest.HTTPBody = request.body;
        NSURLResponse *response;
        NSError *error;
        NSData *returnedData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
        NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *) response;
        if ([httpResponse statusCode] == 200) {
            if (error) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    block(error, nil);
                });
                return;
            }
            id json = [NSJSONSerialization JSONObjectWithData:returnedData options:kNilOptions error:&error];
            if (error) {
                json = nil;
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                block(error, json);
            });
        } else {
            error = [[NSError alloc] initWithDomain:@"SinglyResponseErrorDomain" code:[httpResponse statusCode] userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"NSLocalizedDescriptionKey", (NSString *)[[NSString alloc] initWithData:returnedData encoding:NSUTF8StringEncoding], nil]];
            dispatch_sync(dispatch_get_main_queue(), ^{
                block(error, nil);
            });
        }
    });
}

- (void)updateProfiles
{
    [self updateProfilesWithCompletion:nil];
}

- (void)updateProfilesWithCompletion:(void(^)())block
{
    dispatch_queue_t curQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SinglyAPIRequest *apiReq = [[SinglyAPIRequest alloc] initWithEndpoint:@"profiles" andParameters:nil];
        NSError *error;
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[apiReq completeURLForToken:self.accessToken]]];
        id json = [NSJSONSerialization JSONObjectWithData:data
                                                  options:kNilOptions
                                                    error:&error];
        if (!error && [json isKindOfClass:[NSDictionary class]]) {
            if ([json valueForKey:@"error"])
                _profiles = nil;
            else
                _profiles = json;
            [[NSNotificationCenter defaultCenter] postNotificationName:kSinglySessionProfilesUpdatedNotification object:self];
        }

        if (block) dispatch_sync(curQueue, block);
    });
}

- (BOOL)handleOpenURL:(NSURL *)url
{

    // Facebook
    if ([url.scheme hasPrefix:@"fb"])
    {
        NSString *accessToken = [url extractAccessToken];
        if (accessToken)
        {
            [[SinglySession sharedSession] applyService:@"facebook" withToken:accessToken];
            return YES;
        }
    }

    return NO;

}

- (void)applyService:(NSString *)serviceIdentifier withToken:(NSString *)token
{
    NSLog(@"[SinglySDK] Applying %@ with token %@", serviceIdentifier, token);

    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.singly.com/auth/%@/apply?token=%@&client_id=%@&client_secret=%@",
                                              serviceIdentifier,
                                              token,
                                              self.clientID,
                                              self.clientSecret]];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError)
    {
        // TODO Handle request errors
        // TODO Handle JSON parse errors
        dispatch_async(dispatch_get_current_queue(), ^{
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
            SinglySession.sharedSession.accessToken = [responseDictionary objectForKey:@"access_token"];
            SinglySession.sharedSession.accountID = [responseDictionary objectForKey:@"account"];
            [SinglySession.sharedSession updateProfilesWithCompletion:^{
                dispatch_async(dispatch_get_current_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kSinglyServiceAppliedNotification object:serviceIdentifier];
                });
            }];
        });
    }];
}

@end
