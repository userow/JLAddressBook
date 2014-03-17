//
//  ContactManager.h
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/17/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JLAddressBook.h"

@interface ContactManager : NSObject<JLContactManager>

+ (ContactManager *)sharedInstance;

@property(strong, nonatomic, readonly)
    NSManagedObjectContext *managedObjectContext;

@end
