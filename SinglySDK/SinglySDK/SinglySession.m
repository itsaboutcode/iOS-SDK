//
//  SinglySession.m
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

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import "NSURL+AccessToken.h"

#import "SinglyConstants.h"
#import "SinglyFacebookService.h"
#import "SinglyKeychainItemWrapper.h"
#import "SinglyRequest.h"
#import "SinglySession.h"
#import "SinglySession+Internal.h"

static NSString *kSinglyAccessTokenKey = @"com.singly.accessToken";
static SinglySession *sharedInstance = nil;

@implementation SinglySession

+ (SinglySession *)sharedSession
{
    static dispatch_once_t queue;
    dispatch_once(&queue, ^{
        sharedInstance = [[SinglySession alloc] init];
    });

    return sharedInstance;
}

+ (SinglySession *)sharedSessionInstance
{
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

- (NSString *)accessToken
{
    NSString *theAccessToken = [self.accessTokenWrapper objectForKey:(__bridge id)kSecValueData];
    if (theAccessToken.length == 0) theAccessToken = nil;
    return theAccessToken;
}

- (void)requestAccessTokenWithCode:(NSString *)code
{
    [self requestAccessTokenWithCode:code completion:nil];
}

- (void)requestAccessTokenWithCode:(NSString *)code completion:(void (^)(NSString *, NSError *))completionHandler
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSError *requestError;
        NSError *parseError;
        NSURLResponse *response;

        // Prepare Request
        SinglyRequest *request = [[SinglyRequest alloc] initWithEndpoint:@"oauth/access_token"];
        request.HTTPMethod = @"POST";
        request.parameters = @{
            @"code" : code,
            @"client_id" : self.clientID,
            @"client_secret" : self.clientSecret
        };

        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];

        // Check for Parse Errors
        if (parseError)
        {
            NSLog(@"[SinglySDK] A parse error occurred while attempting to parse the response to our access token request: %@", [parseError localizedDescription]);

            dispatch_sync(currentQueue, ^{ completionHandler(nil, parseError); });
            return;
        }

        // Check for Service Errors
        NSString *serviceErrorMessage = [responseDictionary objectForKey:@"error"];
        if (serviceErrorMessage)
        {
            NSLog(@"[SinglySDK] A service error occurred while attempting to fetch the access token: %@", serviceErrorMessage);

            NSError *serviceError = [NSError errorWithDomain:kSinglyErrorDomain
                                                        code:kSinglyServiceErrorCode
                                                    userInfo:@{ NSLocalizedDescriptionKey : serviceErrorMessage }];

            dispatch_sync(currentQueue, ^{ completionHandler(nil, serviceError); });
            return;
        }

        // Persist the Access Token and Account ID
        self.accessToken = [responseDictionary objectForKey:@"access_token"];
        self.accountID = [responseDictionary objectForKey:@"account"];

        dispatch_sync(currentQueue, ^{
            completionHandler(self.accessToken, nil);
        });

    });
}

- (void)setAccountID:(NSString *)accountID
{
    [self.accessTokenWrapper setObject:accountID forKey:(__bridge id)kSecAttrAccount];
}

- (NSString *)accountID
{
    NSString *theAccountID = [self.accessTokenWrapper objectForKey:(__bridge id)kSecAttrAccount];
    if (theAccountID.length == 0) theAccountID = nil;
    return theAccountID;
}

- (BOOL)isReady
{
    BOOL ready = YES;

    // The access token and account id should be set...
    if (!self.accessToken) ready = NO;
    if (!self.accountID) ready = NO;

    // The loaded profile id should match the account id...
    if (self.profile && ![self.profile[@"id"] isEqualToString:self.accountID])
        ready = NO;

    return ready;
}

#pragma mark - Session Management

- (void)startSessionWithCompletion:(void (^)(BOOL))completionHandler
{
    // Raise an error if the Client ID and Client Secret have not been provided!
    if (!self.clientID || !self.clientSecret)
    {
        [NSException raise:kSinglyCredentialsMissingException
                    format:@"%s: missing client id and/or client secret!", __PRETTY_FUNCTION__];
    }

    // Ensure that we have an Access Token and Account ID...
    if (!self.accountID || !self.accessToken)
    {
        if (completionHandler) completionHandler(NO);
        return;
    }

    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateProfilesWithCompletion:^(BOOL isSuccessful) {
            if (completionHandler)
            {
                dispatch_sync(currentQueue, ^{
                    completionHandler(self.isReady);
                });
            }
        }];
    });
}

- (void)startSessionWithCompletionHandler:(void (^)(BOOL))completionHandler // DEPRECATED
{
    [self startSessionWithCompletion:completionHandler];
}

- (void)resetSession
{

    // Reset Access Token
    self.accessToken = nil;
    self.accountID = nil;

    // Reset Profiles
    _profile = nil;
    _profiles = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kSinglySessionProfilesUpdatedNotification
                                                        object:self];

    // Reset the Keychain Item
    [self.accessTokenWrapper resetKeychainItem];

}

#pragma mark - Profile Management

- (void)updateProfiles
{
    [self updateProfilesWithCompletion:nil];
}

- (void)updateProfilesWithCompletion:(void (^)(BOOL))completionHandler
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
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

            // Reset Profiles
            _profile = nil;
            _profiles = nil;

            // If the access token has become invalid and the user is denied
            // access, reset the session.
            if (requestError.code == NSURLErrorUserCancelledAuthentication)
            {
                NSLog(@"[SinglySDK:SinglySession] Access token is invalid or expired! Need to reauthorize...");
                dispatch_sync(currentQueue, ^{
                    [self resetSession];
                });
            }

            if (completionHandler) dispatch_sync(currentQueue, ^{
                completionHandler(NO);
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

        if (completionHandler) dispatch_sync(currentQueue, ^{
            completionHandler(isSuccessful);
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
    [self syncDeviceContactsWithCompletion:nil];
}

- (void)syncDeviceContactsWithCompletion:(void (^)(BOOL, NSArray *))completionHandler
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Only allow a single sync operation to be performed at a given time.
        if (self.isSyncingDeviceContacts) return;
        _isSyncingDeviceContacts = YES;

        ABAddressBookRef addressBook;
        __block BOOL isAuthorized = NO;

        // On iOS 6+ we need to ask the user for permission to access their contacts.
        if (ABAddressBookCreateWithOptions != NULL)
        {
            dispatch_semaphore_t accessSemaphore = dispatch_semaphore_create(0);
            addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                isAuthorized = granted;
                dispatch_semaphore_signal(accessSemaphore);
            });
            dispatch_semaphore_wait(accessSemaphore, DISPATCH_TIME_FOREVER);
            dispatch_release(accessSemaphore);
        }

        // iOS 5.x
        else
        {
            addressBook = ABAddressBookCreate();
            isAuthorized = YES;
        }

        // If we are not authorized, notify the user that they will need to allow
        // the app to access their contacts in order to perform a sync.
        if (!isAuthorized)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"Unable to sync contacts because we are not allowed to access the contacts on this device. Please enable access for this app in Settings."
                                                               delegate:self
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
            [alertView show];
            _isSyncingDeviceContacts = NO;
            return;
        }

        NSArray *allContacts = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSMutableArray *contactsToSync = [NSMutableArray arrayWithCapacity:allContacts.count];
        for (int i = 0; i < allContacts.count; i++)
        {
            ABRecordRef contactReference = (__bridge ABRecordRef)allContacts[i];
            NSMutableDictionary *contact = [NSMutableDictionary dictionary];

            // Record ID
            contact[@"id"] = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(contactReference)];

            // Name
            contact[@"name"] = [NSString stringWithFormat:@"%@ %@", ABRecordCopyValue(contactReference, kABPersonFirstNameProperty), ABRecordCopyValue(contactReference, kABPersonLastNameProperty)];

            // Phone Numbers
            NSArray *phoneNumbers = ((__bridge_transfer NSArray *)ABMultiValueCopyArrayOfAllValues(ABRecordCopyValue(contactReference, kABPersonPhoneProperty)));
            if (phoneNumbers.count > 0) contact[@"phones"] = phoneNumbers;

            // Email Addresses
            NSArray *emailAddresses = ((__bridge_transfer NSArray *)ABMultiValueCopyArrayOfAllValues(ABRecordCopyValue(contactReference, kABPersonEmailProperty)));
            if (emailAddresses.count > 0) contact[@"emails"] = emailAddresses;

            // Self? (Determined Below...)
            contact[@"self"] = @"false";

            [contactsToSync addObject:contact];
        }

        // Release the address book reference, as we no longer need it to continue.
        CFRelease(addressBook);

        NSDictionary *singlyProfile= SinglySession.sharedSession.profile;
        NSDictionary *ownerProfile;

        // Attempt to determine who the device owner is by comparing their Singly
        // profile against the local address book.
        // TODO Match singly profile against more attributes in the local address book
        for (NSMutableDictionary *contact in contactsToSync)
        {
            // ... comparing e-mail addresses
            NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF IN %@", contact[@"emails"]];
            BOOL isFound = [emailPredicate evaluateWithObject:singlyProfile[@"email"]];
            if (isFound)
            {
                contact[@"self"] = @"true";
                ownerProfile = contact;
                break;
            }
        }
        if (!ownerProfile)
            NSLog(@"[SinglySDK:SinglySession] Unable to determine self for contacts sync!");

        // Prepare to send contacts to the Singly API
        NSError *serializationError;
        NSError *requestError;
        NSError *parseError;
        NSURLResponse *response;
        SinglyRequest *syncRequest = [SinglyRequest requestWithEndpoint:@"friends/ios"];
        [syncRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [syncRequest setHTTPMethod:@"POST"];
        [syncRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:contactsToSync options:kNilOptions error:&serializationError]];

        // Check for serialization errors...
        if (serializationError)
            NSLog(@"[SinglySDK:SinglySession] Serialization error while preparing contacts for syncing: %@", serializationError);

        NSData *responseData = [NSURLConnection sendSynchronousRequest:syncRequest returningResponse:&response error:&requestError];

        // Check for Request Errors
        if (requestError)
        {
            NSLog(@"[SinglySDK:SinglySession] An error occurred while syncing contacts: %@", requestError);
            
            if (completionHandler) dispatch_sync(currentQueue, ^{
                completionHandler(NO, nil);
            });

            return;
        }

        // Parse Synced Contacts
        id syncedContacts = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parseError];
        if (parseError)
            NSLog(@"[SinglySDK:SinglySession] An error occurred while attempting to parse profiles: %@", parseError);

        _isSyncingDeviceContacts = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:kSinglyContactsSyncedNotification
                                                              object:syncedContacts];
        });

        if (completionHandler) dispatch_sync(currentQueue, ^{
            completionHandler(YES, syncedContacts);
        });
    });
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

