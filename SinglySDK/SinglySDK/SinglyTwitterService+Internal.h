//
//  SinglyTwitterService.h
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

/*!
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
typedef void (^SinglyAuthParametersCompletionBlock)(NSString *authParameters, NSError *error);

/*!
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
typedef void (^SinglyTwitterAccessTokenCompletionBlock)(NSDictionary *accessToken, NSError *error);

@interface SinglyTwitterService ()

/// ----------------------------------------------------------------------------
/// @name Requesting Authorization
/// ----------------------------------------------------------------------------

/*!
 *
 * Attempts to request authorization from the device using the native Twitter
 * support available on iOS 5+.
 *
 * @param scopes The optional scopes to request permissions for.
 *
 * @available Available in Singly iOS SDK 1.2.2 and later.
 *
**/
- (void)requestNativeAuthorization:(NSArray *)scopes
                        completion:(SinglyAuthorizationCompletionBlock)completionHandler;

/*!
 *
 * Denotes whether the user has aborted the authorization process.
 *
 * @available Available in Singly iOS SDK 1.2.2 and later.
 *
**/
@property BOOL isAborted;

/// ----------------------------------------------------------------------------
/// @name Handling Reverse Authentication
/// ----------------------------------------------------------------------------

/*!
 *
 * Retrieves the reverse auth parameters from Twitter to be used when requesting
 * an access token.
 *
 * @param error Out parameter used if an error occurs while retrieving the
 *              reverse auth parameters. May be `NULL`.
 *
 * @returns The reverse auth parameters from Twitter.
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (NSString *)fetchReverseAuthParameters:(NSError **)error;

/*!
 *
 * Retrieves the reverse auth parameters from Twitter to be used when requesting
 * an access token. Once the request has completed, the specified
 * `completionHandler` will be called.
 *
 * @param completionHandler The block to run when the request is complete. It
 *                          be passed the reverse auth parameters or the error.
 *
 * @returns The reverse auth parameters from Twitter.
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (void)fetchReverseAuthParametersWithCompletion:(SinglyAuthParametersCompletionBlock)completionHandler;

/// ----------------------------------------------------------------------------
/// @name Retrieving Access Tokens
/// ----------------------------------------------------------------------------

/*!
 *
 * Retrieves the access token and token secret from Twitter.
 *
 * @param account The Twitter account to request access token and token secret
 *                for.
 *
 * @param error Out parameter used if an error occurs while retrieving the
 *              access token and token secret. May be `NULL`.
 *
 * @returns The access token and token secret from Twitter.
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (NSDictionary *)fetchAccessTokenForAccount:(ACAccount *)account
                                       error:(NSError **)error;

/*!
 *
 * Retrieves the access token and token secret from Twitter. Once the request
 * has completed, the specified `completionHandler` will be called.
 *
 * @param account The Twitter account to request access token and token secret
 *                for.
 *
 * @param completionHandler The block to run when the request is complete. It
 *                          be passed the access token or the error.
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (void)fetchAccessTokenForAccount:(ACAccount *)account
                        completion:(SinglyTwitterAccessTokenCompletionBlock)completionHandler;

@end
