//
//  SinglyLogInViewController.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/22/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SinglySession.h"

@protocol SinglyLogInViewControllerDelegate <NSObject>

-(void)singlyLogInViewController:(SinglyLogInViewController*)controller didLoginForService:(NSString*)service;
-(void)singlyLogInViewController:(SinglyLogInViewController *)controller errorLoggingInToService:(NSString *)service withError:(NSError*)error;
@end

@interface SinglyLogInViewController : UIViewController<UIWebViewDelegate, NSURLConnectionDataDelegate>
/*!
 Initialize with a session and service
 @param session
    The session that the login will be saved into.
 @param serviceId
    The name of the service that we are logging into.
*/
- (id)initWithSession:(SinglySession*)session forService:(NSString*)serviceId;

@property (strong, atomic) id<SinglyLogInViewControllerDelegate> delegate;
@property (strong, atomic) NSString* scope;
@property (strong, atomic) NSString* flags;

@end
