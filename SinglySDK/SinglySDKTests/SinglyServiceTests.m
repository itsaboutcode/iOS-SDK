//
//  SinglyServiceTests.m
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

#import "SenTestCase+AsynchronousSupport.h"
#import "SenTestCase+Fixtures.h"

#import "SinglyService.h"
#import "SinglyService+Internal.h"
#import "SinglyServiceTests.h"
#import "SinglyTestURLProtocol.h"

@implementation SinglyServiceTests

- (void)setUp
{
    [super setUp];

    SinglySession.sharedSession.clientID = @"test-client-id";
    SinglySession.sharedSession.clientSecret = @"test-client-secret";

    [NSURLProtocol registerClass:[SinglyTestURLProtocol class]];
}

- (void)tearDown
{
    [super tearDown];

    [SinglySession.sharedSession resetSession];

    [SinglyTestURLProtocol reset];
}

#pragma mark -

- (void)testShouldReturnInitializedServiceWithIdentifier
{
    SinglyService *testService = [SinglyService serviceWithIdentifier:@"generic"];

    STAssertEqualObjects(testService.serviceIdentifier, @"generic", @"Service instance should be initialized for 'generic'.");
}

- (void)testShouldInitializeServiceWithIdentifier
{
    SinglyService *testService = [[SinglyService alloc] initWithIdentifier:@"generic"];

    STAssertEqualObjects(testService.serviceIdentifier, @"generic", @"Service instance should be initialized for 'generic'.");
}

#pragma mark - Service Disconnection

- (void)testShouldDisconnectFromService
{
    SinglyService *testService = [SinglyService serviceWithIdentifier:@"generic"];

    NSData *responseData = [self dataForFixture:@"profiles-service-delete"];
    [SinglyTestURLProtocol setCannedResponseData:responseData];

    BOOL isSuccessful = [testService disconnect:nil];

    STAssertTrue(isSuccessful, @"Return value of disconnect: should be true.");
}

- (void)testShouldDisconnectFromServiceWithCompletion
{
    __block BOOL isComplete = NO;

    SinglyService *testService = [SinglyService serviceWithIdentifier:@"generic"];

    NSData *responseData = [self dataForFixture:@"profiles-service-delete"];
    [SinglyTestURLProtocol setCannedResponseData:responseData];

    [testService disconnectWithCompletion:^(BOOL isSuccessful, NSError *error) {
        STAssertTrue(isSuccessful, @"Parameter value 'isSuccessful' should be true.");
        isComplete = YES;
    }];

    [self waitForCompletion:^{ return isComplete; }];
}

#pragma mark - Service Client Identifiers

- (void)testShouldFetchClientID
{
    SinglyService *testService = [SinglyService serviceWithIdentifier:@"generic"];

    NSData *responseData = [self dataForFixture:@"auth-client_id-generic"];
    [SinglyTestURLProtocol setCannedResponseData:responseData];

    NSString *testClientID = [testService fetchClientID:nil];

    STAssertNotNil(testClientID, @"Return value of fetchClientID: should not be nil.");
}

- (void)testShouldFetchClientIDWithCompletion
{
    __block BOOL isComplete = NO;

    SinglyService *testService = [SinglyService serviceWithIdentifier:@"generic"];

    NSData *responseData = [self dataForFixture:@"auth-client_id-generic"];
    [SinglyTestURLProtocol setCannedResponseData:responseData];

    [testService fetchClientIDWithCompletion:^(NSString *clientID, NSError *error) {
        STAssertNotNil(clientID, @"Parameter 'clientID' value should not be nil.");
        isComplete = YES;
    }];

    [self waitForCompletion:^{ return isComplete; }];
}

@end
