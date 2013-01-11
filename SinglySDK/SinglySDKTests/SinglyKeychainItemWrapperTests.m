//
//  SinglyKeychainItemWrapperTests.m
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

#import "SinglyKeychainItemWrapper.h"
#import "SinglyKeychainItemWrapper+Internal.h"
#import "SinglyKeychainItemWrapperTests.h"

@implementation SinglyKeychainItemWrapperTests

- (void)setUp
{
    self.testItemWrapper = [[SinglyKeychainItemWrapper alloc] initWithIdentifier:@"testIdentifier" accessGroup:nil];
}

- (void)tearDown
{
    [self.testItemWrapper resetKeychainItem];
    self.testItemWrapper = nil;
}

- (void)testShouldInitialize
{
    STAssertNotNil(self.testItemWrapper, @"testItemWrapper should not be nil.");
    STAssertEqualObjects(@"testIdentifier", self.testItemWrapper.identifier, @"Identifier should match 'testIdentifier'.");
}

- (void)testShouldInitializeWithAccessGroup
{
    SinglyKeychainItemWrapper *testItemWrapperWithAccessGroup = [[SinglyKeychainItemWrapper alloc] initWithIdentifier:@"testIdentifeir" accessGroup:@"testAccessGroup"];
    STAssertNotNil(testItemWrapperWithAccessGroup, @"testItemWrapperWithAccessGroup should not be nil.");
    STAssertEqualObjects(@"testAccessGroup", testItemWrapperWithAccessGroup.accessGroup, @"Access group should match 'testAccessGroup'.");
}

- (void)testShouldSetObjectsForKnownKeys
{
    [self.testItemWrapper setObject:@"testValue" forKey:(__bridge id)kSecValueData];
    STAssertEqualObjects(self.testItemWrapper.keychainItemData[(__bridge id)kSecValueData], @"testValue", @"Keychain item data should contain value for the kSecValueData key!");

    [self.testItemWrapper setObject:@"testAccount" forKey:(__bridge id)kSecAttrAccount];
    STAssertEqualObjects(self.testItemWrapper.keychainItemData[(__bridge id)kSecAttrAccount], @"testAccount", @"Keychain item data should contain value for the kSecAttrAccount key!");

    [self.testItemWrapper setObject:@"testLabel" forKey:(__bridge id)kSecAttrLabel];
    STAssertEqualObjects(self.testItemWrapper.keychainItemData[(__bridge id)kSecAttrLabel], @"testLabel", @"Keychain item data should contain value for the kSecAttrLabel key!");

    [self.testItemWrapper setObject:@"testDescription" forKey:(__bridge id)kSecAttrDescription];
    STAssertEqualObjects(self.testItemWrapper.keychainItemData[(__bridge id)kSecAttrDescription], @"testDescription", @"Keychain item data should contain value for the kSecAttrDescription key!");
}

- (void)testShouldReturnObjectsForKnownKeys
{
    [self.testItemWrapper setObject:@"testValue" forKey:(__bridge id)kSecValueData];
    STAssertEqualObjects([self.testItemWrapper objectForKey:(__bridge id)kSecValueData], @"testValue", @"The value for the kSecValueData key should equal 'testValue'.");

    [self.testItemWrapper setObject:@"testAccount" forKey:(__bridge id)kSecAttrAccount];
    STAssertEqualObjects([self.testItemWrapper objectForKey:(__bridge id)kSecAttrAccount], @"testAccount", @"The value for the kSecAttrAccount key should equal 'testAccount'.");

    [self.testItemWrapper setObject:@"testLabel" forKey:(__bridge id)kSecAttrLabel];
    STAssertEqualObjects([self.testItemWrapper objectForKey:(__bridge id)kSecAttrLabel], @"testLabel", @"The value for the kSecAttrLabel key should equal 'testLabel'.");

    [self.testItemWrapper setObject:@"testDescription" forKey:(__bridge id)kSecAttrDescription];
    STAssertEqualObjects([self.testItemWrapper objectForKey:(__bridge id)kSecAttrDescription], @"testDescription", @"The value for the kSecAttrDescription key should equal 'testDescription'.");
}

- (void)testShouldResetKeychainItem
{
    [self.testItemWrapper setObject:@"testValue" forKey:(__bridge id)kSecValueData];
    [self.testItemWrapper setObject:@"testAccount" forKey:(__bridge id)kSecAttrAccount];
    [self.testItemWrapper setObject:@"testLabel" forKey:(__bridge id)kSecAttrLabel];
    [self.testItemWrapper setObject:@"testDescription" forKey:(__bridge id)kSecAttrDescription];

    [self.testItemWrapper resetKeychainItem];

    STAssertEqualObjects(@"", [self.testItemWrapper objectForKey:(__bridge id)kSecValueData], @"The value for the kSecValueData key should be an empty string.");
    STAssertEqualObjects(@"", [self.testItemWrapper objectForKey:(__bridge id)kSecAttrAccount], @"The value for the kSecAttrAccount key should be an empty string.");
    STAssertEqualObjects(@"", [self.testItemWrapper objectForKey:(__bridge id)kSecAttrLabel], @"The value for the kSecAttrLabel key should be an empty string.");
    STAssertEqualObjects(@"", [self.testItemWrapper objectForKey:(__bridge id)kSecAttrDescription], @"The value for the kSecAttrDescription key should be an empty string.");
}

@end
