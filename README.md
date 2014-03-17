# JLAddressBook

[![Version](http://cocoapod-badges.herokuapp.com/v/JLAddressBook/badge.png)](http://cocoadocs.org/docsets/JLAddressBook)
[![Platform](http://cocoapod-badges.herokuapp.com/p/JLAddressBook/badge.png)](http://cocoadocs.org/docsets/JLAddressBook)

## Requirements

iOS 7.0

## Installation

JLAddressBook is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "JLAddressBook"

## Usage

To run the example project; clone the repo, run `pod install`, then open the JLAddressBookExample.xcworkspace.

All you need to do is create an entity type that conforms to this protocol

```objective-c
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
```

and then define a contact manager to keep track of these entities

```objective-c
@protocol JLContactManager<NSObject>

@required

- (id<JLContact>)newContact;
- (void)contactsUpdated:(NSArray *)contacts;
- (NSArray *)existingContacts;
- (BOOL)saveToDevice;

@end
```

then you utilize JLAddressBook to asynchronously update your core data contacts from the iphone address book

```objective-c
@interface JLAddressBook : NSObject

- (instancetype)initWithContactManager:(id<JLContactManager>)contactManager;

- (BOOL)authorized;
- (void)attemptToAuthorize:(AuthorizationBlock)block;

- (UIImage *)photoForContact:(id<JLContact>)contact;
- (UIImage *)thumbnailForContact:(id<JLContact>)contact;

- (void)syncContacts;
- (void)syncContactsAndThen:(SyncBlock)block;

- (void)addContactToDevice:(id<JLContact>)contact;
- (void)addContactToDevice:(id<JLContact>)contact withPhoto:(UIImage *)photo;

@end
```

## Author

Joe Laws, joe.laws@gmail.com

## License

JLAddressBook is available under the MIT license. See the LICENSE file for more info.

