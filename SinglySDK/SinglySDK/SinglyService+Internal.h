//
//  SinglyService+Internal.h
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

#import "SinglyFacebookService.h"
#import "SinglyTwitterService.h"

/*!
 *
 * @available Available in Singly iOS SDK 1.3.0 and later.
 *
**/
typedef void (^SinglyFetchClientIdentifierCompletionBlock)(NSString *clientIdentifier, NSError *error);

@interface SinglyService ()

/*!
 *
 * A convenience accessor for creating and returning an instance of the Facebook
 * service.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
+ (SinglyFacebookService *)facebookService;

/*!
 *
 * A convenience accessor for creating and returning an instance of the Twitter
 * service.
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
+ (SinglyTwitterService *)twitterService;

/*!
 *
 * Fetches the client id for the service from the Singly API.
 *
 * @param error Out parameter used if an error occurs while fetching the client
 *              id. May be `NULL`.
 *
 * @returns `YES` if the request was successful.
 *
 * @see fetchClientIdentifierWithCompletion:
 *
 * @available Available in Singly iOS SDK 1.3.0 and later.
 *
**/
- (NSString *)fetchClientIdentifier:(NSError **)error;

/*!
 *
 * Fetches the client id for the service from the Singly API.
 *
 * @param completionHandler The block to run when the check is complete. It will
 *                          be passed a `BOOL` stating whether or not the
 *                          operation succeeded.
 *
 * @see fetchClientIdentifier:
 *
 * @available Available in Singly iOS SDK 1.3.0 and later.
 *
 **/
- (void)fetchClientIdentifierWithCompletion:(SinglyFetchClientIdentifierCompletionBlock)completionHandler;

/*!
 *
 * Takes the specified service identifier and normalizes it by ensuring that it
 * is downcased and is in line with what is expected by the API.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
+ (NSString *)normalizeServiceIdentifier:(NSString *)serviceIdentifier;


/// ----------------------------------------------------------------------------
/// @name Requesting Authorization
/// ----------------------------------------------------------------------------

/*!
 *
 * Requests authorization from Singly by initializing an instance of the login
 * view controller and configuring it for the service identified by the current
 * instance and any custom scope(s). The specified `completionHandler` will be
 * called once the operation has completed.
 *
 * @see requestAuthorizationViaSinglyFromViewController:
 * @see requestAuthorizationViaSinglyFromViewController:withScopes:
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (void)requestAuthorizationViaSinglyFromViewController:(UIViewController *)viewController
                                             withScopes:(NSArray *)scopes
                                             completion:(SinglyServiceAuthorizationCompletionHandler)completionHandler;

/*!
 *
 * Stores the completion handler to be used after authorization requests are
 * completed.
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
@property (nonatomic, strong) SinglyServiceAuthorizationCompletionHandler completionHandler;

/*!
 *
 * Denotes whether or not the service is authorized. This property is only used
 * during the authorization workflow and does not indicate current authorization
 * status in the Singly API.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
@property (readonly) BOOL isAuthorized;

/// ----------------------------------------------------------------------------
/// @name Authorization Callbacks
/// ----------------------------------------------------------------------------

/*!
 *
 * This method is called once the user has been successfully authorized with the
 * service. It is responsible for posting notifications, informing delegates and
 * calling the completion handler.
 *
 * @available Available in Singly iOS SDK 1.3.0 and later.
 *
 **/
- (void)serviceDidAuthorize:(SinglyServiceAuthorizationCompletionHandler)completionHandler;

/*!
 *
 * This method is called if there was an error during the authorization process.
 * It is responsible for posting notifications, informing delegates and calling
 * the completion handler.
 *
 * @available Available in Singly iOS SDK 1.3.0 and later.
 *
 **/
- (void)serviceDidFailAuthorizationWithError:(NSError *)error
                           completion:(SinglyServiceAuthorizationCompletionHandler)completionHandler;

@end
