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
#import "SinglyFriendPickerViewController+Internal.h"
#import "SinglyFriendPlaceholder.h"
#import "SinglyRequest.h"
#import "SinglySession.h"

@implementation SinglyFriendPickerViewController

- (void)fetchFriends
{
    [self fetchFriendsAtOffset:0 withLimit:0];
}

- (void)fetchFriendsAtOffset:(NSInteger)offset
{
    [self fetchFriendsAtOffset:offset withLimit:0];
}

- (void)fetchFriendsAtOffset:(NSInteger)offset withLimit:(NSInteger)limit
{
    if (self.isRefreshing) return;
    _isRefreshing = YES;

    // Offset & Limit
    if (limit <= 0) limit = 50;
    NSString *offsetString = [NSString stringWithFormat:@"%d", offset];
    NSString *limitString = [NSString stringWithFormat:@"%d", limit];

    NSLog(@"[SinglySDK] Fetching friends...");

    // Configure the Request
    NSDictionary *requestParameters = @{
        @"limit": limitString,
        @"offset": offsetString,
        @"toc": @"true"
    };
    SinglyRequest *request = [SinglyRequest requestWithEndpoint:@"friends/all"
                                                  andParameters:requestParameters];

    // Send the Request to the Singly API
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError)
    {
        NSError *parseError;

        // Check for Request Errors
        if (requestError)
        {
            NSLog(@"[SinglySDK:SinglySession] A request error occurred while attempting to load friends: %@", requestError);
            _isRefreshing = NO;

            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:[requestError localizedDescription]
                                                               delegate:self
                                                      cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
            [alertView show];
            return;
        }

        // Parse the Response
        id responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];
        if (parseError)
        {
            NSLog(@"[SinglySDK:SinglySession] An error occurred while attempting to parse friends: %@", parseError);
            _isRefreshing = NO;
            return;
        }

        // We are expecting an array, so if we receive a dictionary it is
        // likely because of an error...
        else if ([responseObject isKindOfClass:[NSDictionary class]] && responseObject[@"error"])
        {
            NSLog(@"[SinglySDK:SinglySession] An error occurred while attempting to request friends: %@", responseObject[@"error"]);
            _isRefreshing = NO;
            return;
        }

        // Extract Response Components
        NSMutableDictionary *indexDetails = [NSMutableDictionary dictionaryWithDictionary:responseObject[0]];
        NSDictionary *indexMetadata = indexDetails[@"meta"];
        NSMutableArray *friends = [NSMutableArray arrayWithArray:responseObject];

        NSLog(@"Index Meta: %@", indexMetadata);
        
        // Remove Metadata from Keys
        [indexDetails removeObjectForKey:@"meta"];

        // Remove Metadata from Friends
        [friends removeObjectAtIndex:0];

        // TODO Compare returned metadata from friends array size and reset if
        //      necessary

        // Prepare Index Keys

        if (!_friends)
        {
            int friendsCount = [indexMetadata[@"length"] intValue];
            _friends = [NSMutableArray arrayWithCapacity:friendsCount];
            for (int i = 0; i < friendsCount; i++)
            {
                SinglyFriendPlaceholder *placeholder = [[SinglyFriendPlaceholder alloc] init];
                placeholder.isLoading = NO;
                [_friends insertObject:placeholder atIndex:i];
            }
        }

        [_friends replaceObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(offset, friends.count)] withObjects:friends];
        _indexDetails = indexDetails;
        _indexKeys = [[indexDetails allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
        {
            return [indexDetails[obj1][@"offset"] intValue] > [indexDetails[obj2][@"offset"] intValue];
        }];

        NSLog(@"Index Details: %@", indexDetails);
        NSLog(@"Index Keys: %@", self.indexKeys);
        NSLog(@"Friends: %@", responseObject);

        NSLog(@"[SinglySDK] Loaded %d friends ...", self.friends.count);

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [SinglyActivityIndicatorView dismissIndicator];
            self.tableView.separatorColor = self.originalSeparatorColor;
            self.originalSeparatorColor = nil;
        });

        _isRefreshing = NO;
    }];
}

#pragma mark - View Callbacks

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.rowHeight = 54;
    self.tableView.delegate = self;

    [self fetchFriends];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.friends.count == 0 || self.isRefreshing)
    {
        [SinglyActivityIndicatorView showIndicator];

        self.originalSeparatorColor = self.tableView.separatorColor;
        self.tableView.separatorColor = [UIColor clearColor];
    }
    else
    {
//        [self refreshFriends];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [SinglyActivityIndicatorView dismissIndicator];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.indexKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *sectionInfo = self.indexDetails[self.indexKeys[section]];
    return [sectionInfo[@"length"] intValue];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *sectionInfo = self.indexDetails[self.indexKeys[section]];
    if ([sectionInfo[@"length"] intValue] > 0)
        return [self.indexKeys[section] uppercaseString];
    return nil;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *titles = [self.indexKeys mutableCopy];

    // Capitalize the Titles
    for (int i = 0; i < titles.count; i++)
        [titles replaceObjectAtIndex:i withObject:[titles[i] uppercaseString]];

    return titles;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"com.singly.SinglyFriendPickerCell";
    SinglyFriendPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell = [[SinglyFriendPickerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    NSString *indexKey = self.indexKeys[indexPath.section];
    NSDictionary *sectionInfo = self.indexDetails[indexKey];
    int friendIndex = indexPath.row + [sectionInfo[@"offset"] intValue];

    if (friendIndex < self.friends.count)
    {
        id friendInfo = self.friends[friendIndex];
        if (![friendInfo isKindOfClass:[SinglyFriendPlaceholder class]])
            cell.friendInfoDictionary = friendInfo;
        else
            cell.friendInfoDictionary = nil;
    }

    return cell;
}

#pragma mark - Table View Delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    NSString *idr = [[[self.friends objectForKey:[self.friendsSortedKeys objectAtIndex:indexPath.row]] objectAtIndex:0] objectForKey:@"idr"];
//    idr = [idr substringFromIndex:[idr rangeOfString:@"#" options:NSBackwardsSearch].location + 1];
//    NSLog(@"[SinglySDK:SinglyFriendPickerViewController] Selected IDR: %@", idr);
}

#pragma mark - Scroll View Delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    int visibleFriendIndex;
    NSDictionary *sectionInfo;
    id friend;
    NSArray *visibleIndexPaths = self.tableView.indexPathsForVisibleRows;
    NSMutableArray *indexesToLoad = [NSMutableArray array];

    for (NSIndexPath *indexPath in visibleIndexPaths)
    {
        sectionInfo = self.indexDetails[self.indexKeys[indexPath.section]];
        visibleFriendIndex = [sectionInfo[@"offset"] intValue] + indexPath.row;
        friend = self.friends[visibleFriendIndex];

        if ([friend isKindOfClass:[SinglyFriendPlaceholder class]])
        {
            if (!((SinglyFriendPlaceholder *)friend).isLoading)
            {
                ((SinglyFriendPlaceholder *)friend).isLoading = YES;
                [indexesToLoad addObject:[NSNumber numberWithInt:visibleFriendIndex]];
            }
        }
    }

    if (indexesToLoad.count > 0)
    {
        [self fetchFriendsAtOffset:[indexesToLoad[0] intValue] - 10 withLimit:[[indexesToLoad lastObject] intValue] - [indexesToLoad[0] intValue] * 2];
    }

}

@end
