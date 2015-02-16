//
//  Contact.h
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/19/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AddressBookContact : NSManagedObject

@property (nonatomic, retain) id emails;
@property (nonatomic, retain) id phoneNumbers;
@property (nonatomic, retain) id phoneNumberTypes;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) id thumbnail;

@end
