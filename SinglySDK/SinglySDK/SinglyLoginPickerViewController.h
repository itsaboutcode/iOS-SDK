//
//  SinglyLoginPickerViewController.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/29/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SinglySDK/SinglySDK.h>

@interface SinglyLoginPickerViewController : UITableViewController <SinglyLoginViewControllerDelegate>

@property (strong, atomic) NSArray *services;
@property (strong, atomic) SinglySession *session;

- (id)initWithSession:(SinglySession *)session;

@end
