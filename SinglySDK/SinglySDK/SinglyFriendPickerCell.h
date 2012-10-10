//
//  SinglyFriendPickerCell.h
//  SinglySDK
//
//  Created by Justin Mecham on 10/9/12.
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SinglyFriendPickerCell : UITableViewCell <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSDictionary *friendInfoDictionary;

@end
