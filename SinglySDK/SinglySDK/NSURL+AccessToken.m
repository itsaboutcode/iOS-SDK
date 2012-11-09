//
//  NSURL+AccessToken.m
//  SinglySDK
//
//  Created by Justin Mecham on 11/6/12.
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//

#import "NSDictionary+QueryString.h"
#import "NSURL+AccessToken.h"

@implementation NSURL (AccessToken)

- (NSString *)extractAccessToken
{
    NSString *queryString = self.fragment;
    if (!queryString) queryString = self.query;

    NSDictionary *params = [NSDictionary dictionaryWithQueryString:queryString];
    NSString *accessToken = [params objectForKey:@"access_token"];

    return accessToken;
}

@end
