//
//  SinglyTwitterService.h
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

@interface SinglyTwitterService ()

/*!
 *
 * Retrieves the reverse auth parameters from Twitter to be used when requesting
 * an access token.
 *
 * @param error Out parameter used if an error occurs while retrieving the
 *              reverse auth parameters. May be `NULL`.
 *
 * @returns The reverse auth parameters from Twitter.
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (NSString *)fetchReverseAuthParameters:(NSError **)error;

/*!
 *
 * Retrieves the reverse auth parameters from Twitter to be used when requesting
 * an access token. Once the request has completed, the specified
 * `completionHandler` will be called.
 *
 * @param completionHandler The block to run when the request is complete. It
 *                          be passed the access token or the error.
 *
 * @returns The reverse auth parameters from Twitter.
 *
 * @available Available in Singly iOS SDK 1.2.0 and later.
 *
**/
- (void)fetchReverseAuthParametersWithCompletion:(void (^)(NSString *accessToken, NSError *error))completionHandler;

@end