//
//  SYMainViewController.m
//  SinglySDK Example
//
//  Created by Justin Mecham on 10/1/12.
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//

#import "SYMainViewController.h"

@interface SYMainViewController ()

@end

@implementation SYMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    
    // Disable examples unless authenticated...
    if (![SinglySession sharedSession].accessToken)
    {
        self.friendPickerCell.userInteractionEnabled = NO;
        self.friendPickerCell.textLabel.alpha = 0.25;
        self.friendPickerCell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        self.friendPickerCell.userInteractionEnabled = YES;
        self.friendPickerCell.textLabel.alpha = 1.0;
        self.friendPickerCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    [self.tableView reloadData];
    
    [super viewWillAppear:animated];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0 && ![SinglySession sharedSession].accessToken)
    {
        return @"You must authenticate with a service to access the following examples";
    }
    return nil;
}

@end
