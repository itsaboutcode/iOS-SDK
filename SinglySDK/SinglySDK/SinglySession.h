//
//  SinglySession.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/21/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SinglySessionDelegate <NSObject>
@required
-(void)singlyResultForAPI:(NSString*)api withJSON:(id)json;
-(void)singlyErrorForAPI:(NSString*)api withError:(NSError*)error;
@end

@interface SinglySession : NSObject {
}
@property (strong, atomic, getter = getAccessToken, setter = setAccessToken:) NSString* accessToken;
@property (strong, atomic, getter = getAccountID, setter = setAccountID:) NSString* accountID;
@property (strong, atomic) id<SinglySessionDelegate> delegate;

-(void)setAccountID:(NSString *)accountID;
-(NSString*)getAccountID;

-(void)setAccessToken:(NSString *)accessToken;
-(NSString*)getAccessToken;

-(void)checkReadyWithBlock:(void (^)(BOOL))block;
-(void)requestAPI:(NSString*)api withParameters:(NSDictionary*)params;
@end

