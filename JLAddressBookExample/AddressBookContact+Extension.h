//
//  AddressBookContact+Extension.h
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/17/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "AddressBookContact.h"
#import "JLContact.h"

@interface ImageToDataTransformer : NSValueTransformer

@end

@interface AddressBookContact (Extension)<JLContact>

+ (NSString *)entityName;

- (NSString *)fullName;

@end
