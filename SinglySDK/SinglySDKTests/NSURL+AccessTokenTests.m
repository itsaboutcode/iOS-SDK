//
//  NSURL+AccessTokenTests.m
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
#import "NSURL+AccessTokenTests.h"

@implementation NSURL_AccessTokenTests

static NSString *testAccessToken = @"1olBvHiVk4BE583qHN6lrzRxNT0.nhubPfqZfe1a25645d52c98159bfda70449380472880cdf6cca7fc92895e79f98536a21b314b6cc0a8f15cba629d185e86ea52917a4c47933557f3502b7e3d5d7f4076797eadcd70024d44ca6dc001d7fd01db3ae3a67fc0731e66b448be89aa0c861137";

- (void)testShouldExtractAccessTokenAsHashParameter
{
    NSURL *testURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://example.com/foo#access_token=%@", testAccessToken]];
    NSString *accessToken = [testURL extractAccessToken];

    STAssertEqualObjects(accessToken, testAccessToken, @"The extracted access token does not match the test token.");
}

- (void)testShouldExtractAccessTokenAsQueryParameter
{
    NSURL *testURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://example.com/foo?access_token=%@", testAccessToken]];
                      NSString *accessToken = [testURL extractAccessToken];

    STAssertEqualObjects(accessToken, testAccessToken, @"The extracted access token does not match the test token.");
}


@end
