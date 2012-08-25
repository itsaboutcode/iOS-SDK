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

/*!
 Create a new API request
 @param endpoint
    The Singly API endpoint to hit, does not need to include the / at the begninning
 @param parameters
    A NSDictionary of the query string parameters to send on the request.  This may be nil.
*/
+(SinglyAPIRequest*)apiRequestForEndpoint:(NSString*)endpoint withParameters:(NSDictionary*)parameters;
/*!
 Create a new API request
 @param endpoint
 The Singly API endpoint to hit, does not need to include the / at the begninning
*/
+(SinglyAPIRequest*)apiRequestForEndpoint:(NSString *)endpoint;
-(id)initWithEndpoint:(NSString*)endpoint andParameters:(NSDictionary*)parameters;
-(NSString*)completeURLForToken:(NSString*)accessToken;
@end
