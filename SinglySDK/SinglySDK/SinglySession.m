//
//  SinglySession.m
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/21/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import "SinglySession.h"

static NSString* kSinglyAccountIDKey = @"com.singly.accountID";
static NSString* kSinglyAccessTokenKey = @"comsingly.accessToken";

@implementation SinglySession

-(void)setAccountID:(NSString *)accountID
{
    [[NSUserDefaults standardUserDefaults] setObject:accountID forKey:kSinglyAccountIDKey];
}

-(NSString*)accountID;
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kSinglyAccountIDKey];
}

-(void)setAccessToken:(NSString *)accessToken;
{
    [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:kSinglyAccessTokenKey];
}

-(NSString*)accessToken;
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kSinglyAccessTokenKey];
}

-(void)checkReadyWithCompletionHandler:(void (^)(BOOL))block;
{
    // If we don't have an accountID or accessToken we're definitely not ready
    if (!self.accountID || !self.accessToken) {
        return block(NO);
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.singly.com/v0/profiles?access_token=%@", self.accessToken]]];
        NSError* error;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        NSString* foundAccountID = [json objectForKey:@"id"];
        BOOL isReady = NO;
        if ([foundAccountID isEqualToString:self.accountID]) {
            isReady = YES;
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            block(isReady);
        });
    });
    
}

-(void)requestAPI:(SinglyAPIRequest *)request withDelegate:(id<SinglyAPIRequestDelegate>)delegate;
{
    [self requestAPI:request withCompletionHandler:^(NSError *error, id json) {
        if (error) {
            [delegate singlyAPIRequest:request failedWithError:error];
        } else {
            [delegate singlyAPIRequest:request succeededWithJSON:json];
        }
    }];
}

-(void)requestAPI:(SinglyAPIRequest *)request withCompletionHandler:(void (^)(NSError *, id))block;
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
        NSURLResponse* response;
        NSError* error;
        NSData* returnedData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
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
    });    
}
@end
