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
#import "SinglyKeychainItemWrapper.h"
#import "SinglyRequest.h"
#import "SinglySession.h"
#import "SinglySession+Internal.h"

static NSString *kSinglyAccessTokenKey = @"com.singly.accessToken";
static SinglySession *sharedInstance = nil;

@implementation SinglySession

+ (SinglySession*)sharedSession
{
    if (sharedInstance == nil)
        sharedInstance = [[SinglySession alloc] init];
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _accessTokenWrapper = [[SinglyKeychainItemWrapper alloc] initWithIdentifier:kSinglyAccessTokenKey accessGroup:nil];
    }
    return self;
}

- (void)setAccountID:(NSString *)accountID
{
    [self.accessTokenWrapper setObject:accountID forKey:(__bridge id)kSecAttrAccount];
}

- (NSString *)accountID
{
    NSString *theAccountID = [self.accessTokenWrapper objectForKey:(__bridge id)kSecAttrAccount];
    if (theAccountID.length == 0) theAccountID = nil;
    return theAccountID;
}

- (void)setAccessToken:(NSString *)accessToken
{
    [self.accessTokenWrapper setObject:accessToken forKey:(__bridge id)kSecValueData];
}

- (NSString *)accessToken
{
    NSString *theAccessToken = [self.accessTokenWrapper objectForKey:(__bridge id)kSecValueData];
    if (theAccessToken.length == 0) theAccessToken = nil;
    return theAccessToken;
}

- (void)startSessionWithCompletionHandler:(void (^)(BOOL))block
{
    // If we don't have an accountID or accessToken we're definitely not ready
    if (!self.accountID || !self.accessToken) return block(NO);

    dispatch_queue_t resultQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateProfilesWithCompletion:^(BOOL success)
        {
            NSString *foundAccountID = [self.profiles objectForKey:@"id"];
            BOOL isReady = ([foundAccountID isEqualToString:self.accountID]);
            dispatch_sync(resultQueue, ^{
                block(isReady);
            });
        }];
    });
}

- (void)updateProfiles
{
    [self updateProfilesWithCompletion:nil];
}

- (void)updateProfilesWithCompletion:(void (^)(BOOL))block
{
    dispatch_queue_t curQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *requestError;
        NSError *parseError;
        NSURLResponse *response;
        BOOL isSuccessful = NO;

        SinglyRequest *request = [SinglyRequest requestWithEndpoint:@"profiles"];
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];

        // Check for invalid or expired tokens...
        if (requestError)
        {
            NSLog(@"[SinglySDK:SinglySession] An error occurred while requesting profiles: %@", requestError);
            _profiles = [NSDictionary dictionary];

            if ([(NSHTTPURLResponse *)response statusCode] == 401)
            {
                NSLog(@"[SinglySDK:SinglySession] Access token is invalid or expired! Need to reauthorize...");
                self.accessToken = nil;
            }
        }

        else
        {
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];
            if (!requestError && !parseError)
            {
                if ([responseDictionary valueForKey:@"error"])
                    _profiles = [NSDictionary dictionary];
                else
                    _profiles = responseDictionary;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSNotificationCenter.defaultCenter postNotificationName:kSinglySessionProfilesUpdatedNotification object:self];
                });
                isSuccessful = YES;
            }
        }

        if (block) dispatch_sync(curQueue, ^{
            block(isSuccessful);
        });
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
            [SinglySession.sharedSession applyService:@"facebook" withToken:accessToken];
            return YES;
        }
    }

    return NO;

}

- (void)applyService:(NSString *)serviceIdentifier withToken:(NSString *)token
{
    NSLog(@"[SinglySDK] Applying service '%@' with token '%@' to the Singly service ...", serviceIdentifier, token);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *requestError;
        NSError *parseError;
        NSURLResponse *response;
        SinglyRequest *request = [[SinglyRequest alloc] initWithEndpoint:[NSString stringWithFormat:@"auth/%@/apply", serviceIdentifier]];
        request.parameters = @{
            @"client_id": self.clientID,
            @"client_secret": self.clientSecret,
            @"token": token
        };
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];

        if (!requestError && !parseError)
        {
            dispatch_async(dispatch_get_current_queue(), ^{
                SinglySession.sharedSession.accessToken = responseDictionary[@"access_token"][@"access_token"];
                SinglySession.sharedSession.accountID = responseDictionary[@"account"];
                [SinglySession.sharedSession updateProfilesWithCompletion:^(BOOL successful)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [NSNotificationCenter.defaultCenter postNotificationName:kSinglyServiceAppliedNotification object:serviceIdentifier];
                    });
                }];
            });
        }
    });
}

@end
