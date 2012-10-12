//
//  SinglyFriendPickerCell.m
//  SinglySDK
//
//  Created by Justin Mecham on 10/9/12.
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SinglyFriendPickerCell.h"

@interface SinglyFriendPickerCell ()

@property (nonatomic, strong) NSURLConnection *imageConnection;
@property (nonatomic, strong) NSMutableData *receivedData;

@end

@implementation SinglyFriendPickerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.imageView.image = [UIImage imageNamed:@"SinglySDK.bundle/Avatar Placeholder"];
        self.imageView.layer.cornerRadius = 3.0;
        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(4, 4, 35, 35);
    self.textLabel.frame = CGRectMake(47, 0, self.textLabel.frame.size.width - 48, self.textLabel.frame.size.height);
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    [self.imageConnection cancel];
    self.imageView.image = [UIImage imageNamed:@"SinglySDK.bundle/Avatar Placeholder"];
}

- (void)setFriendInfoDictionary:(NSDictionary *)friendInfoDictionary
{
    _friendInfoDictionary = friendInfoDictionary;

    // Set Text Label
    self.textLabel.text = friendInfoDictionary[@"oembed"][@"title"];

    // Load Image
    NSURL *imageURL = [NSURL URLWithString:friendInfoDictionary[@"oembed"][@"thumbnail_url"]];
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:imageURL];
    self.receivedData = [NSMutableData data];
    self.imageConnection = [[NSURLConnection alloc] initWithRequest:imageRequest delegate:self startImmediately:NO];
    [self.imageConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.imageConnection start];
}

#pragma mark - URL Connection Delegates

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.receivedData.length = 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.imageView.image = [UIImage imageWithData:self.receivedData];
    self.imageConnection = nil;
    self.receivedData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    self.imageConnection = nil;
    self.receivedData = nil;
}

@end
