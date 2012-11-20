//
//  SinglyAPIRequest.m
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

#import "SinglyAPIRequest.h"

@implementation SinglyAPIRequest

+ (SinglyAPIRequest *)apiRequestForEndpoint:(NSString *)endpoint withParameters:(NSDictionary *)parameters
{
    return [[SinglyAPIRequest alloc] initWithEndpoint:endpoint andParameters:parameters];
}

+ (SinglyAPIRequest*)apiRequestForEndpoint:(NSString *)endpoint
{
    return [SinglyAPIRequest apiRequestForEndpoint:endpoint withParameters:nil];
}

- (id)initWithEndpoint:(NSString *)endpoint andParameters:(NSDictionary *)parameters
{
    self = [super init];
    if (self) {
        self.method = @"GET";
        // Ignore the / if it's there
        _endpoint = [endpoint characterAtIndex:0] == '/' ? [endpoint substringFromIndex:1] : endpoint;
        _parameters = parameters;
    }
    return self;
}

- (NSString *)completeURLForToken:(NSString *)accessToken
{
    NSString *apiURLStr = [NSString stringWithFormat:@"https://api.singly.com/v0/%@?access_token=%@", self.endpoint, accessToken];
    if (self.parameters)
    {
        NSMutableString* paramString = [NSMutableString string];
        [self.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
        {
            if (![obj isKindOfClass:[NSNull class]])
            {
                [paramString appendFormat:@"&%@=%@", [self escapeString:key], [self escapeString:obj]];
            }
        }];
        apiURLStr = [apiURLStr stringByAppendingString:paramString];
    }
    return apiURLStr;
}

#pragma mark -

- (NSString *)escapeString:(NSString *)rawString
{
    CFStringRef originalString = (__bridge_retained CFStringRef)rawString;
    NSString *finalString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, originalString, NULL, NULL, kCFStringEncodingUTF8);
    CFRelease(originalString);
    return finalString;
}

@end
