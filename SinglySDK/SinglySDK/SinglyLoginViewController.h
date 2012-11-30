//
//  SinglyLogInViewController.h
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

#import <UIKit/UIKit.h>
#import <SinglySDK/SinglySession.h>

@class SinglyLoginViewController;

/*!
 *
 * @protocol SinglyLoginViewControllerDelegate
 * @abstract Delegate methods related to a SinglyLoginViewController
 *
 **/
@protocol SinglyLoginViewControllerDelegate <NSObject>

/*!
 *
 * This method is invoked on the delegate after login was successful.
 *
 * @param controller The login view controller instance.
 * @param service The service identifier.
 *
**/
- (void)singlyLoginViewController:(SinglyLoginViewController *)controller didLoginForService:(NSString *)service;

/*!
 *
 * This method is invoked on the delegate when an error occurs during the login
 * process.
 *
 * @param controller The login view controller instance.
 * @param service The service identifier.
 * @param error The error that occurred.
 *
**/
- (void)singlyLoginViewController:(SinglyLoginViewController *)controller errorLoggingInToService:(NSString *)service withError:(NSError *)error;

@end

/*!
 *
 * A view controller for requesting authorization from a supported service via
 * a web view.
 *
 * In general, you should use SinglyService to invoke authorization requests as
 * opposed to using this view controller directly. If you need to do something
 * more custom, then this view controller is a good starting point.
 *
**/
@interface SinglyLoginViewController : UIViewController <UIWebViewDelegate, NSURLConnectionDataDelegate>

/*!
 *
 * When defined, this delegate will be called when authorization succeeds or
 * fails.
 *
**/
@property (nonatomic, strong) id<SinglyLoginViewControllerDelegate> delegate;

/*!
 *
 * The service identifier of the service we are attempting to authenticate with.
 *
**/
@property (nonatomic, strong) NSString *serviceIdentifier;

/*!
 *
 * Custom scope to request from the service.
 *
**/
@property (nonatomic, strong) NSArray *scopes;

/*!
 *
 * Some services may require a custom flag, so specify them here.
 *
**/
@property (nonatomic, strong) NSString *flags;

/*!
 *
 * Initialize with a service identifier.
 *
 * @param serviceIdentifier The name of the service that we are logging into.
 *
**/
- (id)initWithServiceIdentifier:(NSString *)serviceIdentifier;

@end
