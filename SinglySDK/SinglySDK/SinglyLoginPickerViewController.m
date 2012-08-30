//
//  SinglyLoginPickerViewController.m
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/29/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import "SinglyLoginPickerViewController.h"
#import <SinglySDK/SinglyLogInViewController.h>
#import <QuartzCore/QuartzCore.h>

@interface SinglyLoginPickerViewController () {
    SinglySession* session_;
}
@end

@implementation SinglyLoginPickerViewController

-(id)initWithSession:(SinglySession *)session;
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        session_ = session;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.services == nil) {
        // TODO:  Dynamically load this
        self.services = [NSArray arrayWithObjects:@"facebook", @"twitter", @"instagram", @"github", @"foursquare", nil];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.services.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"com.singly.serviceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 6, 32, 32)];
        imageView.tag = 1;
        [cell addSubview:imageView];
        
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(44, 5, self.view.bounds.size.width - 40 - 60 - 8, 32)];
        label.textAlignment = UITextAlignmentLeft;
        label.tag = 2;
        [cell addSubview:label];
        
        UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(self.view.bounds.size.width - 8 - 80, 10, 80, 28);
        button.tag = 3;
        [cell addSubview:button];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSString* service = [self.services objectAtIndex:indexPath.row];
    
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:1];
    imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://singly.com/images/service_icons/%@.png", service]]]];
    
    UILabel* label = (UILabel*)[cell viewWithTag:2];
    label.text = service;
    
    UIButton* button = (UIButton*)[cell.subviews objectAtIndex:3];
    button.tag = indexPath.row;
    if ([session_.profiles objectForKey:service]) {
        [self disableColorButton:button];
        [button setTitle:@"Logged In" forState:UIControlStateNormal];
        button.enabled = NO;
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [self enableColorButton:button];
        [button addTarget:self action:@selector(loginTouchDown:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(loginTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"Log In" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }

    [button.titleLabel setShadowColor:[UIColor darkGrayColor]];
    [button.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    [button bringSubviewToFront:button.titleLabel];
    
    return cell;
}

-(void)loginTouchDown:(id)sender;
{
    UIButton* button = (UIButton*)sender;
    CALayer *layer = button.layer;
    CALayer* newLayer = [CALayer layer];
    newLayer.frame = layer.bounds;
    newLayer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.15].CGColor;
    [layer insertSublayer:newLayer atIndex:1];
}

-(void)loginTouchUp:(id)sender;
{
    UIButton* button = (UIButton*)sender;
    [[button.layer.sublayers objectAtIndex:1] removeFromSuperlayer];
    
    NSLog(@"Login to service %@", [self.services objectAtIndex:button.tag]);
    SinglyLogInViewController* loginViewController = [[SinglyLogInViewController alloc] initWithSession:session_ forService:[self.services objectAtIndex:button.tag]];
    loginViewController.delegate = self;
    [self presentViewController:loginViewController animated:YES completion:NULL];
}

-(void)enableColorButton:(UIButton*)button;
{
    // Add Border
    CALayer *layer = button.layer;
    layer.cornerRadius = 8.0f;
    layer.masksToBounds = YES;
    layer.borderWidth = 1.0f;
    layer.borderColor = [UIColor colorWithWhite:0.5f alpha:0.2f].CGColor;
    layer.shadowColor = [UIColor darkGrayColor].CGColor;
    layer.shadowOffset = CGSizeMake(0, -1);
    
    // Add Shine
    CAGradientLayer *shineLayer = [CAGradientLayer layer];
    shineLayer.frame = layer.bounds;
    shineLayer.colors = [NSArray arrayWithObjects:
                         (id)[UIColor colorWithRed:0.537 green:0.604 blue:0.690 alpha:1.0].CGColor,
                         (id)[UIColor colorWithRed:0.318 green:0.443 blue:0.592 alpha:1.0].CGColor,
                         (id)[UIColor colorWithRed:0.227 green:0.361 blue:0.529 alpha:1.0].CGColor,
                         (id)[UIColor colorWithRed:0.235 green:0.369 blue:0.533 alpha:1.0].CGColor,
                         nil];
    shineLayer.locations = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.0f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:1.0f],
                            nil];
    [layer addSublayer:shineLayer];
}

-(void)disableColorButton:(UIButton*)button
{
    // Add Border
    CALayer *layer = button.layer;
    layer.cornerRadius = 8.0f;
    layer.masksToBounds = YES;
    layer.borderWidth = 1.0f;
    layer.borderColor = [UIColor colorWithWhite:0.0f alpha:0.2f].CGColor;
    layer.shadowColor = [UIColor darkGrayColor].CGColor;
    layer.shadowOffset = CGSizeMake(0, -1);
    
    // Add Shine
    CAGradientLayer *shineLayer = [CAGradientLayer layer];
    shineLayer.frame = layer.bounds;
    shineLayer.colors = [NSArray arrayWithObjects:
                         (id)[UIColor colorWithRed:0.882 green:0.882 blue:0.882 alpha:1.0].CGColor,
                         (id)[UIColor colorWithRed:0.882 green:0.882 blue:0.882 alpha:1.0].CGColor,
                         (id)[UIColor colorWithRed:0.741 green:0.741 blue:0.741 alpha:1.0].CGColor,
                         (id)[UIColor colorWithRed:0.741 green:0.741 blue:0.741 alpha:1.0].CGColor,
                         nil];
    shineLayer.locations = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.0f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:0.5f],
                            [NSNumber numberWithFloat:1.0f],
                            nil];
    [layer addSublayer:shineLayer];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO:  Should this count as hitting log in?
}

#pragma mark - Singly Login View Controller delegate
-(void)singlyLogInViewController:(SinglyLogInViewController *)controller didLoginForService:(NSString *)service;
{
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)singlyLogInViewController:(SinglyLogInViewController *)controller errorLoggingInToService:(NSString *)service withError:(NSError *)error;
{
    [self dismissViewControllerAnimated:FALSE completion:nil];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}
@end
