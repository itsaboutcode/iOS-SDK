//
//  SinglyFriendPickerViewController.m
//  SinglySDK
//
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "SinglySession.h"
#import "SinglyFriendPickerViewController.h"
#import "SinglyAPIRequest.h"
#import "SinglyFriendPickerCell.h"

@interface SinglyFriendPickerViewController ()
{
    NSMutableDictionary* _friends;
    NSArray* _friendsSortedKeys;
    UIView* _loadingView;
    NSMutableArray* _pickedFriends;
    UIColor* originalSepColor;
}

@end

@implementation SinglyFriendPickerViewController

- (id)initWithSession:(SinglySession*)session;
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self)
    {
        _session = session;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.rowHeight = 54;

    [self.session requestAPI:[SinglyAPIRequest apiRequestForEndpoint:@"types/contacts" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"200", @"limit", nil]] withCompletionHandler:^(NSError *error, id json) {
        if (![json isKindOfClass:[NSArray class]]) {
            return;
        }
        // Here we flip through the contacts and see merge them a bit
        NSArray* contacts = (NSArray*)json;
        _friends = [NSMutableDictionary dictionaryWithCapacity:contacts.count];
        NSLog(@"Got %d contacts", contacts.count);
        for (NSDictionary* contact in contacts) {
            NSDictionary* oembed = [contact objectForKey:@"oembed"];
            if (!oembed || ![oembed objectForKey:@"title"]){
                NSLog(@"Skipped for no title or oembed");
                continue;
            }
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
        self.tableView.separatorColor = originalSepColor;
        originalSepColor = nil;
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
        
        originalSepColor = self.tableView.separatorColor;
        self.tableView.separatorColor = [UIColor clearColor];
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

#pragma mark - SinglySession

- (SinglySession *)session
{
    _session = [SinglySession sharedSession];
    return _session;
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
    SinglyFriendPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell = [[SinglyFriendPickerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSDictionary *friendInfo = [[_friends objectForKey:[_friendsSortedKeys objectAtIndex:indexPath.row]] objectAtIndex:0];
    cell.friendInfoDictionary = friendInfo;

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
