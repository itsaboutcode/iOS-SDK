//
//  SinglyLoginPickerViewController.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/29/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SinglySession.h"
#import "SinglyLoginViewController.h"

@interface SinglyLoginPickerViewController : UITableViewController <SinglySessionDelegate, SinglyLoginViewControllerDelegate>

@property (strong, atomic) NSArray *services;

/*!
 *
 * The SinglySession to use for the login requests. The default value of this is
 * the shared singleton instance.
 *
 */
@property (strong, nonatomic) SinglySession *session;

- (id)initWithSession:(SinglySession *)session;

@end
