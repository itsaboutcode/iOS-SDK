//
//  SinglyFriendPickerViewController.m
//  SinglySDK
//
//  Copyright (c) 2012-2013 Singly, Inc. All rights reserved.
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
#import "SinglyAlertView.h"
#import "SinglyConnection.h"
#import "SinglyFriendPickerCell.h"
#import "SinglyFriendPickerViewController.h"
#import "SinglyFriendPickerViewController+Internal.h"
#import "SinglyFriendPlaceholder.h"
#import "SinglyRequest.h"
#import "SinglySession.h"

@implementation SinglyFriendPickerViewController

- (BOOL)fetchFriends:(NSError **)error
{
    return [self fetchFriendsAtOffset:0 limit:0 error:error];
}

- (void)fetchFriendsWithCompletion:(SinglyFetchFriendsCompletionBlock)completionHandler
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSError *error;
        BOOL isSuccessful = [self fetchFriends:&error];

        if (completionHandler) dispatch_sync(currentQueue, ^{
            completionHandler(isSuccessful, error);
        });

    });
}

- (BOOL)fetchFriendsAtOffset:(NSInteger)offset error:(NSError **)error
{
    return [self fetchFriendsAtOffset:offset limit:0 error:error];
}

- (void)fetchFriendsAtOffset:(NSInteger)offset completion:(SinglyFetchFriendsCompletionBlock)completionHandler
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSError *error;
        BOOL isSuccessful = [self fetchFriendsAtOffset:offset error:&error];

        if (completionHandler) dispatch_sync(currentQueue, ^{
            completionHandler(isSuccessful, error);
        });
        
    });
}

- (BOOL)fetchFriendsAtOffset:(NSInteger)offset limit:(NSInteger)limit error:(NSError **)error
{
    if (self.isRefreshing) return NO;
    _isRefreshing = YES;

    // Offset & Limit
    if (limit <= 0) limit = 50;
    NSString *offsetString = [NSString stringWithFormat:@"%d", offset];
    NSString *limitString = [NSString stringWithFormat:@"%d", limit];

    NSLog(@"[SinglySDK] Fetching friends...");

    // Prepare the Request
    NSDictionary *requestParameters = @{
        @"limit": limitString,
        @"offset": offsetString,
        @"toc": @"true"
    };
    SinglyRequest *request = [SinglyRequest requestWithEndpoint:@"friends/all"
                                                  andParameters:requestParameters];

    // Send the Request
    NSError *fetchError;
    SinglyConnection *connection = [SinglyConnection connectionWithRequest:request];
    id responseObject = [connection performRequest:&fetchError];

    // Check for Errors
    if (fetchError)
    {
        if (error) *error = fetchError;

        _isRefreshing = NO;

        //
        // Display a friendly alert to the user.
        //
        SinglyAlertView *alertView = [[SinglyAlertView alloc] initWithTitle:nil message:[fetchError localizedDescription]];
        [alertView addCancelButtonWithTitle:@"Dismiss"];
        [alertView show];

        return NO;
    }

    // Display a placeholder if no friends were returned
    if (((NSArray *)responseObject).count == 0)
    {
        [SinglyActivityIndicatorView dismissIndicator];
        self.tableView.separatorColor = self.originalSeparatorColor;
        self.originalSeparatorColor = nil;
        return YES;
    }

    // Extract Response Components
    NSMutableDictionary *indexDetails = [NSMutableDictionary dictionaryWithDictionary:responseObject[0]];
    NSDictionary *indexMetadata = indexDetails[@"meta"];
    NSMutableArray *friends = [NSMutableArray arrayWithArray:responseObject];

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

    NSLog(@"[SinglySDK] Found %d friends...", self.friends.count);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [SinglyActivityIndicatorView dismissIndicator];
        self.tableView.separatorColor = self.originalSeparatorColor;
        self.originalSeparatorColor = nil;
    });

    _isRefreshing = NO;

    return YES;
}

- (void)fetchFriendsAtOffset:(NSInteger)offset limit:(NSInteger)limit completion:(SinglyFetchFriendsCompletionBlock)completionHandler
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSError *error;
        BOOL isSuccessful = [self fetchFriendsAtOffset:offset limit:limit error:&error];

        if (completionHandler) dispatch_sync(currentQueue, ^{
            completionHandler(isSuccessful, error);
        });
        
    });
}

#pragma mark - View Callbacks

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Customize Table View Appearance
    self.tableView.rowHeight = 54;

    [self fetchFriendsWithCompletion:nil];
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
        int offset = [indexesToLoad[0] intValue] - 10;
        int limit  = [[indexesToLoad lastObject] intValue] - [indexesToLoad[0] intValue] * 2;
        [self fetchFriendsAtOffset:offset limit:limit error:nil];
    }

}

@end
