//
//  SinglySession.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/21/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SinglySession;

@protocol SinglySessionDelegate <NSObject>
@required
-(void)singlySession:(SinglySession*)session resultForAPI:(NSString*)api withJSON:(id)json;
-(void)singlySession:(SinglySession*)session errorForAPI:(NSString*)api withError:(NSError*)error;
-(void)singlySession:(SinglySession*)session didLogInForService:(NSString*)service;
-(void)singlySession:(SinglySession *)session errorLoggingInToService:(NSString *)service withError:(NSError*)error;
@end

@interface SinglySession : NSObject {
}
@property (copy) NSString* accessToken;
@property (copy) NSString* accountID;
@property (strong, atomic) id<SinglySessionDelegate> delegate;

-(void)checkReadyWithCompletionHandler:(void (^)(BOOL))block;
-(void)requestAPI:(NSString*)api withParameters:(NSDictionary*)params;
@end

