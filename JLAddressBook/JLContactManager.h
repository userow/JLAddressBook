//
//  JLContactManager.h
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/19/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "JLContact.h"
@import Foundation;

@protocol JLContactManager<NSObject>

@required

// Add an extension to an NSManagedObject that implements this protocol if you
// want to be able to sync them directly to coredata
- (id<JLContact>)newContact;

// existingContacts should be an array of id<JLContact>'s. They must implement
// @selector(addressBookIDs) if you want to keep them in sync with the iphone
// contacts, otherwise everytime sync contact is called, new contacts will be
// created and passed to contactsUpdated
- (NSArray *)existingContacts;

@end
