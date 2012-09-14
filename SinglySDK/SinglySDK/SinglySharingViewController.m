//
//  SinglySharingViewController.m
//  SinglySDK
//
//  Created by Thomas Muldowney on 9/12/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import "SinglySharingViewController.h"
#import "SinglySharingView.h"
#import <QuartzCore/QuartzCore.h>

@interface SinglySharingViewController () {
    SinglySharingView* sharingView;
}
@end

@implementation SinglySharingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];

    sharingView = [[SinglySharingView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:sharingView];
    [sharingView.cancel addTarget:self action:@selector(cancelButton:) forControlEvents:UIControlEventTouchUpInside];
    
    CATransition* transition = [CATransition animation];
    transition.type = kCATransitionMoveIn;
    transition.subtype = kCATransitionFromBottom;
    transition.duration = 0.4f;
    [sharingView.layer addAnimation:transition forKey:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)cancelButton:(id)sender;
{
    NSLog(@"Here");
    [self.presentingViewController dismissModalViewControllerAnimated:NO];
}
@end
