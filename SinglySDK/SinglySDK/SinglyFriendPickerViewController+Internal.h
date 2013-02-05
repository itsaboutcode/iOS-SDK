//
//  SinglyFriendPickerViewController+Internal.h
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

@interface SinglyFriendPickerViewController ()

/*!
 *
 * The friends fetched from the Singly API.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
@property (strong, readonly) NSMutableArray *friends;

/*!
 *
 * When the view is first displayed, we hide the table view separators until
 * the initial set of friends has loaded. This property tracks the color of the
 * separators before we cleared them.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
@property (strong) UIColor *originalSeparatorColor;

/*!
 *
 * Denotes whether or not the view controller is currently in the process of
 * refreshing the friends list.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
@property (readonly) BOOL isRefreshing;

/*!
 *
 *
 *
 * @available Available in Singly iOS SDK 1.1.0 and later.
 *
**/
@property (copy) NSArray *indexKeys;

/*!
 *
 *
 *
 * @available Available in Singly iOS SDK 1.1.0 and later.
 *
**/
@property (copy) NSDictionary *indexDetails;

/*!
 *
 *
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (BOOL)fetchFriends:(NSError **)error;

/*!
 *
 *
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (void)fetchFriendsWithCompletion:(void (^)(BOOL isSuccessful, NSError *error))completionHandler;

/*!
 *
 *
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (BOOL)fetchFriendsAtOffset:(NSInteger)offset
                       error:(NSError **)error;

/*!
 *
 *
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (void)fetchFriendsAtOffset:(NSInteger)offset
                  completion:(void (^)(BOOL isSuccessful, NSError *error))completionHandler;

/*!
 *
 *
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (BOOL)fetchFriendsAtOffset:(NSInteger)offset
                       limit:(NSInteger)limit
                       error:(NSError **)error;

/*!
 *
 *
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (void)fetchFriendsAtOffset:(NSInteger)offset
                       limit:(NSInteger)limit
                  completion:(void (^)(BOOL isSuccessful, NSError *error))completionHandler;

@end

