//
//  SinglySharingView.m
//  SinglySDK
//
//  Created by Thomas Muldowney on 9/12/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import "SinglySharingView.h"
#import <QuartzCore/QuartzCore.h>

@implementation SinglySharingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(4, 4, frame.size.width - 8, frame.size.height / 2.2)];
    if (self) {
        self.layer.cornerRadius = 16.0;
        self.backgroundColor = [UIColor whiteColor];
        //self.layer.masksToBounds = YES;
        
        // TODO:  make it purty
        _cancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _cancel.frame = CGRectMake(12, 12, 64, 26);
        [_cancel setTitle:@"Cancel" forState:UIControlStateNormal];
        [self addSubview:_cancel];
        
        _send = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _send.frame = CGRectMake(250, 12, 52, 26);
        [_send setTitle:@"Send" forState:UIControlStateNormal];
        [self addSubview:_send];
        
        UITextView* field = [[UITextView alloc] initWithFrame:CGRectMake(1, 48, self.bounds.size.width - 2, self.bounds.size.height - 48)];
        field.backgroundColor = [UIColor clearColor];
        field.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        field.layer.cornerRadius = 16.0;
        [self addSubview:field];
        
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.layer.borderWidth = 1.5;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowRadius = 3.0;
        self.layer.shadowOpacity = 0.8;
        self.layer.shadowOffset = CGSizeMake(2, 2);
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
