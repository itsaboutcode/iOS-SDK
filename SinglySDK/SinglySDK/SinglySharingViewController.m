//
//  SinglySharingViewController.m
//  SinglySDK
//
//  Created by Thomas Muldowney on 9/12/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import "SinglySharingViewController.h"
#import <SinglySDK/SinglySession.h>
#import <SinglySDK/SinglyAPIRequest.h>
#import <QuartzCore/QuartzCore.h>
#import "DEFacebookTextView.h"
#import <QuartzCore/QuartzCore.h>
#import "DEFacebookSheetCardView.h"

@implementation NSString (URLEncode)

- (NSString *)URLEncodedString
{
    __autoreleasing NSString *encodedString;
    
    NSString *originalString = (NSString *)self;
    encodedString = (__bridge_transfer NSString * )
    CFURLCreateStringByAddingPercentEscapes(NULL,
                                            (__bridge CFStringRef)originalString,
                                            NULL,
                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                            kCFStringEncodingUTF8);
    return encodedString;
}
@end

@interface SinglySharingViewController () {
    SinglySession* _session;
    NSString* _service;
}
@end

@implementation SinglySharingViewController

-(id)initWithSession:(SinglySession*)session forService:(NSString*)service;
{
    self = [super init];
    if (self) {
        _session = session;
        _service = service;
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    
    self.titleLabel.text = [_service capitalizedString];
}

-(void)send;
{
    NSString* url = [NSString stringWithFormat:@"/types/%@", ([self attachmentsCount] > 0 ? @"photos" : @"statuses")];
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:_service, @"services", nil];
    SinglyAPIRequest* request = [SinglyAPIRequest apiRequestForEndpoint:url withParameters:params];
    request.method = @"POST";
    if ([self attachmentsCount] > 0) {
        NSLog(@"Getting the photo send ready");
        UIImage* image = [self.images objectAtIndex:0];
        NSData* pngData = UIImagePNGRepresentation(image);
        NSString* imgData = [[NSString alloc] initWithData:pngData encoding:NSASCIIStringEncoding];
        NSMutableData* data = [NSMutableData dataWithCapacity:6 + imgData.length];
        [data appendData:[@"photo=%@" dataUsingEncoding:NSASCIIStringEncoding]];
        [data appendData:[[imgData URLEncodedString] dataUsingEncoding:NSUTF8StringEncoding]];
        request.body = data;
    } else {
        NSString* body = [NSString stringWithFormat:@"body=%@", [self.textView.text URLEncodedString]];
        request.body = [body dataUsingEncoding:NSUTF8StringEncoding];
    }
    //    self.textView.text, @"body", nil];
    [_session requestAPI:request withCompletionHandler:^(NSError *error, id resJson) {
        if (error || [resJson objectForKey:@"error"]) {
            NSLog(@"error:%@", error);
            
            // remove activity
            //[[[self.sendButton subviews] lastObject] removeFromSuperview];
            //[self.sendButton setTitle:@"Post" forState:UIControlStateNormal];
            self.view.userInteractionEnabled = YES;
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Send Message", @"")
                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"The message, \"%@\" cannot be sent.", @""), self.textView.text]
                                                                delegate:self
                                                       cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                       otherButtonTitles:nil];
            //alertView.tag = DEFacebookComposeViewControllerCannotSendAlert;
            [alertView show];
            
            self.sendButton.enabled = YES;
            
            
        } else {
            NSLog(@"Did work: %@", resJson);
            CGFloat yOffset = -(self.view.bounds.size.height + CGRectGetMaxY(self.cardView.frame) + 10.0f);
            
            [UIView animateWithDuration:0.35f
                             animations:^ {
                                 self.cardView.frame = CGRectOffset(self.cardView.frame, 0.0f, yOffset);
                                 self.paperClipView.frame = CGRectOffset(self.paperClipView.frame, 0.0f, yOffset);
                             }];
            
            
            if (self.completionHandler) {
                self.completionHandler(DEFacebookComposeViewControllerResultDone);
            }
            else {
                [self dismissModalViewControllerAnimated:YES];
            }
        }
    }];
    
}
#if 0
-(void)viewDidAppear:(BOOL)animated
{
    CATransition* transition = [CATransition animation];
    transition.type = kCATransitionMoveIn;
    transition.subtype = kCATransitionFromBottom;
    transition.duration = 0.4f;
    [sharingView.layer addAnimation:transition forKey:nil];
}
#endif
@end
