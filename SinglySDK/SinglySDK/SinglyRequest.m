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
    _endpoint = endpoint;
    _parameters = parameters;
    self = [super initWithURL:self.URL];
    if (self)
    {
        // ...
    }
    return self;
}

- (NSURL *)URL
{
    return [SinglyRequest URLForEndpoint:self.endpoint andParameters:self.parameters];
}

+ (NSURL *)URLForEndpoint:(NSString *)endpoint andParameters:(NSDictionary *)parameters
{
    NSString *apiURLString = [NSString stringWithFormat:@"%@/%@?", kSinglyBaseURL, endpoint];

    // Add Parameters to URL
    if (parameters)
    {
        NSMutableString *paramString = [NSMutableString string];
        [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop)
         {
             if (![value isKindOfClass:[NSNull class]])
                 [paramString appendFormat:@"&%@=%@", [key URLEncodedString], [value URLEncodedString]];
         }];
        apiURLString = [apiURLString stringByAppendingString:paramString];
    }

    // Add Singly Access Token to URL
    if (SinglySession.sharedSession.accessToken)
        apiURLString = [apiURLString stringByAppendingFormat:@"&access_token=%@", SinglySession.sharedSession.accessToken];

    return [NSURL URLWithString:apiURLString];
}

@end
