//
//  SinglyKeychainItemWrapper.h
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

/*!
 *
 * The SinglyKeychainItemWrapper class is an abstraction layer for the iPhone
 * Keychain communication. It is merely a simple wrapper to provide a distinct
 * barrier between all the idiosyncracies involved with the Keychain CF/NS
 * container objects.
 *
 * This class is heavily based on KeychainItemWrapper from Apple, but has been
 * modernized with ARC and Objective-C 2.0 syntax.
 *
**/
@interface SinglyKeychainItemWrapper : NSObject

/*!
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
@property (strong) NSMutableDictionary *keychainItemData;

/*!
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
@property (strong) NSMutableDictionary *genericPasswordQuery;

/*!
 *
 * The designated initializer.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
- (id)initWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup;

/*!
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
- (void)setObject:(id)inObject forKey:(id)key;

/*!
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
- (id)objectForKey:(id)key;

/*!
 *
 * Initializes and resets the default generic keychain item data.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
- (void)resetKeychainItem;

@end