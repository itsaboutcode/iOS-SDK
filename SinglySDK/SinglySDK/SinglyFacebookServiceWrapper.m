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

    for (NSString *urlScheme in urlSchemesArray)
    {
        if ([urlScheme hasPrefix:@"fb"])
        {
            supported = YES;
            break;
        }
        else
            supported = NO;
    }

    if (!supported)
        NSLog(@"[SinglySDK] Missing facebook url scheme in Info.plist");

    return supported;
}

@end
