//
//  SinglyFriendPickerViewController.m
//  SinglySDK
//
//  Created by Thomas Muldowney on 8/30/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import "SinglyFriendPickerViewController.h"
#import <SinglySDK/SinglyAPIRequest.h>

@interface SinglyFriendPickerViewController () {
    SinglySession* _session;
    NSMutableDictionary* _friends;
    NSArray* _friendsSortedKeys;
    UIView* _loadingView;
    NSMutableArray* _pickedFriends;
}

@end

@implementation SinglyFriendPickerViewController

-(id)initWithSession:(SinglySession*)session;
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
    
    [_session requestAPI:[SinglyAPIRequest apiRequestForEndpoint:@"types/contacts" withParameters:[NSDictionary dictionaryWithObject:@"true" forKey:@"map"]] withCompletionHandler:^(NSError *error, id json) {
        if (![json isKindOfClass:[NSArray class]]) {
            return;
        }
        // Here we flip through the contacts and see merge them a bit
        NSArray* contacts = (NSArray*)json;
        _friends = [NSMutableDictionary dictionaryWithCapacity:contacts.count];
        for (NSDictionary* contact in contacts) {
            NSDictionary* map = [contact objectForKey:@"map"];
            if (!map) continue;
            NSDictionary* oembed = [map objectForKey:@"oembed"];
            if (!oembed || ![oembed objectForKey:@"title"]) continue;
            NSMutableArray* profiles = [_friends objectForKey:[oembed objectForKey:@"title"]];
            if (!profiles) {
                profiles = [NSMutableArray array];
                [_friends setObject:profiles forKey:[oembed objectForKey:@"title"]];
            }
            [profiles addObject:contact];
        }
        _friendsSortedKeys = [[_friends allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [self.tableView reloadData];
        [_loadingView removeFromSuperview];
    }];
}

-(void)viewWillAppear:(BOOL)animated
{
    if (_friendsSortedKeys.count == 0) {
        _loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
        _loadingView.backgroundColor = [UIColor blackColor];
        UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.frame  = CGRectMake(140, 180, activityView.bounds.size.width, activityView.bounds.size.height);
        [activityView startAnimating];
        [_loadingView addSubview:activityView];
        
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(4, 220, _loadingView.bounds.size.width - 8, 22)];
        label.text = @"Loading...";
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        [_loadingView addSubview:label];
        
        [self.view addSubview:_loadingView];
        [self.view bringSubviewToFront:_loadingView];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _friendsSortedKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"com.singly.SinglyFriendPickerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        UILabel* lbl = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, cell.bounds.size.width - 16, cell.bounds.size.height)];
        [cell addSubview:lbl];
    }
    
    UILabel* lbl = [[cell subviews] objectAtIndex:1];
    lbl.text = [_friendsSortedKeys objectAtIndex:indexPath.row];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    */
    NSString* idr = [[[_friends objectForKey:[_friendsSortedKeys objectAtIndex:indexPath.row]] objectAtIndex:0] objectForKey:@"idr"];
    idr = [idr substringFromIndex:[idr rangeOfString:@"#" options:NSBackwardsSearch].location + 1];
    self.pickedFriends = [NSArray arrayWithObject:idr];
}

@end
