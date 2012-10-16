//
//  SinglyLoginPickerServiceCell.h
//  SinglySDK
//
//  Created by Justin Mecham on 10/16/12.
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SinglyLoginPickerServiceCell : UITableViewCell <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSDictionary *serviceInfoDictionary;
@property (nonatomic, assign) BOOL authenticated;

@end
