//
//  SinglySession.m
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/21/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import "SinglySession.h"

static NSString* kSinglyAccountIDKey = @"com.singly.accountID";
static NSString* kSinglyAccessTokenKey = @"com.singly.accessToken";

@interface SinglySession () {
    NSDictionary* _profiles;
}
@end

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

-(NSDictionary*)profiles;
{
    return _profiles;
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
            _profiles = json;
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

-(void)updateProfilesWithCompletion:(void(^)())block;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SinglyAPIRequest* apiReq = [[SinglyAPIRequest alloc] initWithEndpoint:@"profiles" andParameters:nil];
        NSError* error;
        id json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[apiReq completeURLForToken:self.accessToken]]] options:kNilOptions error:&error];
        if (!error && [json isKindOfClass:[NSDictionary class]]) {
            _profiles = json;
        }
        
        dispatch_sync(dispatch_get_main_queue(), block);
    });
}
@end
