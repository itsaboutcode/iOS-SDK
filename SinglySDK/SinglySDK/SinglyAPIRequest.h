//
//  SinglyAPIRequest.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/24/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SinglyAPIRequest;

@protocol SinglyAPIRequestDelegate <NSObject>
-(void)singlyAPIRequest:(SinglyAPIRequest*)request succeededWithJSON:(id)json;
-(void)singlyAPIRequest:(SinglyAPIRequest *)request failedWithError:(NSError*)error;
@end

@interface SinglyAPIRequest : NSObject

@property (copy) NSString* endpoint;
@property (copy) NSString* method;
@property (copy) NSData* body;

+(SinglyAPIRequest*)apiRequestForEndpoint:(NSString*)endpoint withParameters:(NSDictionary*)parameters;
-(id)initWithEndpoint:(NSString*)endpoint andParameters:(NSDictionary*)parameters;
-(NSString*)completeURLForToken:(NSString*)accessToken;
@end
