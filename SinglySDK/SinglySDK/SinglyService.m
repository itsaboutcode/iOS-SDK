//
//  SinglyService.m
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

#import "SinglySession.h"
#import "SinglyService.h"
#import "SinglyService+Internal.h"
#import "SinglyFacebookService.h"

@implementation SinglyService

+ (id)serviceWithIdentifier:(NSString *)serviceIdentifier
{

    // Normalize the Service Identifier
    serviceIdentifier = [SinglyService normalizeServiceIdentifier:serviceIdentifier];

    // Custom Service for Facebook
    if ([serviceIdentifier isEqualToString:@"facebook"])
        return [self facebookService];

    SinglyService *serviceInstance = [[SinglyService alloc] initWithIdentifier:serviceIdentifier];
    return serviceInstance;

}

+ (SinglyFacebookService *)facebookService
{
    SinglyFacebookService *serviceInstance = [[SinglyFacebookService alloc] initWithIdentifier:@"facebook"];
    return serviceInstance;
}

- (id)initWithIdentifier:(NSString *)serviceIdentifier
{
    if (self = [self init])
    {
        serviceIdentifier = [SinglyService normalizeServiceIdentifier:serviceIdentifier];
        _serviceIdentifier = serviceIdentifier;
    }
    return self;
}

#pragma mark -

- (void)fetchClientID
{

    // If we already have the Client ID, do not attempt to fetch it again...
    if (self.clientID) return;

    // Make a request to the Singly API for the Client ID...
    NSError *requestError;
    NSError *parseError;
    NSURLResponse *response;
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.singly.com/v0/auth/%@/client_id/%@", [[SinglySession sharedSession] clientID], self.serviceIdentifier]];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];

    // TODO Add error handling to the request
    // TODO Add error handling to JSON parse

    NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&parseError];
    self.clientID = responseDictionary[@"facebook"];

    NSLog(@"[SinglySDK] Retrieved Client ID for '%@': %@", self.serviceIdentifier, self.clientID);
}

#pragma mark -

+ (NSString *)normalizeServiceIdentifier:(NSString *)serviceIdentifier
{
    serviceIdentifier = [serviceIdentifier lowercaseString];
    return serviceIdentifier;
}

#pragma mark -

- (void)requestAuthorizationWithViewController:(UIViewController *)viewController
{

    self.isAuthorized = NO;

    dispatch_queue_t authorizationQueue;
    authorizationQueue = dispatch_queue_create("com.singly.AuthorizationQueue", NULL);

    dispatch_async(authorizationQueue, ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            [self requestAuthorizationViaSinglyWithViewController:viewController];
        });

    });
    
}

- (void)requestAuthorizationViaSinglyWithViewController:(UIViewController *)viewController
{

    SinglyLoginViewController *loginViewController = [[SinglyLoginViewController alloc] initWithSession:[SinglySession sharedSession] forService:self.serviceIdentifier];
    loginViewController.delegate = self;
    [viewController presentModalViewController:loginViewController animated:YES];
    
}

@end
