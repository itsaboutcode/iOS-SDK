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
#import "SinglyRequest.h"
#import "SinglySession.h"

@implementation SinglyFriendPickerViewController

- (void)refreshFriends
{

    if (self.isRefreshing)
        return;

    self.isRefreshing = YES;
    NSLog(@"[SinglySDK] Refreshing friends...");

    SinglyRequest *request = [SinglyRequest requestWithEndpoint:@"types/contacts" andParameters:@{ @"limit": @"200" }];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError)
     {

         NSError *parseError;

         // Check for Request Errors
         if (requestError)
         {
             NSLog(@"[SinglySDK:SinglySession] A request error occurred while attempting to load friends: %@", requestError);
             self.isRefreshing = NO;
             return;
         }

         // Parse the Response
         id parsedFriends = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];
         if (parseError)
         {
             NSLog(@"[SinglySDK:SinglySession] An error occurred while attempting to parse friends: %@", parseError);
             self.isRefreshing = NO;
             return;
         }

         // We are expecting an array, so if we receive a dictionary it is
         // likely because of an error...
         else if ([parsedFriends isKindOfClass:[NSDictionary class]] && parsedFriends[@"error"])
         {
             NSLog(@"[SinglySDK:SinglySession] An error occurred while attempting to request friends: %@", parsedFriends[@"error"]);
             self.isRefreshing = NO;
             return;
         }

         NSLog(@"[SinglySDK] Loaded %d friends", ((NSArray *)parsedFriends).count);

         self.friends = [NSMutableDictionary dictionary];
         for (NSDictionary *friend in parsedFriends)
         {
             NSDictionary *oEmbed = [friend objectForKey:@"oembed"];

             if (!oEmbed || ![oEmbed objectForKey:@"title"])
                 continue;

             NSMutableArray *profiles = [self.friends objectForKey:[oEmbed objectForKey:@"title"]];
             if (!profiles)
             {
                 profiles = [NSMutableArray array];
                 [self.friends setObject:profiles forKey:[oEmbed objectForKey:@"title"]];
             }
             [profiles addObject:friend];

         }

         dispatch_async(dispatch_get_main_queue(), ^{
             self.friendsSortedKeys = [[self.friends allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
             [self.tableView reloadData];
             [SinglyActivityIndicatorView dismissIndicator];
             self.tableView.separatorColor = self.originalSeparatorColor;
             self.originalSeparatorColor = nil;
         });
         
         self.isRefreshing = NO;
     }];
}

#pragma mark - View Callbacks

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.rowHeight = 54;

    [self refreshFriends];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.friendsSortedKeys.count == 0 || self.isRefreshing)
    {
        [SinglyActivityIndicatorView showIndicator];

        self.originalSeparatorColor = self.tableView.separatorColor;
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

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.friendsSortedKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"com.singly.SinglyFriendPickerCell";
    SinglyFriendPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell = [[SinglyFriendPickerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSDictionary *friendInfo = [[self.friends objectForKey:[self.friendsSortedKeys objectAtIndex:indexPath.row]] objectAtIndex:0];
    cell.friendInfoDictionary = friendInfo;

    return cell;
}

#pragma mark - Table View Delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *idr = [[[self.friends objectForKey:[self.friendsSortedKeys objectAtIndex:indexPath.row]] objectAtIndex:0] objectForKey:@"idr"];
    idr = [idr substringFromIndex:[idr rangeOfString:@"#" options:NSBackwardsSearch].location + 1];
    NSLog(@"[SinglySDK:SinglyFriendPickerViewController] Selected IDR: %@", idr);
}

@end
