//
//  SinglySession.m
//  SinglySDK
//
//  Copyright (c) 2012 Singly, Inc. All rights reserved.
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

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import "NSURL+AccessToken.h"

#import "SinglyFacebookService.h"
#import "SinglyKeychainItemWrapper.h"
#import "SinglyRequest.h"
#import "SinglySession.h"
#import "SinglySession+Internal.h"

static NSString *kSinglyAccessTokenKey = @"com.singly.accessToken";
static SinglySession *sharedInstance = nil;

@implementation SinglySession

+ (SinglySession*)sharedSession
{
    if (sharedInstance == nil)
        sharedInstance = [[SinglySession alloc] init];
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _accessTokenWrapper = [[SinglyKeychainItemWrapper alloc] initWithIdentifier:kSinglyAccessTokenKey accessGroup:nil];
    }
    return self;
}

#pragma mark - Session Configuration

- (void)setAccessToken:(NSString *)accessToken
{
    [self.accessTokenWrapper setObject:accessToken forKey:(__bridge id)kSecValueData];
}

- (void)setAccountID:(NSString *)accountID
{
    [self.accessTokenWrapper setObject:accountID forKey:(__bridge id)kSecAttrAccount];
}

#pragma mark - Session Management

- (NSString *)accessToken
{
    NSString *theAccessToken = [self.accessTokenWrapper objectForKey:(__bridge id)kSecValueData];
    if (theAccessToken.length == 0) theAccessToken = nil;
    return theAccessToken;
}

- (NSString *)accountID
{
    NSString *theAccountID = [self.accessTokenWrapper objectForKey:(__bridge id)kSecAttrAccount];
    if (theAccountID.length == 0) theAccountID = nil;
    return theAccountID;
}

- (void)startSessionWithCompletionHandler:(void (^)(BOOL))block
{
    // If we don't have an accountID or accessToken we're definitely not ready
    if (!self.accountID || !self.accessToken) return block(NO);

    dispatch_queue_t resultQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateProfilesWithCompletion:^(BOOL success) {
            NSString *foundAccountID = [self.profile objectForKey:@"id"];
            _isReady = ([foundAccountID isEqualToString:self.accountID]);
            dispatch_sync(resultQueue, ^{
                block(self.isReady);
            });
        }];
    });
}

- (void)resetSession
{

    // Reset Session Ready State
    _isReady = NO;

    // Reset Profiles
    _profiles = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kSinglySessionProfilesUpdatedNotification
                                                        object:self];

    // Reset Access Token & Account ID
    self.accessToken = nil;
    self.accountID = nil;

}

#pragma mark - Profile Management

- (void)updateProfiles
{
    [self updateProfilesWithCompletion:nil];
}

- (void)updateProfilesWithCompletion:(void (^)(BOOL))block
{
    dispatch_queue_t curQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *requestError;
        NSURLResponse *response;
        BOOL isSuccessful = NO;

        SinglyRequest *request = [SinglyRequest requestWithEndpoint:@"profile" andParameters:@{ @"auth" : @"true" }];
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];

        // Check for invalid or expired tokens...
        if (requestError)
        {
            NSLog(@"[SinglySDK:SinglySession] An error occurred while requesting profiles: %@", requestError);

            _profile = [NSDictionary dictionary];
            _profiles = [NSDictionary dictionary];

            if ([(NSHTTPURLResponse *)response statusCode] == 401)
            {
                NSLog(@"[SinglySDK:SinglySession] Access token is invalid or expired! Need to reauthorize...");
                self.accessToken = nil;
            }

            if (block) dispatch_sync(curQueue, ^{
                block(isSuccessful);
            });

            return;
        }

        // Parse the profiles response...
        NSError *parseError;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];

        // Check for parse errors...
        if (parseError)
            NSLog(@"[SinglySDK:SinglySession] An error occurred while attempting to parse profiles: %@", parseError);

        else
        {

            // Check for service errors...
            NSString *serviceError = [responseDictionary valueForKey:@"error"];
            if (serviceError)
                NSLog(@"[SinglySDK:SinglySession] A service error occurred while requesting profiles: %@", serviceError);

            else
            {
                NSDictionary *serviceProfiles = responseDictionary[@"services"];
                _profile = responseDictionary;
                _profiles = serviceProfiles;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSNotificationCenter.defaultCenter postNotificationName:kSinglySessionProfilesUpdatedNotification
                                                                      object:self];
                });
                isSuccessful = YES;
            }
        }

        if (block) dispatch_sync(curQueue, ^{
            block(isSuccessful);
        });

    });
}

#pragma mark - Service Management

- (void)applyService:(NSString *)serviceIdentifier withToken:(NSString *)token
{
    NSLog(@"[SinglySDK] Applying service '%@' with token '%@' to the Singly service ...", serviceIdentifier, token);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *requestError;
        NSError *parseError;
        NSURLResponse *response;
        SinglyRequest *request = [[SinglyRequest alloc] initWithEndpoint:[NSString stringWithFormat:@"auth/%@/apply", serviceIdentifier]];
        request.parameters = @{
        @"client_id": self.clientID,
        @"client_secret": self.clientSecret,
        @"token": token
        };
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];

        if (!requestError && !parseError)
        {
            dispatch_async(dispatch_get_current_queue(), ^{
                SinglySession.sharedSession.accessToken = responseDictionary[@"access_token"];
                SinglySession.sharedSession.accountID = responseDictionary[@"account"];
                [SinglySession.sharedSession updateProfilesWithCompletion:^(BOOL successful) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [NSNotificationCenter.defaultCenter postNotificationName:kSinglyServiceAppliedNotification
                                                                          object:serviceIdentifier];
                    });
                }];
            });
        }
    });
}

#pragma mark - Device Contacts

- (void)syncDeviceContacts
{

    ABAddressBookRef addressBook = ABAddressBookCreate();

    // Ask for permission to access the device contacts...
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            [self syncDeviceContactsFromAddressBook:addressBook];
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
    {
        [self syncDeviceContactsFromAddressBook:addressBook];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:@"Unable to sync contacts because we are not allowed to read contacts. Please enable access for this app in Settings."
                                                           delegate:self
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
    }

}

- (void)syncDeviceContactsFromAddressBook:(ABAddressBookRef)addressBook
{
    CFArrayRef allContacts = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex contactsCount = ABAddressBookGetPersonCount(addressBook);
    NSMutableArray *contactsToSync = [NSMutableArray arrayWithCapacity:contactsCount];

    for (int i = 0; i < contactsCount; i++)
    {
        ABRecordRef contactReference = CFArrayGetValueAtIndex(allContacts, i);
        NSMutableDictionary *contact = [NSMutableDictionary dictionary];

        // Record ID
        contact[@"id"] = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(contactReference)];

        // Name
        contact[@"name"] = [NSString stringWithFormat:@"%@ %@", ABRecordCopyValue(contactReference, kABPersonFirstNameProperty), ABRecordCopyValue(contactReference, kABPersonLastNameProperty)];

        // Phone Numbers
        NSArray *phoneNumbers = ((__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(ABRecordCopyValue(contactReference, kABPersonPhoneProperty)));
        if (phoneNumbers.count > 0) contact[@"phones"] = phoneNumbers;

        // Email Addresses
        NSArray *emailAddresses = ((__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(ABRecordCopyValue(contactReference, kABPersonEmailProperty)));
        if (emailAddresses.count > 0) contact[@"emails"] = emailAddresses;

        [contactsToSync addObject:contact];
    }

    CFRelease(addressBook);
    CFRelease(allContacts);

    NSDictionary *profile = SinglySession.sharedSession.profile;
    NSDictionary *selfProfile;

    // Determine self by ...
    for (NSMutableDictionary *contact in contactsToSync)
    {
        // ... comparing e-mail addresses
        NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF IN %@", contact[@"emails"]];
        BOOL isFound = [emailPredicate evaluateWithObject:profile[@"email"]];
        if (isFound)
        {
            contact[@"self"] = @"true";
            selfProfile = contact;
            break;
        }

        contact[@"self"] = @"false";
    }

    if (!selfProfile)
    {
        NSLog(@"[SinglySDK:SinglySession] Unable to determine self for contacts sync!");
    }

    // Prepare to send contacts to the Singly API
    NSError *serializationError;
    SinglyRequest *syncRequest = [SinglyRequest requestWithEndpoint:@"friends/ios"];
    [syncRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [syncRequest setHTTPMethod:@"POST"];
    [syncRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:contactsToSync options:kNilOptions error:&serializationError]];

    // Check for serialization errors...
    if (serializationError)
        NSLog(@"[SinglySDK:SinglySession] Serialization error while preparing contacts for syncing: %@", serializationError);

    [NSURLConnection sendAsynchronousRequest:syncRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError) {
        NSError *parseError;
        id syncedContacts = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];

        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:kSinglyContactsSyncedNotification
                                                              object:syncedContacts];
        });
    }];
    
}

#pragma mark - URL Handling

- (BOOL)handleOpenURL:(NSURL *)url
{

    // Facebook
    if ([url.scheme hasPrefix:@"fb"])
    {
        NSString *accessToken = [url extractAccessToken];
        if (accessToken)
        {
            [SinglySession.sharedSession applyService:@"facebook" withToken:accessToken];
            return YES;
        }
    }

    return NO;

}

@end
