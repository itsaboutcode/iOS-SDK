//
//  SinglyLogInViewController.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/22/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SinglySession.h"

@class SinglyLoginViewController;

@protocol SinglyLoginViewControllerDelegate <NSObject>

- (void)singlyLoginViewController:(SinglyLoginViewController *)controller didLoginForService:(NSString *)service;
- (void)singlyLoginViewController:(SinglyLoginViewController *)controller errorLoggingInToService:(NSString *)service withError:(NSError *)error;

@end

@interface SinglyLoginViewController : UIViewController <UIWebViewDelegate, NSURLConnectionDataDelegate>

@property (weak, atomic) id<SinglyLoginViewControllerDelegate> delegate;

/*!
 *
 * The SinglySession to use for the login request. The default value of this is
 * the shared singleton instance.
 *
 */
@property (strong, nonatomic) SinglySession *session;

@property (strong, atomic) NSString *targetService;
@property (strong, atomic) NSString *scope;
@property (strong, atomic) NSString *flags;

/*!
 *
 * Initialize with a SinglySession and service identifier.
 *
 * @param session The session that the login will be saved into.
 * @param serviceId The name of the service that we are logging into.
 */
- (id)initWithSession:(SinglySession *)session forService:(NSString *)serviceId;

@end
