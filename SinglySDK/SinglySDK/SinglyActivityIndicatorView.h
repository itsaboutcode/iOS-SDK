//
//  SinglyActivityIndicatorView.h
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

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

/*!
 *
 * A simple activity indicator that displays a rotating instance of the Singly
 * gradient logo. This is used by the various view controllers in the SDK.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
@interface SinglyActivityIndicatorView : UIView

/// ----------------------------------------------------------------------------
/// @name Accessing the Indicator View
/// ----------------------------------------------------------------------------

/*!
 *
 * The shared singleton activity indicator instance.
 *
 * @returns SinglyActivityIndicatorView
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
+ (SinglyActivityIndicatorView *)sharedIndicator;

/// ----------------------------------------------------------------------------
/// @name Controlling Visibility
/// ----------------------------------------------------------------------------

/*!
 *
 * Displays the activity indicator centered on the main window object.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
+ (void)showIndicator;

/*!
 *
 * Dismisses the activity indicator from view.
 *
 * @available Available in Singly iOS SDK 1.0.0 and later.
 *
**/
+ (void)dismissIndicator;

@end
