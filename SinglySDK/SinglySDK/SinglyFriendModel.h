//
//  SinglyFriendModel.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 9/25/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SinglySession;

typedef void(^DataReadyBlock)(NSError*);

@interface SinglyFriendModel : NSObject

/*!
Init the model for all services
*/
-(id)initWithSession:(SinglySession*)session;
/*!
Init the session only for the given services only
*/
-(id)initWithSession:(SinglySession *)session forService:(NSArray*)services;

-(void)fetchDataWithCompletionHandler:(DataReadyBlock)completionHandler;

@end
