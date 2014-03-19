//
//  Contact+Extension.h
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/17/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "Contact.h"
#import "JLContact.h"

@interface ImageToDataTransformer : NSValueTransformer

@end

@interface Contact (Extension)<JLContact>

+ (NSString *)entityName;

- (NSString *)fullName;

@end
