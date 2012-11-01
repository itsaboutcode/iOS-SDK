//
//  SinglyFacebookServiceWrapper.m
//  SinglySDK
//
//  Created by Justin Mecham on 10/26/12.
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//

#import "SinglyFacebookServiceWrapper.h"

@implementation SinglyFacebookServiceWrapper

+ (BOOL)nativeAuthSupported
{
    BOOL supported = YES;

    NSDictionary *urlTypesDictionary = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    if (!urlTypesDictionary)
        supported = NO;

    NSArray *urlSchemesArray = [urlTypesDictionary valueForKey:@"CFBundleURLSchemes"];
    if (!urlSchemesArray)
        supported = NO;
    else
        urlSchemesArray = urlSchemesArray[0];

    if ([urlSchemesArray indexOfObject:@"fb325008370894171"] == NSNotFound)
        supported = NO;

    if (!supported)
        NSLog(@"Missing facebook url scheme");

    return supported;
}

@end
