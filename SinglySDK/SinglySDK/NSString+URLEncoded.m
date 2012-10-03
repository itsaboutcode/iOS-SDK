//
//  NSString+NSString_URIEncoding.m
//  SinglySDK
//
//  Created by Thomas Muldowney on 10/3/12.
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//

#import "NSString+URLEncoded.h"

@implementation NSString (URLEncoded)

- (NSString *)URLEncodedString;
{
    __autoreleasing NSString *encodedString;
    
    NSString *originalString = (NSString *)self;
    encodedString = (__bridge_transfer NSString * )
    CFURLCreateStringByAddingPercentEscapes(NULL,
                                            (__bridge CFStringRef)originalString,
                                            NULL,
                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                            kCFStringEncodingUTF8);
    return encodedString;
}

@end
