//
//  SinglyActionSheet.m
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

#import "SinglyActionSheet.h"

@implementation SinglyActionSheet
{
	id <UIActionSheetDelegate> externalDelegate;

	NSMutableDictionary *actionsPerIndex;
}

- (id)initWithTitle:(NSString *)title
{
	self = [super initWithTitle:title
                       delegate:(id)self
              cancelButtonTitle:nil
         destructiveButtonTitle:nil
              otherButtonTitles:nil];

	if (self)
	{
		actionsPerIndex = [[NSMutableDictionary alloc] init];
	}

	return self;
}

- (NSInteger)addButtonWithTitle:(NSString *)title block:(SinglyActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title];

	if (block)
	{
		NSNumber *key = [NSNumber numberWithInt:retIndex];
		[actionsPerIndex setObject:[block copy] forKey:key];
	}

	return retIndex;
}

- (NSInteger)addDestructiveButtonWithTitle:(NSString *)title block:(SinglyActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title block:block];
	[self setDestructiveButtonIndex:retIndex];

	return retIndex;
}

- (NSInteger)addCancelButtonWithTitle:(NSString *)title
{
	NSInteger retIndex = [self addButtonWithTitle:title];
	[self setCancelButtonIndex:retIndex];

	return retIndex;
}

#pragma mark -

- (id <UIActionSheetDelegate>)delegate
{
	return externalDelegate;
}

- (void)setDelegate:(id <UIActionSheetDelegate>)delegate
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

#pragma mark - Action Sheet Delegates

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
    if (externalDelegate && [externalDelegate respondsToSelector:@selector(actionSheetCancel:)])
        [externalDelegate actionSheetCancel:actionSheet];
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    if (externalDelegate && [externalDelegate respondsToSelector:@selector(willPresentActionSheet:)])
        [externalDelegate willPresentActionSheet:actionSheet];
}

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet
{
    if (externalDelegate && [externalDelegate respondsToSelector:@selector(didPresentActionSheet:)])
        [externalDelegate didPresentActionSheet:actionSheet];
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (externalDelegate && [externalDelegate respondsToSelector:@selector(actionSheet:willDismissWithButtonIndex:)])
        [externalDelegate actionSheet:actionSheet willDismissWithButtonIndex:buttonIndex];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	NSNumber *key = [NSNumber numberWithInt:buttonIndex];

	SinglyActionSheetBlock block = [actionsPerIndex objectForKey:key];
	if (block) block();

    if (externalDelegate && [externalDelegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)])
        [externalDelegate actionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
}

@end
