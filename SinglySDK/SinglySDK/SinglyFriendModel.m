//
//  SinglyFriendModel.m
//  SinglySDK
//
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "SinglyRequest.h"
#import "SinglyFriendModel.h"
#import "SinglySession.h"

@implementation SinglyFriendModel

- (id)initWithSession:(SinglySession *)session
{
    self = [super init];
    if (self)
    {
        _session = session;
    }
    return self;
}

- (id)initWithSession:(SinglySession *)session forService:(NSArray *)services
{
    self = [super init];
    if (self)
    {
        _session = session;
        _services = services;
    }
    return self;
}

- (void)fetchDataWithCompletionHandler:(DataReadyBlock)completionHandler
{

    SinglyRequest *request = [SinglyRequest requestWithEndpoint:@"types/contacts" andParameters:@{ @"limit": @"500" }];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError)
    {
//        // Get out of here on system or remote errors
//        if (error || ([json isKindOfClass:[NSDictionary class]] && [json objectForKey:@"error"])) {
//            NSError* finalError = error ? error : [NSError errorWithDomain:@"SinglySDK" code:100 userInfo:@{NSLocalizedDescriptionKey:[json objectForKey:@"error"]}];
//            return completionHandler(finalError);
//        }

        NSArray *friends = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
        NSMutableArray *allFriends = [NSMutableArray arrayWithCapacity:friends.count];
        for (NSDictionary *friend in friends)
        {
            NSDictionary *oEmbed = [friend objectForKey:@"oembed"];

            if (!oEmbed || ![oEmbed objectForKey:@"title"])
                NSLog(@"Skipped for no title or oembed");

            NSMutableDictionary *friendInfo = [NSMutableDictionary dictionaryWithDictionary:oEmbed];
            // Parse the idr and get the service out
            NSString *idr = [friend objectForKey:@"idr"];
            NSRange serviceRange = [idr rangeOfString:@"@"];
            serviceRange.location++;
            serviceRange.length = [idr rangeOfString:@"/"].location - serviceRange.location;
            [friendInfo setObject:@{[idr substringWithRange:serviceRange]:[friend objectForKey:@"data"]} forKey:@"services"];
            [allFriends addObject:friendInfo];
        }

        _friends = allFriends;
    }];

}

@end
