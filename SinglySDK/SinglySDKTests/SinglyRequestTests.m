//
//  SinglyRequestTests.m
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

#import "SinglyConstants.h"
#import "SinglyRequest.h"
#import "SinglyRequest+Internal.h"
#import "SinglyRequestTests.h"
#import "SinglySession.h"

@implementation SinglyRequestTests

- (void)setUp
{
    [SinglySession.sharedSession resetSession];
}

- (void)testShouldAddSinglySDKHeaders
{
    SinglyRequest *testRequest = [SinglyRequest requestWithEndpoint:@"foo"];
    NSDictionary  *allHeaders  = testRequest.allHTTPHeaderFields;

    STAssertNotNil(allHeaders[@"X-Singly-SDK"], @"");
    STAssertEqualObjects(allHeaders[@"X-Singly-SDK"], @"iOS", @"The HTTP header 'X-Singly-SDK' should match 'iOS'.");

    STAssertNotNil(allHeaders[@"X-Singly-SDK-Version"], @"");
    STAssertEqualObjects(allHeaders[@"X-Singly-SDK-Version"], kSinglySDKVersion, [NSString stringWithFormat:@"The HTTP header 'X-Singly-SDK-Version' should match '%@'.", kSinglySDKVersion]);
}

- (void)testSetAllHTTPHeaderFieldsShouldKeepSinglySDKHeaders
{
    SinglyRequest *testRequest = [SinglyRequest requestWithEndpoint:@"foo"];
    [testRequest setAllHTTPHeaderFields:@{
        @"Content-Type": @"application/json"
    }];

    NSDictionary *allHeaders = testRequest.allHTTPHeaderFields;
    STAssertEqualObjects(allHeaders[@"Content-Type"], @"application/json", @"Custom HTTP header 'Content-Type' should match 'application/json'.");

    STAssertNotNil(allHeaders[@"X-Singly-SDK"], @"");
    STAssertEqualObjects(allHeaders[@"X-Singly-SDK"], @"iOS", @"The HTTP header 'X-Singly-SDK' should match 'iOS'.");

    STAssertNotNil(allHeaders[@"X-Singly-SDK-Version"], @"");
    STAssertEqualObjects(allHeaders[@"X-Singly-SDK-Version"], kSinglySDKVersion, [NSString stringWithFormat:@"The HTTP header 'X-Singly-SDK-Version' should match '%@'.", kSinglySDKVersion]);
}

- (void)testShouldUseBaseURLFromSinglySession
{
    NSURL *testURL = [NSURL URLWithString:@"http://localhost:8042/foo"];
    NSString *oldBaseURL = SinglySession.sharedSession.baseURL;
    SinglySession.sharedSession.baseURL = @"http://localhost:8042";
    SinglyRequest *testRequest = [SinglyRequest requestWithEndpoint:@"foo"];

    STAssertEqualObjects(testRequest.URL, testURL, @"The constructed URL for the request should equal 'http://localhost:8042'.");

    SinglySession.sharedSession.baseURL = oldBaseURL;
}

@end
