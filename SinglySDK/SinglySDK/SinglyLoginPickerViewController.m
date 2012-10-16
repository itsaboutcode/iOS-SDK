//
//  SinglyLoginPickerViewController.m
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/29/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SinglyLoginPickerViewController.h"
#import "SinglyLoginPickerServiceCell.h"

@interface SinglyLoginPickerViewController ()

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSString *selectedService;

@end

@implementation SinglyLoginPickerViewController

-(id)initWithSession:(SinglySession *)session
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _session = session;
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

//  self.tableView.allowsSelection = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Load Services Dictionary
    // TODO We may want to move this to SinglySession
    if (!self.servicesDictionary)
    {
        
        // Display Activity Indicator
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicator.center = self.view.center;
        [self.activityIndicator startAnimating];
        [self.view addSubview:self.activityIndicator];

        // Load Services Dictionary
        NSURL *servicesURL = [NSURL URLWithString:@"https://api.singly.com/services"];
        NSURLRequest *servicesRequest = [NSURLRequest requestWithURL:servicesURL];
        [NSURLConnection sendAsynchronousRequest:servicesRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError) {
            _servicesDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
            if (!self.services)
                self.services = [self.servicesDictionary allKeys];
            [self.activityIndicator stopAnimating];
            [self.tableView reloadData];
        }];

    }
    else if (self.servicesDictionary && !self.services)
    {
        self.services = [self.servicesDictionary allKeys];
    }

}

#pragma mark - SinglySession

- (SinglySession *)session
{
    if (!_session)
        _session = [SinglySession sharedSession];
    return _session;
}

#pragma mark - Table View

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
    static NSString *CellIdentifier = @"com.singly.SinglyLoginPickerServiceCell";
    SinglyLoginPickerServiceCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell = [[SinglyLoginPickerServiceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    NSString *service = [self.services objectAtIndex:indexPath.row];
    NSDictionary *serviceInfoDictionary = [self.servicesDictionary objectForKey:service];
    cell.serviceInfoDictionary = serviceInfoDictionary;

    if ([self.session.profiles objectForKey:service])
        cell.authenticated = YES;
    else
        cell.authenticated = NO;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *service = [self.services objectAtIndex:indexPath.row];
    self.selectedService = service;

    if (![self.session.profiles objectForKey:service])
    {
        SinglyLoginViewController* loginViewController = [[SinglyLoginViewController alloc] initWithSession:self.session forService:service];
        loginViewController.delegate = self;
        [self presentViewController:loginViewController animated:YES completion:NULL];
    }
    else
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Singly Login View Controller delegate

- (void)singlyLoginViewController:(SinglyLoginViewController *)controller didLoginForService:(NSString *)service;
{
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)singlyLoginViewController:(SinglyLoginViewController *)controller errorLoggingInToService:(NSString *)service withError:(NSError *)error;
{
    [self dismissViewControllerAnimated:FALSE completion:nil];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
