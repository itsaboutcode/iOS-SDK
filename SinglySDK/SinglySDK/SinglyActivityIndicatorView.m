//
//  SinglyActivityIndicatorView.m
//  SinglySDK
//
//  Created by Justin Mecham on 10/26/12.
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SinglyActivityIndicatorView.h"

@implementation SinglyActivityIndicatorView

static SinglyActivityIndicatorView *sharedInstance = nil;

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
    self.sharedIndicator.alpha = 0;
    [mainWindow addSubview:self.sharedIndicator];

    [UIView animateWithDuration:0.5 animations:^{
        self.sharedIndicator.alpha = 1;
    }];
}

+ (void)dismissIndicator
{
    [UIView animateWithDuration:0.5 animations:^{
        self.sharedIndicator.alpha = 0;
    } completion:^(BOOL finished) {
        [self.sharedIndicator removeFromSuperview];
    }];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {

        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 5.0;
        self.layer.borderColor = [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.15] CGColor];
        self.layer.borderWidth = 1.0;
        self.clipsToBounds = YES;

        UIImageView *spinner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SinglySDK.bundle/Icon-512"]];
        spinner.contentMode = UIViewContentModeScaleAspectFill;
        spinner.center = self.center;
        spinner.frame = self.bounds;
        CABasicAnimation *fullRotation;
        fullRotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        fullRotation.fromValue = [NSNumber numberWithFloat:0];
        fullRotation.toValue = [NSNumber numberWithFloat:(2 * M_PI)];
        fullRotation.duration = 1.0;
        fullRotation.repeatCount = MAXFLOAT;
        [spinner.layer addAnimation:fullRotation forKey:@"spinner"];
        [self addSubview:spinner];

    }
    return self;
}

@end
