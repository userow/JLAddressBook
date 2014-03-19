//
//  Contact.h
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/19/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Contact : NSManagedObject

@property (nonatomic, retain) id emails;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) id thumbnail;

@end
