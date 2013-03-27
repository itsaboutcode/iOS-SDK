//
//  SinglyFacebookServiceTests.m
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

#import <OCMock/OCMock.h>
#import "SenTestCase+AsynchronousSupport.h"
#import "SenTestCase+Fixtures.h"

#import "SinglyService.h"
#import "SinglyService+Internal.h"
#import "SinglyTestURLProtocol.h"

#import "SinglyFacebookServiceTests.h"

@implementation SinglyFacebookServiceTests

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

#pragma mark - Application-Based Authorization Tests

//
// Tests that an app that has been properly configured to both answer Facebook
// URL schemes and handle opens from those URLs by implementing the
// `application:openURL:sourceApplication:annotation:` method is properly
// recognized as being configured by the `isApplicationAuthorizationConfigured`
// method on `SinglyFacebookService`.
//
- (void)testApplicationBasedAuthorizationShouldBeAvailable
{
    SinglyFacebookService *facebookService = [[SinglyFacebookService alloc] init];
    NSArray *testURLTypes = @[
        @{ @"CFBundleURLSchemes": @[ @"custom-scheme" ] },
        @{ @"CFBundleURLSchemes": @[ @"fb000000000000000" ] }
    ];

    //
    // Mock the app delegate so that we can implement the delegate method
    // `application:openURL:sourceApplication:annotation:`.
    //
    id mockAppDelegate = [OCMockObject mockForProtocol:@protocol(UIApplicationDelegate)];
    id mockApplication = [OCMockObject mockForClass:[UIApplication class]];
    id mockApplicationInstance = [OCMockObject mockForClass:[UIApplication class]];
    [[mockAppDelegate stub] application:[OCMArg any] openURL:[OCMArg any] sourceApplication:[OCMArg any] annotation:[OCMArg any]];
    [[[mockApplicationInstance stub] andReturn:mockAppDelegate] delegate];
    [[[mockApplication stub] andReturn:mockApplicationInstance] sharedApplication];

    //
    // Mock the main bundle for the application so that we can override the
    // values found in Info.plist with values we want to use for testing.
    //
    id mockBundleInstance = [OCMockObject mockForClass:[NSBundle class]];
    id mockBundle = [OCMockObject mockForClass:[NSBundle class]];
    [[[mockBundleInstance stub] andReturn:testURLTypes] objectForInfoDictionaryKey:[OCMArg any]];
    [[[mockBundle stub] andReturn:mockBundleInstance] mainBundle];

    STAssertTrue([facebookService isAppAuthorizationConfigured], @"Facebook application authorization should be available.");

    [mockBundle stopMocking];
    [mockBundleInstance stopMocking];
    [mockApplicationInstance stopMocking];
    [mockApplication stopMocking];
    [mockAppDelegate stopMocking];
}

//
// Tests that the `isApplicationAuthorizationConfigured` method on
// `SinglyFacebookService` will return false if the app integrating the Singly
// SDK is not configured for the Facebook URL scheme (i.e. fb123456789012345).
//
- (void)testApplicationBasedAuthorizationShouldNotBeAvailableWhenURLSchemeIsMissing
{
    SinglyFacebookService *facebookService = [[SinglyFacebookService alloc] init];
    NSArray *testURLTypes = @[ @{ @"CFBundleURLSchemes": @[ @"custom-scheme" ] } ];

    //
    // Mock the app delegate so that we can implement the delegate method
    // `application:openURL:sourceApplication:annotation:`. Even though the
    // implemented method should not reach this check, we should keep it mocked
    // in case the method implementation changes.
    //
    id mockAppDelegate = [OCMockObject mockForProtocol:@protocol(UIApplicationDelegate)];
    id mockApplication = [OCMockObject mockForClass:[UIApplication class]];
    id mockApplicationInstance = [OCMockObject mockForClass:[UIApplication class]];
    [[mockAppDelegate stub] application:[OCMArg any] openURL:[OCMArg any] sourceApplication:[OCMArg any] annotation:[OCMArg any]];
    [[[mockApplicationInstance stub] andReturn:mockAppDelegate] delegate];
    [[[mockApplication stub] andReturn:mockApplicationInstance] sharedApplication];

    //
    // Mock the main bundle for the application so that we can override the
    // values found in Info.plist with values we want to use for testing.
    //
    id mockBundleInstance = [OCMockObject mockForClass:[NSBundle class]];
    [[[mockBundleInstance stub] andReturn:testURLTypes] objectForInfoDictionaryKey:[OCMArg any]];
    id mockBundle = [OCMockObject mockForClass:[NSBundle class]];
    [[[mockBundle stub] andReturn:mockBundleInstance] mainBundle];

    STAssertFalse([facebookService isAppAuthorizationConfigured], @"Facebook application authorization should not be available.");
    
    [mockBundle stopMocking];
    [mockBundleInstance stopMocking];
    [mockApplicationInstance stopMocking];
    [mockApplication stopMocking];
    [mockAppDelegate stopMocking];
}

//
// Tests that the `isApplicationAuthorizationConfigured` method on
// `SinglyFacebookService` will return false if the app integrating the Singly
// SDK has not implemented the `application:openURL:sourceApplication:annotation:`
// method in the application delegate.
//
- (void)testApplicationBasedAuthorizationShouldNotBeAvailableWhenAppDelegateMethodIsMissing
{
    SinglyFacebookService *facebookService = [[SinglyFacebookService alloc] init];
    NSArray *testURLTypes = @[ @{ @"CFBundleURLSchemes": @[ @"custom-scheme" ] } ];

    //
    // Mock the main bundle for the application so that we can override the
    // values found in Info.plist with values we want to use for testing.
    //
    id mockBundleInstance = [OCMockObject mockForClass:[NSBundle class]];
    [[[mockBundleInstance stub] andReturn:testURLTypes] objectForInfoDictionaryKey:[OCMArg any]];
    id mockBundle = [OCMockObject mockForClass:[NSBundle class]];
    [[[mockBundle stub] andReturn:mockBundleInstance] mainBundle];

    STAssertFalse([facebookService isAppAuthorizationConfigured], @"Facebook application authorization should not be available.");

    [mockBundle stopMocking];
    [mockBundleInstance stopMocking];
}

@end
