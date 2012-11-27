//
//  SinglyRequest.m
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

#import "NSString+URLEncoded.h"
#import "SinglyConstants.h"
#import "SinglyRequest.h"
#import "SinglyRequest+Internal.h"
#import "SinglySession.h"

@implementation SinglyRequest

+ (id)requestWithEndpoint:(NSString *)endpoint
{
    SinglyRequest *request = [[SinglyRequest alloc] initWithEndpoint:endpoint];
    return request;
}

+ (id)requestWithEndpoint:(NSString *)endpoint andParameters:(NSDictionary *)parameters
{
    SinglyRequest *request = [[SinglyRequest alloc] initWithEndpoint:endpoint andParameters:parameters];
    return request;
}

- (id)initWithEndpoint:(NSString *)endpoint
{
    self = [self initWithEndpoint:endpoint andParameters:nil];
    return self;
}

- (id)initWithEndpoint:(NSString *)endpoint andParameters:(NSDictionary *)parameters
{
    self = [super init];
    if (self)
    {
        _endpoint = endpoint;
        _parameters = parameters;
        _isAuthorizedRequest = YES;
        [self updateURL];
    }
    return self;
}

#pragma mark - Properties

- (void)setEndpoint:(NSString *)endpoint
{
    _endpoint = endpoint;
    [self updateURL];
}

- (void)setIsAuthorizedRequest:(BOOL)isAuthorizedRequest
{
    _isAuthorizedRequest = isAuthorizedRequest;
    [self updateURL];
}

- (void)setParameters:(NSDictionary *)parameters
{
    _parameters = parameters;
    [self updateURL];
}

#pragma mark - Endpoint URLs

- (void)updateURL
{
    self.URL = [SinglyRequest URLForEndpoint:self.endpoint
                              withParameters:self.parameters
                            andAuthorization:self.isAuthorizedRequest];
}

+ (NSURL *)URLForEndpoint:(NSString *)endpoint withParameters:(NSDictionary *)parameters
{
    return [SinglyRequest URLForEndpoint:endpoint
                          withParameters:parameters
                        andAuthorization:YES];
}

+ (NSURL *)URLForEndpoint:(NSString *)endpoint withParameters:(NSDictionary *)parameters andAuthorization:(BOOL)isAuthorized
{
    NSMutableString *apiURLString = [NSMutableString stringWithFormat:@"%@/%@", kSinglyBaseURL, endpoint];

    // Add Query Parameter Separator to URL
    if (isAuthorized || parameters.count > 0)
        [apiURLString appendString:@"?"];

    // Add Parameters to URL
    if (parameters)
    {
        [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop)
         {
             if (![value isKindOfClass:[NSNull class]])
                 [apiURLString appendFormat:@"&%@=%@", [key URLEncodedString], [value URLEncodedString]];
         }];
    }

    // Add Singly Access Token to URL
    if (isAuthorized && SinglySession.sharedSession.accessToken)
        [apiURLString appendFormat:@"&access_token=%@", SinglySession.sharedSession.accessToken];

//    NSLog(@"[SinglySDK:SinglyRequest] Generated URL: %@", apiURLString);

    return [NSURL URLWithString:apiURLString];
}

@end
