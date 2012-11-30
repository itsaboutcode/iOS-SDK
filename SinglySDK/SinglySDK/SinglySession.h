//
//  SinglySession.h
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

@class SinglyService, SinglySession;

/*!
 *
 * Notification raised when a session's profiles have been updated.
 *
**/
static NSString *kSinglySessionProfilesUpdatedNotification = @"com.singly.notifications.sessionProfilesUpdated";

/*!
 *
 * Notification raised when a service has been applied to the Singly API.
 *
**/
static NSString *kSinglyServiceAppliedNotification = @"com.singly.notifications.serviceApplied";

/*!
 *
 * Manages the current session state.
 *
**/
@interface SinglySession : NSObject

/*!
 *
 * The access token that will be used for all Singly API requests.
 *
 * @property accessToken
 *
**/
@property (copy) NSString *accessToken;

/*!
 *
 * The account ID associated with the current access token.
 *
 * @property accountID
 *
**/
@property (copy) NSString *accountID;

/*!
 *
 * The client ID to be used while authenticating against the Singly API.
 *
 * @property clientID
 *
**/
@property (copy) NSString *clientID;

/*!
 *
 * The client secret to be used while authenticating against the Singly API.
 *
 * @property clientSecret
 *
**/
@property (copy) NSString *clientSecret;

/*!
 *
 * Profiles of the services that the account has connected.  Will return until
 * there is a valid session.
 *
 * @property profiles
**/
@property (readonly) NSDictionary *profiles;

/*!
 *
 * The service the is currently being authorized. This is necessary for
 * integration with 3rd party apps on the iPhone so that we know which service
 * has been authorized after our app is opened again.
 *
 * @property authorizingService
**/
@property (nonatomic, strong) SinglyService *authorizingService;

/*!
 *
 * Access the shared session object
 *
 * This is the preferred way to use the SinglySession and you should only create
 * a new instance if you must use multiple sessions inside one app.
 *
**/
+ (SinglySession *)sharedSession;

/*!
 *
 * Get the session in a state that is ready to make API calls.
 *
 * @param block The block to run when the check is complete. It will be passed a BOOL stating if the session is ready.
 *
**/
- (void)startSessionWithCompletionHandler:(void (^)(BOOL))block;

/*!
 *
 * Explicitly go and update the profiles. Posts a notification when profiles
 * have been updated.
 *
**/
- (void)updateProfiles;

/*!
 *
 * Explicitly go and update the profiles
 *
 * @param block The block to call when the profile update is complete
 *
**/
- (void)updateProfilesWithCompletion:(void (^)(BOOL))block;

/*!
 *
 * Handles app launches by oauth redirection requests and maps them appropriately
 * based on the service.
 *
 * @param url The redirection URL that should be handled
 *
**/
- (BOOL)handleOpenURL:(NSURL *)url;

/*!
 *
 * Allows you to associate a service with an existing access token to the Singly
 * session.
 *
 * @param serviceIdentifier The service identifier (e.g. "facebook", "twitter", etc)
 * @param token The access token to associate
 *
**/
- (void)applyService:(NSString *)serviceIdentifier withToken:(NSString *)token;

@end
