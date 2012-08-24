//
//  SinglyLogInViewController.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/22/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SinglySession.h"

@interface SinglyLogInViewController : UIViewController<UIWebViewDelegate, NSURLConnectionDataDelegate>
- (id)initWithSession:(SinglySession*)session forService:(NSString*)serviceId;

@property (strong, atomic) NSString* clientID;
@property (strong, atomic) NSString* clientSecret;
@property (strong, atomic) NSString* scope;
@property (strong, atomic) NSString* flags;

@end
