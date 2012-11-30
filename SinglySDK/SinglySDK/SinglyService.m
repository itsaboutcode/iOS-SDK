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

#import "SinglyRequest.h"
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

    // Configure the Request
    NSError *requestError;
    NSError *parseError;
    NSURLResponse *response;
    SinglyRequest *request = [[SinglyRequest alloc] initWithEndpoint:[NSString stringWithFormat:@"auth/%@/client_id/%@", SinglySession.sharedSession.clientID, self.serviceIdentifier]];
    request.isAuthorizedRequest = NO;

    // Send the request and check for errors...
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
    if (requestError)
    {
        NSLog(@"[SinglySDK] A request error occurred while attempting to fetch the client id from '%@': %@", request.URL, requestError);
        return;
    }

    // Parse the response and check for errors...
    NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];
    if (parseError)
    {
        NSLog(@"[SinglySDK] A parse error occurred while attempting to parse the client id response for '%@': %@", self.serviceIdentifier, parseError);
        return;
    }

    // Check for service errors...
    NSError *serviceError = responseDictionary[@"error"];
    if (serviceError)
    {
        NSLog(@"[SinglySDK] A service error occured while attempting to fetch the client id for '%@': %@", self.serviceIdentifier, serviceError);
        return;
    }

    self.clientID = responseDictionary[self.serviceIdentifier];

    NSLog(@"[SinglySDK] Retrieved Client ID for '%@': %@", self.serviceIdentifier, self.clientID);

}

#pragma mark -

+ (NSString *)normalizeServiceIdentifier:(NSString *)serviceIdentifier
{
    serviceIdentifier = [serviceIdentifier lowercaseString];
    return serviceIdentifier;
}

#pragma mark -

- (void)requestAuthorizationFromViewController:(UIViewController *)viewController withScopes:(NSArray *)scopes
{

    self.isAuthorized = NO;

    dispatch_queue_t authorizationQueue;
    authorizationQueue = dispatch_queue_create("com.singly.AuthorizationQueue", NULL);

    dispatch_async(authorizationQueue, ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            [self requestAuthorizationViaSinglyFromViewController:viewController withScopes:scopes];
        });

    });
    
}

- (void)requestAuthorizationViaSinglyFromViewController:(UIViewController *)viewController
{
    [self requestAuthorizationFromViewController:viewController withScopes:nil];
}

- (void)requestAuthorizationViaSinglyFromViewController:(UIViewController *)viewController withScopes:(NSArray *)scopes
{

    SinglyLoginViewController *loginViewController = [[SinglyLoginViewController alloc] initWithServiceIdentifier:self.serviceIdentifier];
    loginViewController.scopes = scopes;
    loginViewController.delegate = self;
    [viewController presentModalViewController:loginViewController animated:YES];

}

#pragma mark - Login View Controller Delegates

- (void)singlyLoginViewController:(SinglyLoginViewController *)controller didLoginForService:(NSString *)service
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidAuthorize:)])
        [self.delegate singlyServiceDidAuthorize:self];
}

- (void)singlyLoginViewController:(SinglyLoginViewController *)controller errorLoggingInToService:(NSString *)service withError:(NSError *)error
{
    [controller dismissViewControllerAnimated:NO completion:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(singlyServiceDidFail:withError:)])
        [self.delegate singlyServiceDidFail:self withError:error];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
