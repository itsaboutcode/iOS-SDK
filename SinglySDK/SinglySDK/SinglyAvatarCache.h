//
//  SinglyAvatarCache.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SinglyAvatarCache : NSCache

/// ----------------------------------------------------------------------------
/// @name Accessing the Avatar Cache
/// ----------------------------------------------------------------------------

/*!
 *
 * The shared singleton avatar cache instance.
 *
 * @returns SinglyAvatarCache
 *
 * @available Available in Singly iOS SDK 1.1.0 and later.
 *
**/
+ (SinglyAvatarCache *)sharedCache;

/*!
 *
 * Adds the specified image to the cache for the given URL.
 *
 * @available Available in Singly iOS SDK 1.1.0 and later.
 *
**/
- (void)cacheImage:(UIImage *)image forURL:(NSString *)url;

/*!
 *
 * Looks in the cache for an image for the given URL. If available, it will be
 * returned. This will return a nil value if the image is not cached.
 *
 * @returns UIImage
 *
 * @available Available in Singly iOS SDK 1.1.0 and later.
 *
**/
- (UIImage *)cachedImageForURL:(NSString *)url;

/*!
 *
 * Checks the cache for the presence of an image for the given URL.
 *
 * @returns BOOL
 *
 * @available Available in Singly iOS SDK 1.1.0 and later.
 *
**/
- (BOOL)cachedImageExistsForURL:(NSString *)url;

@end
