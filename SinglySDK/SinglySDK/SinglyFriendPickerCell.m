//
//  SinglyFriendPickerCell.m
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

#import "SinglyCache.h"
#import "SinglyFriendPickerCell.h"
#import "SinglyFriendPickerCell+Internal.h"

@implementation SinglyFriendPickerCell

@synthesize friendInfoDictionary = _friendInfoDictionary;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.imageView.image = [UIImage imageNamed:@"SinglySDK.bundle/Avatar Placeholder"];
        self.imageView.layer.cornerRadius = 3.0;
        self.imageView.layer.shouldRasterize = YES;
        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.textLabel.font = [UIFont systemFontOfSize:16];
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

    // Cancel Image Downloads
    if (self.imageConnection)
        [self.imageConnection cancel];

    // Clear the Friend Info Dictionary
    _friendInfoDictionary = nil;

    // Clear the Image and Text Views
    self.textLabel.text = @"";
    self.imageView.image = [UIImage imageNamed:@"SinglySDK.bundle/Avatar Placeholder"];
}

- (void)setFriendInfoDictionary:(NSDictionary *)friendInfoDictionary
{
    @synchronized(self)
    {
        if ([_friendInfoDictionary isEqualToDictionary:friendInfoDictionary])
            return;

        _friendInfoDictionary = [friendInfoDictionary copy];

        // Set Text Label
        self.textLabel.text = friendInfoDictionary[@"name"];

        // Load Image
        NSString *imageLocation = friendInfoDictionary[@"thumbnail_url"];
        if (imageLocation)
        {

            // Check cache...
            if ([SinglyCache.sharedCache cachedImageExistsForURL:imageLocation])
            {
                self.imageView.image = (UIImage *)[SinglyCache.sharedCache cachedImageForURL:imageLocation];
            }
            else
            {
                NSURL *imageURL = [NSURL URLWithString:imageLocation];
                NSURLRequest *imageRequest = [NSURLRequest requestWithURL:imageURL];
                self.receivedData = [NSMutableData data];
                self.imageConnection = [[NSURLConnection alloc] initWithRequest:imageRequest delegate:self startImmediately:NO];
                [self.imageConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
                [self.imageConnection start];
            }
        }
    }
}

- (NSDictionary *)friendInfoDictionary
{
    @synchronized(self)
    {
        return _friendInfoDictionary;
    }
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
    NSString *imageLocation = [[connection.originalRequest URL] absoluteString];
    UIImage *receivedImage = [UIImage imageWithData:self.receivedData];
    if (receivedImage)
    {
        self.imageView.image = receivedImage;
        [SinglyCache.sharedCache cacheImage:receivedImage forURL:imageLocation];
    }
    self.imageConnection = nil;
    self.receivedData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"[SinglySDK:SinglyFriendPickerCell] Connection Error: %@ (%@)", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    self.imageConnection = nil;
    self.receivedData = nil;
}

@end
