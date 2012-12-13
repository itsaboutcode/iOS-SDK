//
//  SinglyFriend.m
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

#import "SinglyRequest.h"
#import "SinglyFriend.h"

@implementation SinglyFriend

// TODO Perhaps this belongs on SinglySession? SinglyService? Hmm...
+ (void)syncContacts
{

    ABAddressBookRef addressBook = ABAddressBookCreate();
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

    NSLog(@"Contacts to Sync: %@", contactsToSync);

    // TODO Determine self

    NSError *serializationError;
    SinglyRequest *syncRequest = [SinglyRequest requestWithEndpoint:@"friends/ios"];
    [syncRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [syncRequest setHTTPMethod:@"POST"];
    [syncRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:contactsToSync options:kNilOptions error:&serializationError]];

    NSLog(@"Serialization Error: %@", serializationError);

    [NSURLConnection sendAsynchronousRequest:syncRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *responseData, NSError *requestError)
    {
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"Response: %@", responseString);
    }];
}

@end
