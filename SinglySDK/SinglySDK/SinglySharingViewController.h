//
//  SinglySharingViewController.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 9/12/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DEFacebookComposeViewController.h"

@class SinglySession;

@interface SinglySharingViewController : DEFacebookComposeViewController

-(id)initWithSession:(SinglySession*)session forService:(NSString*)service;

@end
