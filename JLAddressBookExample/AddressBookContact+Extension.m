//
//  AddressBookContact+Extension.m
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/17/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "AddressBookContact+Extension.h"

@implementation AddressBookContact (Extension)

+ (NSString *)entityName {
  return @"AddressBookContact";
}

- (NSString *)fullName {
  if ([self.firstName length] > 0 && [self.lastName length] > 0) {
    return [NSString stringWithFormat:@"%@, %@", self.lastName, self.firstName];
  } else if ([self.firstName length] > 0) {
    return self.firstName;
  } else if ([self.lastName length] > 0) {
    return self.lastName;
  } else {
    return @"NO NAME";
  }
}

@end

@implementation ImageToDataTransformer

+ (BOOL)allowsReverseTransformation {
  return YES;
}

+ (Class)transformedValueClass {
  return [NSData class];
}

- (id)transformedValue:(id)value {
  return UIImagePNGRepresentation(value);
}

- (id)reverseTransformedValue:(id)value {
  return [[UIImage alloc] initWithData:value];
}

@end