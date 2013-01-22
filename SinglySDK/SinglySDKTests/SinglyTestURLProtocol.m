//
//  SinglyTestURLProtocol.m
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

#import "SinglyTestURLProtocol.h"

static NSData *singlyCannedResponseData = nil;
static NSError *singlyCannedError = nil;
static NSDictionary *singlyCannedHeaders = nil;
static NSInteger singlyCannedStatusCode = 200;

@implementation SinglyTestURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return [request.URL.host isEqualToString:@"api.singly.com"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
	return request;
}

+ (void)setCannedResponseData:(NSData *)data
{
    singlyCannedResponseData = data;
}

+ (void)setCannedError:(NSError *)error
{
    singlyCannedError = error;
}

+ (void)setCannedStatusCode:(NSInteger)statusCode
{
    singlyCannedStatusCode = statusCode;
}

+ (void)setCannedHeaders:(NSDictionary *)headers
{
    singlyCannedHeaders = headers;
}

+ (void)reset
{
    singlyCannedResponseData = nil;
    singlyCannedError = nil;
    singlyCannedHeaders = nil;
    singlyCannedStatusCode = 200;
}

- (void)startLoading
{
    NSURLRequest *request = [self request];
    id<NSURLProtocolClient> client = [self client];

    if (singlyCannedResponseData)
    {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                                  statusCode:singlyCannedStatusCode
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:singlyCannedHeaders];

        [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [client URLProtocol:self didLoadData:singlyCannedResponseData];
        [client URLProtocolDidFinishLoading:self];
    }

    else if (singlyCannedError)
    {
        [client URLProtocol:self didFailWithError:singlyCannedError];
    }
}

- (void)stopLoading
{
}

@end
