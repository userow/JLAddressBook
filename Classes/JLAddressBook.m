//
//  JLAddressBook.m
//  Joseph Laws
//
//  Created by Joseph Laws on 3/7/14.
//  Copyright (c) 2014 Joseph Laws. All rights reserved.
//

#import "JLAddressBook.h"
#import "DDLog.h"
@import AddressBook;

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF JLAddressBookLogLevel

#ifdef DEBUG
static const int JLAddressBookLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int JLAddressBookLogLevel = LOG_LEVEL_ERROR;
#endif

@interface JLAddressBook ()
@property(nonatomic, strong) NSRegularExpression *regex;
@property(nonatomic, strong) id<JLContactManager> contactFactory;
@end

@implementation JLAddressBook

+ (NSOperationQueue *)queue {

  static NSOperationQueue *_instance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
      _instance = [[NSOperationQueue alloc] init];
      _instance.maxConcurrentOperationCount = 1;
  });

  return _instance;
}

- (instancetype)initWithContactFactory:(id<JLContactManager>)contactFactory {
  self = [super init];
  if (self) {
    NSError *error = nil;
    self.regex = [NSRegularExpression
        regularExpressionWithPattern:@"[^\\d]"
                             options:NSRegularExpressionCaseInsensitive
                               error:&error];
    if (error) {
      self = nil;
      return nil;
    }
    self.contactFactory = contactFactory;
  }
  return self;
}

- (void)dealloc {
}

- (BOOL)authorized {
  return ABAddressBookGetAuthorizationStatus() ==
         kABAuthorizationStatusAuthorized;
}
- (void)attemptToAuthorize:(AuthorizationBlock)block {
  ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();

  switch (status) {
    case kABAuthorizationStatusAuthorized: {
      block(true, nil);
    } break;
    case kABAuthorizationStatusNotDetermined: {
      ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
      ABAddressBookRequestAccessWithCompletion(
          addressBook, ^(bool granted, CFErrorRef error) {
              CFRelease(addressBook);
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

- (UIImage *)photoForContact:(id<JLContact>)contact {
  return [self imageAs:NO forContact:contact];
}

- (UIImage *)thumbnailForContact:(id<JLContact>)contact {
  return [self imageAs:YES forContact:contact];
}

- (void)syncContacts {
  [[JLAddressBook queue]
      addOperationWithBlock:^{ [self syncContactsAndWait]; }];
}

- (void)syncContactsAndThen:(SyncBlock)b {
  __strong SyncBlock block = b;
  [[JLAddressBook queue] addOperationWithBlock:^{
      [self syncContactsAndWait];
      block();
  }];
}

- (void)addContactToDevice:(id<JLContact>)contact {
  [self addContactToDevice:contact withPhoto:nil];
}

- (void)addContactToDevice:(id<JLContact>)contact withPhoto:(UIImage *)photo {
  DDLogInfo(@"Adding contact to device %@", contact);

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

  ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
  ABAddressBookAddRecord(addressBook, record, NULL);
  ABAddressBookSave(addressBook, NULL);
  CFRelease(addressBook);

  if ([contact respondsToSelector:@selector(addressBookIDs)]) {
    NSNumber *recordID = @(ABRecordGetRecordID(record));
    contact.addressBookIDs = @[ recordID ];
  }
}

#pragma mark - Helpers

- (void)syncContactsAndWait {
  if (![self authorized]) return;

  NSArray *existingContacts = self.contactFactory.existingContacts;

  ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
  CFArrayRef peopleArrayRef = ABAddressBookCopyArrayOfAllPeople(addressBook);
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
      } else if ([self.contactFactory saveToDevice]) {
        [self addContactToDevice:contact];
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
      DDLogInfo(@"Creating a new contact from %ul linked contacts",
                linkedCount);
      contact = [self.contactFactory newContact];
      [self populateContact:contact
               withArrayRef:linkedArrayRef
                  withCount:linkedCount];
    } else {
      DDLogInfo(@"Adding %ul linked contacts to an existing contact",
                linkedCount);
      [self populateContact:contact
               withArrayRef:linkedArrayRef
                  withCount:linkedCount];
    }

    CFRelease(linkedArrayRef);

    [contacts addObject:contact];
  }

  CFRelease(peopleArrayRef);
  CFRelease(addressBook);

  [self.contactFactory contactsUpdated:contacts];
}

- (void)populateContact:(id<JLContact>)contact
           withArrayRef:(CFArrayRef)linkedArrayRef
              withCount:(NSUInteger)linkedCount {

  NSMutableSet *phoneNumbers = [NSMutableSet new];
  NSMutableSet *emails = [NSMutableSet new];
  NSMutableSet *addressBookIDs = [NSMutableSet new];

  for (NSUInteger i = 0; i < linkedCount; i++) {
    ABRecordRef recordRef = CFArrayGetValueAtIndex(linkedArrayRef, i);

    if ([contact respondsToSelector:@selector(firstName)]) {
      if (!contact.firstName || [contact.firstName length] == 0) {
        contact.firstName = [self stringProperty:kABPersonFirstNameProperty
                                      fromRecord:recordRef];
        if (!contact.firstName) contact.firstName = @"";
      }
    }

    if ([contact respondsToSelector:@selector(lastName)]) {
      if (!contact.lastName || [contact.lastName length] == 0) {
        contact.lastName = [self stringProperty:kABPersonLastNameProperty
                                     fromRecord:recordRef];
        if (!contact.lastName) contact.lastName = @"";
      }
    }

    if ([contact respondsToSelector:@selector(phoneNumbers)]) {
      NSArray *newPhones =
          [self arrayProperty:kABPersonPhoneProperty fromRecord:recordRef];
      [phoneNumbers addObjectsFromArray:newPhones];
    }

    if ([contact respondsToSelector:@selector(emails)]) {
      NSArray *newEmails =
          [self arrayProperty:kABPersonEmailProperty fromRecord:recordRef];
      [emails addObjectsFromArray:newEmails];
    }

    NSNumber *recordID = @(ABRecordGetRecordID(recordRef));

    if ([contact respondsToSelector:@selector(addressBookIDs)]) {
      [addressBookIDs addObject:recordID];
    }

    if ([contact respondsToSelector:@selector(photo)]) {
      if (!contact.photo) {
        contact.photo = [self imagePropertyFromRecord:recordRef asThumbnail:NO];
      }
    }

    if ([contact respondsToSelector:@selector(thumbnail)]) {
      if (!contact.thumbnail) {
        contact.thumbnail =
            [self imagePropertyFromRecord:recordRef asThumbnail:YES];
      }
    }
  }

  if ([contact respondsToSelector:@selector(phoneNumbers)]) {
    contact.phoneNumbers = [self cleanPhoneNumbers:phoneNumbers];
  }

  if ([contact respondsToSelector:@selector(emails)]) {
    contact.emails = [self cleanEmails:emails];
  }

  if ([contact respondsToSelector:@selector(addressBookIDs)]) {
    contact.addressBookIDs = [addressBookIDs asArray];
  }
}

- (NSArray *)cleanEmails:(NSSet *)emails {
  NSMutableSet *newEmails = [NSMutableSet new];
  for (NSString *email in emails) {
    [newEmails addObject:[email lowercaseString]];
  }
  return [newEmails asArray];
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
  return [newPhoneNumbers asArray];
}

- (UIImage *)imageAs:(BOOL)thumbnail forContact:(id<JLContact>)contact {
  if (![self authorized] ||
      ![contact respondsToSelector:@selector(addressBookIDs)]) {
    return nil;
  }

  ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);

  for (NSNumber *recordID in contact.addressBookIDs) {

    ABRecordRef recordRef =
        ABAddressBookGetPersonWithRecordID(addressBook, recordID.intValue);

    if (recordRef == NULL) continue;

    UIImage *image =
        [self imagePropertyFromRecord:recordRef asThumbnail:thumbnail];
    if (image) return image;
  }
  CFRelease(addressBook);

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
