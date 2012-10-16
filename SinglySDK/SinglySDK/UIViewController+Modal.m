//
//  UIViewController+Modal.m
//  SinglySDK
//
//  Created by Justin Mecham on 10/16/12.
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//

#import "UIViewController+Modal.h"

@implementation UIViewController (Modal)

- (BOOL)isModal
{
  BOOL isModal = ((self.presentingViewController && self.presentingViewController.modalViewController == self) \
                  || (self.navigationController && self.navigationController.presentingViewController && self.navigationController.presentingViewController.modalViewController == self.navigationController) \
                  || [[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]]);

  return isModal;
}

@end
