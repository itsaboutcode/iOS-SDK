//
//  SinglySessionTests.m
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

#import "SinglySession.h"
#import "SinglySession+Internal.h"
#import "SinglySessionTests.h"

@implementation SinglySessionTests

- (void)tearDown
{
    [SinglySession.sharedSession resetSession];
}

- (void)testSharedSessionInitialization
{
    STAssertNotNil(SinglySession.sharedSessionInstance, @"The shared session instance was not initialized!");
    STAssertNotNil(SinglySession.sharedSession, @"The shared session was not initialized!");
}

- (void)testNewlyInitializedSessionShouldNotBeReady
{
    SinglySession *testSession = [[SinglySession alloc] init];

    STAssertFalse(testSession.isReady, @"Newly initialized session should not be in a ready state.");
}

- (void)testSubsequentCallsToSharedSessionShouldReturnSingletonInstance
{
    SinglySession *sessionOne = SinglySession.sharedSession;
    SinglySession *sessionTwo = SinglySession.sharedSession;

    STAssertEquals(sessionOne, sessionTwo, @"Both session pointers should be identical.");
}


- (void)testShouldSetClientID
{
    SinglySession *testSession = [[SinglySession alloc] init];
    testSession.clientID = @"test-client-id";

    STAssertEqualObjects(testSession.clientID, @"test-client-id", @"The client ID should match 'test-client-id'.");
}

- (void)testShouldSetClientSecret
{
    SinglySession *testSession = [[SinglySession alloc] init];
    testSession.clientSecret = @"test-client-secret";

    STAssertEqualObjects(testSession.clientSecret, @"test-client-secret", @"The client ID should match 'test-client-secret'.");
}

- (void)testShouldResetSession
{
    SinglySession *testSession = [[SinglySession alloc] init];
    testSession.accessToken = @"test-access-token";
    testSession.accountID = @"test-account-id";

    STAssertEqualObjects(testSession.accessToken, @"test-access-token", @"The accessToken property should equal 'test-access-token'.");
    STAssertEqualObjects(testSession.accountID, @"test-account-id", @"The accountID property should equal 'test-account-id'.");

    [testSession resetSession];

    // TODO Test isReady, profiles and watch for notification: kSinglySessionProfilesUpdatedNotification

    STAssertNil(testSession.accessToken, @"The accessToken property should be nil.");
    STAssertNil(testSession.accountID, @"The accountID property should be nil.");
}

- (void)testStartingSessionWithoutCredentialsShouldReturnNotReady
{
    SinglySession *testSession = SinglySession.sharedSession;
    [testSession resetSession];

    STAssertNil(testSession.accessToken, @"The accessToken property should be nil.");
    STAssertNil(testSession.accountID, @"The accessToken property should be nil.");

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [testSession startSessionWithCompletionHandler:^(BOOL isReady) {
        STAssertFalse(isReady, @"The session should not be ready.");
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    #if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
        dispatch_release(semaphore);
    #endif
}

- (void)testShouldStartSession
{
    SinglySession *testSession = SinglySession.sharedSession;
    [testSession resetSession];

    STAssertNil(testSession.accessToken, @"The accessToken property should be nil.");
    STAssertNil(testSession.accountID, @"The accessToken property should be nil.");

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [testSession startSessionWithCompletionHandler:^(BOOL isReady) {
        STAssertFalse(isReady, @"The session should not be ready.");
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    #if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
        dispatch_release(semaphore);
    #endif
}

- (void)testShouldUpdateProfiles
{
    
}

- (void)testShouldHandleOpenURL
{

}

@end
