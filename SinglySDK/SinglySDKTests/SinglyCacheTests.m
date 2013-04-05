//
//  SinglyCacheTests.m
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

#import "SinglyCache.h"
#import "SinglyCache+Internal.h"
#import "SinglyCacheTests.h"

@implementation SinglyCacheTests

- (void)testSharedCacheInitialization
{
    STAssertNotNil(SinglyCache.sharedCache, @"The shared cache was not initialized!");
}

- (void)testShouldCacheImage
{
    SinglyCache *cache = SinglyCache.sharedCache;
    [cache cacheImage:[self blankImage] forURL:@"http://localhost/blank"];
}

- (void)testShouldRaiseExceptionForNilImage
{
    SinglyCache *cache = SinglyCache.sharedCache;
    STAssertThrows([cache cacheImage:nil forURL:@"http://localhost/blank"], @"Setting a nil image did not throw an exception!");
}

- (void)testShouldRaiseExceptionForNilURL
{
    SinglyCache *cache = SinglyCache.sharedCache;
    STAssertThrows([cache cacheImage:[self blankImage] forURL:nil], @"Setting a nil URL did not throw an exception!");
}

- (void)testShouldReturnCachedImage
{
    SinglyCache *cache = SinglyCache.sharedCache;
    NSString *testURL = @"http://localhost/test";
    UIImage *testImage = [self blankImage];
    UIImage *cachedImage;

    [cache cacheImage:testImage forURL:testURL];
    cachedImage = [cache cachedImageForURL:testURL];

    STAssertEquals(testImage, cachedImage, @"Cached image does not equal the test image.");
}

- (void)testCheckForExistenceShouldReturnTrueForCachedImage
{
    SinglyCache *cache = SinglyCache.sharedCache;
    NSString *testURL = @"http://localhost/test";
    UIImage *testImage = [self blankImage];
    BOOL isCached = NO;

    [cache cacheImage:testImage forURL:testURL];
    isCached = [cache cachedImageExistsForURL:testURL];

    STAssertTrue(isCached, @"Check for cached image should be true.");
}

- (void)testCheckForExistenceShouldReturnFalseForUnknownImage
{
    SinglyCache *cache = SinglyCache.sharedCache;
    BOOL isCached = YES;

    isCached = [cache cachedImageExistsForURL:@"http://localhost/unknown"];

    STAssertFalse(isCached, @"Check for cached image should be false.");
}

#pragma mark -

- (UIImage *)blankImage
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, rect);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

@end
