//
//  JLAddressBook.m
//  Joseph Laws
//
//  Created by Joseph Laws on 3/7/14.
//  Copyright (c) 2014 Joseph Laws. All rights reserved.
//

#import "JLAddressBook.h"
@import AddressBook;

@interface JLAddressBook ()
@property(nonatomic, strong) NSRegularExpression *regex;
@property(nonatomic, strong) id<JLContactManager> contactManager;
@property(nonatomic) ABAddressBookRef addressBook;
@end

@implementation JLAddressBook

- (instancetype)initWithContactManager:(id<JLContactManager>)contactManager {
  self = [super init];
  if (self) {
    NSError *error = nil;
    self.regex = [NSRegularExpression
        regularExpressionWithPattern:@"[^\\d]"
                             options:NSRegularExpressionCaseInsensitive
                               error:&error];

    if (error) {
      NSLog(@"Failed to instantiate the regex parser");
      return nil;
    }

    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);

    if (!self.addressBook) {
      NSLog(@"Failed to instantiate an ABAddressBook");
      return nil;
    }

    self.contactManager = contactManager;
  }
  return self;
}

- (void)dealloc {
  CFRelease(self.addressBook);
}

+ (BOOL)authorized {
  return ABAddressBookGetAuthorizationStatus() ==
         kABAuthorizationStatusAuthorized;
}

+ (void)attemptToAuthorize:(AuthorizationBlock)block {
  ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();

  switch (status) {
    case kABAuthorizationStatusAuthorized: {
      block(true, nil);
    } break;
    case kABAuthorizationStatusNotDetermined: {
      ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
      ABAddressBookRequestAccessWithCompletion(
          addressBook, ^(bool granted, CFErrorRef error) {
              if (granted) {
                block(true, nil);
              } else {
                block(false, (__bridge NSError *)error);
              }
          });
    } break;
    case kABAuthorizationStatusDenied: {
      block(false, [NSError errorWithDomain:@"Denied"
                                       code:kABAuthorizationStatusDenied
                                   userInfo:nil]);
    } break;
    case kABAuthorizationStatusRestricted: {
      block(false, [NSError errorWithDomain:@"Restricted"
                                       code:kABAuthorizationStatusRestricted
                                   userInfo:nil]);
    } break;
    default: {
      block(false, [NSError errorWithDomain:@"Unknown"
                                       code:kABAuthorizationStatusNotDetermined
                                   userInfo:nil]);
    } break;
  }
}

- (NSArray *)syncContacts {
  if (![JLAddressBook authorized]) return nil;

  NSArray *existingContacts = self.contactManager.existingContacts;

  CFArrayRef peopleArrayRef =
      ABAddressBookCopyArrayOfAllPeople(self.addressBook);
  NSUInteger contactCount = (NSUInteger)CFArrayGetCount(peopleArrayRef);
  NSMutableSet *linkedPeopleToSkip = [[NSMutableSet alloc] init];

  NSMutableDictionary *idsToExistingContacts = [NSMutableDictionary new];

  if ([[existingContacts firstObject]
          respondsToSelector:@selector(addressBookIDs)]) {
    for (id<JLContact> contact in existingContacts) {
      if (contact.addressBookIDs) {
        for (NSNumber *addressBookID in contact.addressBookIDs) {
          [idsToExistingContacts setObject:contact forKey:addressBookID];
        }
      }
    }
  }

  NSMutableArray *contacts = [NSMutableArray new];

  for (NSUInteger i = 0; i < contactCount; i++) {
    ABRecordRef originalRef = CFArrayGetValueAtIndex(peopleArrayRef, i);

    if ([linkedPeopleToSkip
            containsObject:@(ABRecordGetRecordID(originalRef))]) {
      continue;
    }

    CFArrayRef linkedArrayRef = ABPersonCopyArrayOfAllLinkedPeople(originalRef);
    NSUInteger linkedCount = (NSUInteger)CFArrayGetCount(linkedArrayRef);

    id<JLContact> contact;

    for (NSUInteger i = 0; i < linkedCount; i++) {
      ABRecordRef recordRef = CFArrayGetValueAtIndex(linkedArrayRef, i);
      NSNumber *recordID = @(ABRecordGetRecordID(recordRef));

      id<JLContact> recordContact =
          [idsToExistingContacts objectForKey:recordID];

      if (recordContact) {
        if (!contact) {
          contact = recordContact;
        } else if (contact && recordContact != contact) {
          // Found two previously distinct contacts
          // TODO merge the contacts and delete one in coredata
        }
      }

      [linkedPeopleToSkip addObject:recordID];
    }

    if (!contact) {
      contact = [self.contactManager newContact];
      [self populateContact:contact
               withArrayRef:linkedArrayRef
                  withCount:linkedCount];
    } else {
      [self populateContact:contact
               withArrayRef:linkedArrayRef
                  withCount:linkedCount];
    }

    CFRelease(linkedArrayRef);

    [contacts addObject:contact];
  }

  CFRelease(peopleArrayRef);

  return contacts;
}

- (UIImage *)photoForContact:(id<JLContact>)contact {
  return [self imageAs:NO forContact:contact];
}

- (UIImage *)thumbnailForContact:(id<JLContact>)contact {
  return [self imageAs:YES forContact:contact];
}

- (void)addContactToDevice:(id<JLContact>)contact {
  [self addContactToDevice:contact withPhoto:nil];
}

- (void)addContactToDevice:(id<JLContact>)contact withPhoto:(UIImage *)photo {
  ABRecordRef record = ABPersonCreate();

  if ([contact respondsToSelector:@selector(firstName)]) {
    ABRecordSetValue(record, kABPersonFirstNameProperty,
                     (__bridge CFTypeRef)(contact.firstName), NULL);
  }

  if ([contact respondsToSelector:@selector(lastName)]) {
    ABRecordSetValue(record, kABPersonLastNameProperty,
                     (__bridge CFTypeRef)(contact.lastName), NULL);
  }

  if ([contact respondsToSelector:@selector(emails)]) {
    ABMutableMultiValueRef multiEmails =
        ABMultiValueCreateMutable(kABStringPropertyType);
    for (NSString *email in contact.emails) {
      ABMultiValueAddValueAndLabel(multiEmails, (__bridge CFTypeRef)(email),
                                   kABHomeLabel, NULL);
    }
    ABRecordSetValue(record, kABPersonEmailProperty, multiEmails, NULL);
  }

  if ([contact respondsToSelector:@selector(phoneNumbers)]) {
    ABMutableMultiValueRef multiPhones =
        ABMultiValueCreateMutable(kABStringPropertyType);
    for (NSString *phoneNumber in contact.phoneNumbers) {
      ABMultiValueAddValueAndLabel(
          multiPhones, (__bridge CFTypeRef)(phoneNumber), kABHomeLabel, NULL);
    }
    ABRecordSetValue(record, kABPersonPhoneProperty, multiPhones, NULL);
  }

  if (photo) {
    NSData *data = UIImagePNGRepresentation(photo);
    ABPersonSetImageData(record, (__bridge CFDataRef)data, NULL);
  }

  ABAddressBookAddRecord(self.addressBook, record, NULL);
  ABAddressBookSave(self.addressBook, NULL);

  if ([contact respondsToSelector:@selector(addressBookIDs)]) {
    NSNumber *recordID = @(ABRecordGetRecordID(record));
    contact.addressBookIDs = @[ recordID ];
  }
}

#pragma mark - Helpers

- (void)populateContact:(id<JLContact>)contact
           withArrayRef:(CFArrayRef)linkedArrayRef
              withCount:(NSUInteger)linkedCount {

  NSMutableSet *phoneNumbers = [NSMutableSet new];
  NSMutableSet *emails = [NSMutableSet new];
  NSMutableSet *addressBookIDs = [NSMutableSet new];

  for (NSUInteger i = 0; i < linkedCount; i++) {
    ABRecordRef recordRef = CFArrayGetValueAtIndex(linkedArrayRef, i);

    if ([contact respondsToSelector:@selector(setFirstName:)]) {
      if (!contact.firstName || [contact.firstName length] == 0) {
        contact.firstName = [self stringProperty:kABPersonFirstNameProperty
                                      fromRecord:recordRef];
        if (!contact.firstName) contact.firstName = @"";
      }
    }

    if ([contact respondsToSelector:@selector(setLastName:)]) {
      if (!contact.lastName || [contact.lastName length] == 0) {
        contact.lastName = [self stringProperty:kABPersonLastNameProperty
                                     fromRecord:recordRef];
        if (!contact.lastName) contact.lastName = @"";
      }
    }

    if ([contact respondsToSelector:@selector(setFullName:)]) {
      if (!contact.fullName || [contact.fullName length] == 0) {
        NSString *lastName = [self stringProperty:kABPersonLastNameProperty
                                       fromRecord:recordRef];

        NSString *firstName = [self stringProperty:kABPersonFirstNameProperty
                                        fromRecord:recordRef];

        if ([firstName length] > 0 && [lastName length] > 0) {
          contact.fullName =
              [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        } else if ([firstName length] > 0) {
          contact.fullName = firstName;
        } else if ([lastName length] > 0) {
          contact.fullName = lastName;
        } else {
          contact.fullName = @"NO NAME";
        }
      }
    }

    if ([contact respondsToSelector:@selector(setPhoneNumbers:)]) {
      NSArray *newPhones =
          [self arrayProperty:kABPersonPhoneProperty fromRecord:recordRef];
      [phoneNumbers addObjectsFromArray:newPhones];
    }

    if ([contact respondsToSelector:@selector(setEmails:)]) {
      NSArray *newEmails =
          [self arrayProperty:kABPersonEmailProperty fromRecord:recordRef];
      [emails addObjectsFromArray:newEmails];
    }

    NSNumber *recordID = @(ABRecordGetRecordID(recordRef));

    if ([contact respondsToSelector:@selector(addressBookIDs)]) {
      [addressBookIDs addObject:recordID];
    }

    if ([contact respondsToSelector:@selector(setPhoto:)]) {
      if (!contact.photo) {
        contact.photo = [self imagePropertyFromRecord:recordRef asThumbnail:NO];
      }
    }

    if ([contact respondsToSelector:@selector(setThumbnail:)]) {
      if (!contact.thumbnail) {
        contact.thumbnail =
            [self imagePropertyFromRecord:recordRef asThumbnail:YES];
      }
    }
  }

  if ([contact respondsToSelector:@selector(setPhoneNumbers:)] &&
      [phoneNumbers count] > 0) {
    contact.phoneNumbers = [self cleanPhoneNumbers:phoneNumbers];
  }

  if ([contact respondsToSelector:@selector(setEmails:)] &&
      [emails count] > 0) {
    contact.emails = [self cleanEmails:emails];
  }

  if ([contact respondsToSelector:@selector(setAddressBookIDs:)]) {
    contact.addressBookIDs = [addressBookIDs allObjects];
  }
}

- (NSArray *)cleanEmails:(NSSet *)emails {
  NSMutableSet *newEmails = [NSMutableSet new];
  for (NSString *email in emails) {
    [newEmails addObject:[email lowercaseString]];
  }
  return [newEmails allObjects];
}

- (NSArray *)cleanPhoneNumbers:(NSSet *)phoneNumbers {
  NSMutableSet *newPhoneNumbers = [NSMutableSet new];
  for (NSString *phoneNumber in phoneNumbers) {

    NSString *digitsOnly = [self.regex
        stringByReplacingMatchesInString:phoneNumber
                                 options:0
                                   range:NSMakeRange(0, [phoneNumber length])
                            withTemplate:@""];

    [newPhoneNumbers addObject:digitsOnly];
  }
  return [newPhoneNumbers allObjects];
}

- (UIImage *)imageAs:(BOOL)thumbnail forContact:(id<JLContact>)contact {
  if (!contact || ![JLAddressBook authorized] ||
      ![contact respondsToSelector:@selector(addressBookIDs)]) {
    return nil;
  }

  for (NSNumber *recordID in contact.addressBookIDs) {

    ABRecordRef recordRef =
        ABAddressBookGetPersonWithRecordID(self.addressBook, recordID.intValue);

    if (recordRef == NULL) continue;

    UIImage *image =
        [self imagePropertyFromRecord:recordRef asThumbnail:thumbnail];
    if (image) return image;
  }

  return nil;
}

- (NSString *)stringProperty:(ABPropertyID)property
                  fromRecord:(ABRecordRef)recordRef {
  CFTypeRef valueRef = (ABRecordCopyValue(recordRef, property));
  return (__bridge_transfer NSString *)valueRef;
}

- (NSArray *)arrayProperty:(ABPropertyID)property
                fromRecord:(ABRecordRef)recordRef {
  ABMultiValueRef multiValue = ABRecordCopyValue(recordRef, property);
  NSUInteger count = (NSUInteger)ABMultiValueGetCount(multiValue);
  NSMutableArray *array = [[NSMutableArray alloc] init];
  for (NSUInteger i = 0; i < count; i++) {
    CFTypeRef value = ABMultiValueCopyValueAtIndex(multiValue, i);
    NSString *string = (__bridge_transfer NSString *)value;
    if (string) {
      [array addObject:string];
    }
  }
  CFRelease(multiValue);
  return [NSArray arrayWithArray:array];
}

- (UIImage *)imagePropertyFromRecord:(ABRecordRef)recordRef
                         asThumbnail:(BOOL)asThumbnail {
  ABPersonImageFormat format = asThumbnail ? kABPersonImageFormatThumbnail
                                           : kABPersonImageFormatOriginalSize;
  NSData *data = (__bridge_transfer NSData *)ABPersonCopyImageDataWithFormat(
      recordRef, format);
  return (data) ? [UIImage imageWithData:data scale:UIScreen.mainScreen.scale]
                : nil;
}

@end
