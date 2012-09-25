//
//  SinglySession.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/21/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SinglyAPIRequest.h"

@class SinglySession;
@class SinglyLogInViewController;

/*!
 @protocol SinglySessionDelegate
 @abstract Delegate methods related to a SinglySession
*/
@protocol SinglySessionDelegate <NSObject>
@required
/*!
 Delegate method for a successful service login.
 @param session
    The SinglySession that this delegate is firing for
 @param service
    The service name for the successful login
*/
-(void)singlySession:(SinglySession*)session didLogInForService:(NSString*)service;
/*!
 Delegate method for an error during service login
 @param session
    The SinglySession that this delegate is firing for
 @param service
    The service name for the successful login
 @param error
    The error that occured during login
*/
-(void)singlySession:(SinglySession *)session errorLoggingInToService:(NSString *)service withError:(NSError*)error;
@end

@interface SinglySession : NSObject {
}
/*!
 @property accessToken
 The access token that will be used for all Singly API requests.
*/
@property (copy) NSString* accessToken;
/*!
 @property accountID
 The account ID associated with the current access token
*/
@property (copy) NSString* accountID;
@property (copy) NSString* clientID;
@property (copy) NSString* clientSecret;
/*!
 Profiles of the services that the account has connected.  Will return until there is a valid session.
*/
@property (readonly) NSDictionary* profiles;
@property (weak, atomic) id<SinglySessionDelegate> delegate;

/*!
 Checks if the session is ready to make API requests.
 @param block
    The block to run when the check is complete.  It will be passed a BOOL stating if the session is ready.
*/
-(void)checkReadyWithCompletionHandler:(void (^)(BOOL))block;
/*!
 Make a Singly API request and handle the result in a delegate
 @param request
    The SinglyAPIRequest to process
 @param delegate
    The object to call when the process succeeds or errors.
*/
-(void)requestAPI:(SinglyAPIRequest*)request withDelegate:(id<SinglyAPIRequestDelegate>)delegate;
/*!
 Make a Singly API request and handle the result in a block
 @param request
    The SinglyAPIRequest to process
 @param block
    The block to call when the request is complete.
*/
-(void)requestAPI:(SinglyAPIRequest *)request withCompletionHandler:(void (^)(NSError*, id))block;

-(void)updateProfilesWithCompletion:(void (^)())block;
@end

