//
//  SinglyAlertView.m
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

#import "SinglyAlertView.h"

@implementation SinglyAlertView
{
	id <UIAlertViewDelegate> externalDelegate;

	NSMutableDictionary *actionsPerIndex;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
    self = [super initWithTitle:title
                        message:message
                       delegate:(id)self
              cancelButtonTitle:nil
              otherButtonTitles:nil];

    actionsPerIndex = [[NSMutableDictionary alloc] init];
    
	return self;
}

- (NSInteger)addButtonWithTitle:(NSString *)title block:(SinglyAlertViewBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title];

	if (block)
	{
		NSNumber *key = [NSNumber numberWithInt:retIndex];
		[actionsPerIndex setObject:[block copy] forKey:key];
	}

	return retIndex;
}

- (NSInteger)addCancelButtonWithTitle:(NSString *)title
{
	NSInteger retIndex = [self addButtonWithTitle:title];
	self.cancelButtonIndex = retIndex;

	return retIndex;
}

#pragma mark -

- (id <UIAlertViewDelegate>)delegate
{
	return externalDelegate;
}

- (void)setDelegate:(id <UIAlertViewDelegate>)delegate
{
	if (delegate == (id)self)
	{
		super.delegate = (id)self;
	}
	else if (delegate == nil)
	{
		super.delegate = nil;
		externalDelegate = nil;
	}
	else
	{
		externalDelegate = delegate;
	}
}

#pragma mark - Alert View Delegates

- (void)alertViewCancel:(UIAlertView *)alertView
{
	[externalDelegate alertViewCancel:alertView];
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    [externalDelegate willPresentAlertView:alertView];
}

- (void)didPresentAlertView:(UIAlertView *)alertView
{
    [externalDelegate didPresentAlertView:alertView];
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    return [externalDelegate alertViewShouldEnableFirstOtherButton:alertView];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [externalDelegate alertView:alertView clickedButtonAtIndex:buttonIndex];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [externalDelegate alertView:alertView willDismissWithButtonIndex:buttonIndex];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	NSNumber *key = [NSNumber numberWithInt:buttonIndex];

	SinglyAlertViewBlock block = [actionsPerIndex objectForKey:key];
	if (block) block();

	[externalDelegate alertView:alertView didDismissWithButtonIndex:buttonIndex];
}

@end
