//
//  NSDictionary+QueryStringTests.m
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

#import "NSDictionary+QueryString.h"
#import "NSDictionary+QueryStringTests.h"

@implementation NSDictionary_QueryStringTests

- (void)testDictionaryWithQueryString
{
    NSString *testQueryString = @"foo=bar&baz=qux";
    NSDictionary *testDictionary = [NSDictionary dictionaryWithQueryString:testQueryString];

    STAssertEqualObjects(testDictionary[@"foo"], @"bar", @"The value for the key 'foo' should equal 'bar'.");
    STAssertEqualObjects(testDictionary[@"baz"], @"qux", @"The value for the key 'baz' should equal 'qux'.");
}

- (void)testDictionaryWithQueryStringShouldReturnEmptyDictionaryForEmptyQueryString
{
    NSDictionary *testDictionary = [NSDictionary dictionaryWithQueryString:@""];

    STAssertTrue(testDictionary.allKeys.count == 0, @"The dictionary should contain no keys.");
}

- (void)testDictionaryWithQueryStringShouldURLDecodeKeysAndValues
{
    NSDictionary *testDictionary = [NSDictionary dictionaryWithQueryString:@"foo%5Ba%5D=bar%2Fbaz&foo%5Bb%5D=qux%2Fbaz"];

    STAssertNotNil(testDictionary[@"foo[a]"], @"The dictionary should contain the key 'foo[a]' in place of the encoded key 'foo%5Ba%5D'.");
    STAssertNil(testDictionary[@"foo%5Ba%5D"], @"The dictionary should not contain the key 'foo%5Ba%5D'!");
    STAssertEqualObjects(testDictionary[@"foo[a]"], @"bar/baz", @"The value for the key 'foo[a]' should equal 'bar/baz'.");

    STAssertNotNil(testDictionary[@"foo[b]"], @"The dictionary should contain the key 'foo[b]' in place of the encoded key 'foo%5Bb%5D'.");
    STAssertNil(testDictionary[@"foo%5Bb%5D"], @"The dictionary should not contain the key 'foo%5Bb%5D'!");
    STAssertEqualObjects(testDictionary[@"foo[b]"], @"qux/baz", @"The value for the key 'foo[b]' should equal 'qux/baz'.");
}

@end
