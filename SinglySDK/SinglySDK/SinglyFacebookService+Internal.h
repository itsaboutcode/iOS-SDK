//
//  SinglyFacebookService+Internal.h
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

#import <SinglySDK/SinglySDK.h>

@interface SinglyFacebookService ()

/// ----------------------------------------------------------------------------
/// @name Requesting Authorization
/// ----------------------------------------------------------------------------

/*!
 *
 * Attempts to request authorization from the Facebook app installed on the
 * device.
 *
 * @param scopes The optional scopes to request permissions for.
 *
 * @returns `YES` if the application was able to be launched.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
- (BOOL)requestApplicationAuthorization:(NSArray *)scopes;

/*!
 *
 * Attempts to request authorization from the device using the native Facebook
 * support available on iOS 6+.
 *
 * @param viewController The view controller instance that is presenting the
 *                       authorization request.
 *
 * @param scopes The scope(s) to request from the service. You may request
 *               either read or write permissions, but not read and write within
 *               the same authorization request.
 *
 * @param completionHandler The block to run when the request is complete. It
 *                          will be passed a `BOOL` stating whether or not the
 *                          operation succeeded.
 *
 * @available Available in Singly iOS SDK 1.2.2 and later.
 *
**/
- (void)requestNativeAuthorizationFromViewController:(UIViewController *)viewController
                                          withScopes:(NSArray *)scopes;

/*!
 *
 * Denotes whether the user has aborted the authorization process.
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
@property (readonly) BOOL isAborted;

@end