//
//  SinglyConnection.m
//  SinglySDK
//
//  Copyright (c) 2012-2013 Singly, Inc. All rights reserved.
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

#import "SinglyConnection.h"
#import "SinglyConstants.h"
#import "SinglyLog.h"
#import "SinglyRequest+Internal.h"

@implementation SinglyConnection

+ (id)connectionWithRequest:(SinglyRequest *)request
{
    SinglyConnection *connection = [[SinglyConnection alloc] initWithRequest:request];
    return connection;
}

- (id)initWithRequest:(SinglyRequest *)request
{
    self = [super init];
    if (self)
    {

        // Default Values
        self.request = request;

    }
    return self;
}

#pragma mark -

- (id)performRequest:(NSError **)error
{
    NSData *responseData;
    NSURLResponse *response;
    NSError *requestError;
    NSError *parseError;

    // Perform Request
    responseData = [NSURLConnection sendSynchronousRequest:self.request
                                         returningResponse:&response
                                                     error:&requestError];

    // Check for Request Errors
    if (requestError)
    {

        // Invalid Access Token
        if (requestError.code == NSURLErrorUserCancelledAuthentication)
        {
            if (error)
            {
                NSError *serviceError = [NSError errorWithDomain:kSinglyErrorDomain
                                                            code:kSinglyInvalidAccessTokenErrorCode
                                                        userInfo:@{ NSLocalizedDescriptionKey : kSinglyInvalidAccessTokenErrorMessage }];
                *error = serviceError;
            }
            return nil;
        }

        if (error) *error = requestError;
        return nil;
    }

    // Parse the JSON Response
    id responseObject = [NSJSONSerialization JSONObjectWithData:responseData
                                                        options:NSJSONReadingAllowFragments
                                                          error:&parseError];

    // Check for Parse Errors
    if (parseError)
    {
        if (error) *error = parseError;
        return nil;
    }

    // Check for Service Errors
    if (responseObject && [responseObject isKindOfClass:[NSDictionary class]] && responseObject[@"error"])
    {
        if (error)
        {
            NSString *serviceErrorMessage = responseObject[@"error"];
            NSError *serviceError = [NSError errorWithDomain:kSinglyErrorDomain
                                                        code:kSinglyServiceErrorCode
                                                    userInfo:@{ NSLocalizedDescriptionKey : serviceErrorMessage }];
            *error = serviceError;
        }
        return nil;
    }
    
    return responseObject;
}

- (void)performRequestWithCompletion:(void (^)(id responseObject, NSError *error))completionHandler
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSError *error;
        id responseObject = [self performRequest:&error];

        if (completionHandler) dispatch_sync(currentQueue, ^{
            completionHandler(responseObject, error);
        });
        
    });
}

@end
