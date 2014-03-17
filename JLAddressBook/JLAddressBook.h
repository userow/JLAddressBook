//
//  JLAddressBook.h
//  Joseph Laws
//
//  Created by Joseph Laws on 3/7/14.
//  Copyright (c) 2014 Joseph Laws. All rights reserved.
//

typedef void (^AuthorizationBlock)(bool granted, NSError *error);
typedef void (^SyncBlock)();

@protocol JLContact<NSObject>

@optional

@property(nonatomic, strong) NSString *firstName;
@property(nonatomic, strong) NSString *lastName;
@property(nonatomic, strong) NSArray *phoneNumbers;    // NSString's
@property(nonatomic, strong) NSArray *emails;          // NSString's
@property(nonatomic, strong) NSArray *addressBookIDs;  // NSNumbers's
@property(nonatomic, strong) UIImage *thumbnail;
@property(nonatomic, strong) UIImage *photo;

@end

@protocol JLContactManager<NSObject>

@required

// Add an extension to an NSManagedObject that implements this protocol if you
// want to be able to sync them directly to coredata
- (id<JLContact>)newContact;

// called when syncContacts is complete, and if monitorChanges is set to TRUE,
// then it is called when a change occurs on the device.  This is where you
// would want to save the NSManagedObjectContext if you are syncing your
// contacts in CoreData
- (void)contactsUpdated:(NSArray *)contacts;

// existingContacts should be an array of id<JLContact>'s. They must implement
// @selector(addressBookIDs) if you want to keep them in sync with the iphone
// contacts, otherwise everytime sync contact is called, new contacts will be
// created and passed to contactsUpdated
- (NSArray *)existingContacts;

// Any existing contacts without addressBookIDs will be automatically saved to
// the device during a syncContact event
- (BOOL)saveToDevice;

@end
/**
 `JLAddressBook` utilizes a JLContactManager to automatically keep your contact
 entities synced with a users iphone contacts.  You can utilize a
 JLContactManager and JLContact's that are backed by CoreData or your own custom
 entity manager.
 */
@interface JLAddressBook : NSObject

- (instancetype)initWithContactManager:(id<JLContactManager>)contactManager;

- (BOOL)authorized;
- (void)attemptToAuthorize:(AuthorizationBlock)block;

// If you are not authorized or your contact does not implement
// @selector(addressBookIDs) selector then these methods will return nil. If no
// image is found, nil is returned
- (UIImage *)photoForContact:(id<JLContact>)contact;
- (UIImage *)thumbnailForContact:(id<JLContact>)contact;

// If your ContactManager defines existing contacts, the information in your
// existing contacts will be updated to match what is in the device contacts
// This occurs on a different thread, and both will utilize the contactsUpdated
// callback when it is complete
- (void)syncContacts;
- (void)syncContactsAndThen:(SyncBlock)block;

- (void)addContactToDevice:(id<JLContact>)contact;
- (void)addContactToDevice:(id<JLContact>)contact withPhoto:(UIImage *)photo;

@end
