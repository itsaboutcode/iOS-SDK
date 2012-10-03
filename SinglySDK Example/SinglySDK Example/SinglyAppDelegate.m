//
//  SinglyAppDelegate.m
//  SinglySDK Example
//
//  Created by Thomas Muldowney on 8/22/12.
//  Copyright (c) 2012 Singly. All rights reserved.
//

#import "SinglyAppDelegate.h"

@implementation SinglyAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    // Configure Shared SinglySession
    SinglySession *session = [SinglySession sharedSession];
    session.clientID = CLIENT_ID;
    session.clientSecret = CLIENT_SECRET;
    NSLog(@"Singly Session\n  - Account: %@\n  - Access Token: %@)", session.accountID, session.accessToken);

    [[NSNotificationCenter defaultCenter] addObserverForName:kSinglyNotificationSessionProfilesUpdated object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        NSLog(@"**** Profiles were updated");
    }];
    
    [session startSessionWithCompletionHandler:^(BOOL ready) {
        NSLog(@"The session is ready to roll.");
    }];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
