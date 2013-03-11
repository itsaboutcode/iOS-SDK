//
//  SinglyActivityIndicatorView.m
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

static SinglyActivityIndicatorView *sharedInstance = nil;

@implementation SinglyActivityIndicatorView

+ (SinglyActivityIndicatorView *)sharedIndicator
{
    if (sharedInstance == nil)
    {
        UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
        sharedInstance = [[SinglyActivityIndicatorView alloc] initWithFrame:CGRectMake(mainWindow.center.x - 48, mainWindow.center.y - 48, 96, 96)];
    }
    return sharedInstance;
}

+ (void)showIndicator
{
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    [self.sharedIndicator.activityIndicatorView startAnimating];
    self.sharedIndicator.alpha = 0;
    [mainWindow addSubview:self.sharedIndicator];

    [UIView animateWithDuration:0.5 animations:^{
        self.sharedIndicator.alpha = 1;
    }];
}

+ (void)dismissIndicator
{
    [UIView animateWithDuration:0.35 animations:^{
         self.sharedIndicator.alpha = 0;
    } completion:^(BOOL finished) {
        [self.sharedIndicator.activityIndicatorView stopAnimating];
        [self.sharedIndicator removeFromSuperview];
    }];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {

        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        self.layer.cornerRadius = 5.0;
//        self.layer.borderColor = [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.15] CGColor];
//        self.layer.borderWidth = 1.0;
        self.clipsToBounds = YES;

        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityIndicatorView.center = self.center;
        self.activityIndicatorView.frame = self.bounds;
        self.activityIndicatorView.color = [UIColor whiteColor];
        [self addSubview:self.activityIndicatorView];

//        UIImageView *spinner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SinglySDK.bundle/Icon-512"]];
//        spinner.contentMode = UIViewContentModeScaleAspectFill;
//        spinner.center = self.center;
//        spinner.frame = self.bounds;
//        CABasicAnimation *fullRotation;
//        fullRotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
//        fullRotation.fromValue = [NSNumber numberWithFloat:0];
//        fullRotation.toValue = [NSNumber numberWithFloat:(2 * M_PI)];
//        fullRotation.duration = 1.0;
//        fullRotation.repeatCount = MAXFLOAT;
//        [spinner.layer addAnimation:fullRotation forKey:@"spinner"];

    }
    return self;
}

@end
