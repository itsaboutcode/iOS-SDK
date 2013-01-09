//
//  SinglyKeychainItemWrapper.m
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

#import <Security/Security.h>
#import "SinglyKeychainItemWrapper.h"
#import "SinglyKeychainItemWrapper+Internal.h"

@implementation SinglyKeychainItemWrapper

- (id)initWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup
{
    self = [super init];
    if (self)
    {

        //
        // Begin Keychain search setup. The genericPasswordQuery leverages the
        // special user defined attribute kSecAttrGeneric to distinguish itself
        // between other generic Keychain items which may be included by the
        // same application.
        //
        _genericPasswordQuery = [[NSMutableDictionary alloc] init];
		[_genericPasswordQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [_genericPasswordQuery setObject:identifier forKey:(__bridge id)kSecAttrGeneric];

        //
		// The keychain access group attribute determines if this item can be shared
		// amongst multiple apps whose code signing entitlements contain the same keychain access group.
        //
		if (accessGroup != nil)
		{
            #if !TARGET_IPHONE_SIMULATOR
                [_genericPasswordQuery setObject:accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
            #endif
		}

        //
		// Use the proper search constants, return only the attributes of the
        // first match.
        //
        _genericPasswordQuery[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
        _genericPasswordQuery[(__bridge id)kSecReturnAttributes] = (__bridge id)kCFBooleanTrue;

        NSDictionary *tempQuery = [NSDictionary dictionaryWithDictionary:self.genericPasswordQuery];
        CFDictionaryRef outDictionaryReference = NULL;
        if (!SecItemCopyMatching((__bridge CFDictionaryRef)tempQuery, (CFTypeRef *)&outDictionaryReference) == noErr)
        {
            //
            // Stick these default values into keychain item if nothing found.
            //
            [self resetKeychainItem];

            //
			// Add the generic attribute and the keychain access group.
            //
            _keychainItemData[(__bridge id)kSecAttrGeneric] = identifier;
			if (accessGroup)
			{
                #if !TARGET_IPHONE_SIMULATOR
                    _keychainItemData[(__bridge id)kSecAttrAccessGroup] = accessGroup;
                #endif
			}
		}
        else
        {
            //
            // Load the saved data from Keychain.
            //
            NSMutableDictionary *outDictionary = (__bridge_transfer NSMutableDictionary *)outDictionaryReference;
            _keychainItemData = [self secItemFormatToDictionary:outDictionary];
        }
    }
	return self;
}

- (void)setObject:(id)inObject forKey:(id)key
{
    if (inObject == nil) return;
    id currentObject = self.keychainItemData[key];
    if (![currentObject isEqual:inObject])
    {
        self.keychainItemData[key] = inObject;
        [self writeToKeychain];
    }
}

- (id)objectForKey:(id)key
{
    return self.keychainItemData[key];
}

- (void)resetKeychainItem
{
	OSStatus junk = noErr;
    if (!self.keychainItemData)
    {
        _keychainItemData = [[NSMutableDictionary alloc] init];
    }
    else
    {
        NSMutableDictionary *tempDictionary = [self dictionaryToSecItemFormat:self.keychainItemData];
		junk = SecItemDelete((__bridge CFDictionaryRef)tempDictionary);
        NSAssert(junk == noErr || junk == errSecItemNotFound, @"Problem deleting current dictionary.");
    }

    //
    // Default attributes for keychain item.
    //
    self.keychainItemData[(__bridge id)kSecAttrAccount] = @"";
    self.keychainItemData[(__bridge id)kSecAttrLabel] = @"";
    self.keychainItemData[(__bridge id)kSecAttrDescription] = @"";

    //
	// Default data for keychain item.
    //
    self.keychainItemData[(__bridge id)kSecValueData] = @"";
}

- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert
{
    //
    // The assumption is that this method will be called with a properly
    // populated dictionary containing all the right key/value pairs for a
    // SecItem.
    //

    //
    // Create a dictionary to return populated with the attributes and data.
    //
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];

    //
    // Add the Generic Password keychain item class attribute.
    //
    returnDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;

    //
    // Convert the NSString to NSData to meet the requirements for the value
    // type kSecValueData. This is where to store sensitive data that should be
    // encrypted.
    //
    NSString *passwordString = dictionaryToConvert[(__bridge id)kSecValueData];
    [returnDictionary setObject:[passwordString dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];

    return returnDictionary;
}

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
    //
    // The assumption is that this method will be called with a properly
    // populated dictionary containing all the right key/value pairs for the UI
    // element.
    //

    //
    // Create a dictionary to return populated with the attributes and data.
    //
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];

    //
    // Add the proper search key and class attribute.
    //
    [returnDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];

    //
    // Acquire the password data from the attributes.
    //
    CFDataRef passwordDataReference = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary, (CFTypeRef *)&passwordDataReference) == noErr)
    {
        NSData *passwordData = (__bridge_transfer NSData *)passwordDataReference;

        //
        // Remove the search, class, and identifier key/value, we don't need them anymore.
        //
        [returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];

        //
        // Add the password to the dictionary, converting from NSData to NSString.
        //
        NSString *password = [[NSString alloc] initWithBytes:[passwordData bytes] length:[passwordData length]
                                                    encoding:NSUTF8StringEncoding];
        returnDictionary[(__bridge id)kSecValueData] = password;
    }
    else
    {
        //
        // Don't do anything if nothing is found.
        //
        NSAssert(NO, @"Serious error, no matching item found in the keychain.\n");
    }

	return returnDictionary;
}

- (void)writeToKeychain
{
    CFDictionaryRef attributesReference = NULL;
    NSMutableDictionary *updateItem = NULL;
	OSStatus result;

    if (SecItemCopyMatching((__bridge CFDictionaryRef)self.genericPasswordQuery, (CFTypeRef *)&attributesReference) == noErr)
    {
        NSDictionary *attributes = (__bridge_transfer NSDictionary *)attributesReference;

        //
        // First we need the attributes from the Keychain.
        //
        updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];

        //
        // Second we need to add the appropriate search key/values.
        //
        updateItem[(__bridge id)kSecClass] = self.genericPasswordQuery[(__bridge id)kSecClass];

        //
        // Lastly, we need to set up the updated attribute list being careful to
        // remove the class.
        //
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:self.keychainItemData];
        [tempCheck removeObjectForKey:(__bridge id)kSecClass];

        //
		// Remove the access group if running on the iPhone simulator.
		//
        #if TARGET_IPHONE_SIMULATOR
            [tempCheck removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
        #endif

        //
        // An implicit assumption is that you can only update a single item at
        // a time.
        //
        result = SecItemUpdate((__bridge CFDictionaryRef)updateItem, (__bridge CFDictionaryRef)tempCheck);
		NSAssert(result == noErr, @"Couldn't update the Keychain Item.");
    }
    else
    {
        //
        // No previous item found; add the new one.
        //
        result = SecItemAdd((__bridge CFDictionaryRef)[self dictionaryToSecItemFormat:self.keychainItemData], NULL);
		NSAssert(result == noErr, @"Couldn't add the Keychain Item.");
    }
}

@end
