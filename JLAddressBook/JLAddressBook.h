//
//  JLAddressBook.h
//  Joseph Laws
//
//  Created by Joseph Laws on 3/7/14.
//  Copyright (c) 2014 Joseph Laws. All rights reserved.
//

#import "JLContact.h"
#import "JLContactManager.h"
@import Foundation;

typedef void (^AuthorizationBlock)(bool granted, NSError *error);

/**
 `JLAddressBook` utilizes a JLContactManager to automatically keep your contact
 entities synced with a users iphone contacts.  You can utilize a
 JLContactManager and JLContact's that are backed by CoreData or your own custom
 entity manager.

 The addressbook methods should ONLY be called on the thread that created it.
 @see JLCoreDataContactManager for an example of how to utilize the addressbook
 on a background thread.
 */
@interface JLAddressBook : NSObject

- (instancetype)initWithContactManager:(id<JLContactManager>)contactManager;

- (BOOL)authorized;
- (void)attemptToAuthorize:(AuthorizationBlock)block;

// If your ContactManager defines existing contacts, the information in your
// existing contacts will be updated to match what is in the device contacts
- (NSArray *)syncContacts;

// If you are not authorized or your contact does not implement
// @selector(addressBookIDs) selector then these methods will return nil. If no
// image is found, nil is returned
- (UIImage *)photoForContact:(id<JLContact>)contact;
- (UIImage *)thumbnailForContact:(id<JLContact>)contact;

// Adds the contact to the device, and if they implement the
// @selector(addressBookIDs) it will be updated with the new recordID
- (void)addContactToDevice:(id<JLContact>)contact;
- (void)addContactToDevice:(id<JLContact>)contact withPhoto:(UIImage *)photo;

@end
