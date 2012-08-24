//
//  SinglyViewController.h
//  SinglySDK Example
//
//  Created by Thomas Muldowney on 8/22/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SinglySDK.h>

@interface SinglyViewController : UIViewController<SinglySessionDelegate>

#pragma mark - SinglySessionDelegate
-(void)singlyResultForAPI:(NSString *)api withJSON:(id)json;
-(void)singlyErrorForAPI:(NSString *)api withError:(NSError *)error;
@end
