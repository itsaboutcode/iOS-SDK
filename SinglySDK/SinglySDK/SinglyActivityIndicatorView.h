//
//  SinglyActivityIndicatorView.h
//  SinglySDK
//
//  Created by Justin Mecham on 10/26/12.
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SinglyActivityIndicatorView : UIView

+ (SinglyActivityIndicatorView *)sharedIndicator;

+ (void)showIndicator;

+ (void)dismissIndicator;

@end
