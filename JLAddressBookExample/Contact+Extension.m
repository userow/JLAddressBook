//
//  Contact+Extension.m
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/17/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "Contact+Extension.h"

@implementation Contact (Extension)

+ (NSString *)entityName {
  return @"Contact";
}

+ (instancetype)insertNewObjectInContext:(NSManagedObjectContext *)context {
  __block Contact *contact;
  [context performBlockAndWait:^{
      contact =
          [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
                                        inManagedObjectContext:context];
  }];
  return contact;
}

- (NSString *)fullName {
  if ([self.firstName length] > 0 && [self.lastName length] > 0) {
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
  } else if ([self.firstName length] > 0) {
    return self.firstName;
  } else if ([self.lastName length] > 0) {
    return self.lastName;
  } else {
    return @"NO NAME";
  }
}

@end
