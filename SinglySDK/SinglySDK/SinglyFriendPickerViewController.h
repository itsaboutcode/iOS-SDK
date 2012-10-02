//
//  SinglyFriendPickerViewController.h
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/30/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SinglySDK/SinglySession.h>

@interface SinglyFriendPickerViewController : UITableViewController

@property (strong, nonatomic) NSArray* pickedFriends;


/*!
 *
 * The SinglySession to use. The default value is the shared singleton instance.
 *
 */
@property (strong, nonatomic) SinglySession *session;

- (id)initWithSession:(SinglySession *)session;

@end
