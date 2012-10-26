//
//  SinglyFriendPickerCell.m
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
    
    self.imageView.frame = CGRectMake((self.frame.size.height - 42) / 2, (self.frame.size.height - 42) / 2, 42, 42);
    self.textLabel.frame = CGRectMake(46 + (self.frame.size.height - 42), 0, self.textLabel.frame.size.width - 48, self.textLabel.frame.size.height);
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
