//
//  JLDataManager.h
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/17/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JLAddressBook.h"

@interface JLDataManager : NSObject

+ (JLDataManager *)sharedInstance;
- (void)reset;
- (void)save;

@property(strong, nonatomic, readonly)
    NSManagedObjectContext *managedObjectContext;
@property(strong, nonatomic, readonly) id<JLContactManager> contactManager;

@end
