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

/*!
 *
 * Displays a list of services that can be authenticated against in a list view
 * with the option to log in to any supported services.
 *
 */
@interface SinglyLoginPickerViewController : UITableViewController <SinglySessionDelegate, SinglyLoginViewControllerDelegate>

/*!
 *
 * The services that should be displayed in the picker. This defaults to all of
 * the available services as returned by servicesDictionary, but can be
 * set to just the services you require.
 *
 */
@property (nonatomic, strong) NSArray *services;

/*!
 *
 * A dictionary containing metadata describing all of the supported services.
 * The dictionary is automatically populated from the Singly API.
 *
 */
@property (nonatomic, strong, readonly) NSDictionary *servicesDictionary;

/*!
 *
 * The SinglySession to use for the login requests. The default value of this is
 * the shared singleton instance.
 *
 */
@property (nonatomic, strong) SinglySession *session;

- (id)initWithSession:(SinglySession *)session;

@end
