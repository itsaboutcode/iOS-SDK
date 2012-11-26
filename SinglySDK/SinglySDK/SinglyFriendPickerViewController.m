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

#import "SinglyActivityIndicatorView.h"
#import "SinglyFriendPickerCell.h"
#import "SinglyFriendPickerViewController.h"
#import "SinglyRequest.h"
#import "SinglySession.h"

@interface SinglyFriendPickerViewController ()
{
    NSMutableDictionary* _friends;
    NSArray* _friendsSortedKeys;
    NSMutableArray* _pickedFriends;
    UIColor* originalSepColor;
}

@property (nonatomic, assign) BOOL isRefreshing;

@end

@implementation SinglyFriendPickerViewController

- (id)initWithSession:(SinglySession*)session
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

    [self refreshFriends];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_friendsSortedKeys.count == 0 || self.isRefreshing)
    {
        [SinglyActivityIndicatorView showIndicator];

//        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(4, 220, _loadingView.bounds.size.width - 8, 22)];
//        label.text = @"Loading...";
//        label.backgroundColor = [UIColor clearColor];
//        label.textAlignment = UITextAlignmentCenter;
//        label.textColor = [UIColor whiteColor];
//        [_loadingView addSubview:label];

        originalSepColor = self.tableView.separatorColor;
        self.tableView.separatorColor = [UIColor clearColor];
    }
    else
    {
        [self refreshFriends];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [SinglyActivityIndicatorView dismissIndicator];
}

#pragma mark -

- (void)refreshFriends
{

    if (self.isRefreshing)
        return;

    self.isRefreshing = YES;
    NSLog(@"[SinglySDK] Refreshing friends...");

    SinglyRequest *request = [SinglyRequest requestWithEndpoint:@"types/contacts" andParameters:@{ @"limit": @"200" }];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError)
    {
        // TODO If not a json array, set isRefreshing = NO and return...

        NSArray *friends = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
        _friends = [NSMutableDictionary dictionaryWithCapacity:friends.count];

        NSLog(@"[SinglySDK] Loaded %d friends", friends.count);

        for (NSDictionary *friend in friends)
        {
            NSDictionary *oEmbed = [friend objectForKey:@"oembed"];

            if (!oEmbed || ![oEmbed objectForKey:@"title"])
            {
                NSLog(@"Skipped for no title or oembed");
                continue;
            }

            NSMutableArray *profiles = [_friends objectForKey:[oEmbed objectForKey:@"title"]];
            if (!profiles)
            {
                profiles = [NSMutableArray array];
                [_friends setObject:profiles forKey:[oEmbed objectForKey:@"title"]];
            }
            [profiles addObject:friend];

        }

        dispatch_async(dispatch_get_main_queue(), ^{
            _friendsSortedKeys = [[_friends allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            [self.tableView reloadData];
            [SinglyActivityIndicatorView dismissIndicator];
            self.tableView.separatorColor = originalSepColor;
            originalSepColor = nil;
        });

        self.isRefreshing = NO;
    }];
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    */
    NSString *idr = [[[_friends objectForKey:[_friendsSortedKeys objectAtIndex:indexPath.row]] objectAtIndex:0] objectForKey:@"idr"];
    idr = [idr substringFromIndex:[idr rangeOfString:@"#" options:NSBackwardsSearch].location + 1];
    self.pickedFriends = [NSArray arrayWithObject:idr];
}

@end
