//
//  JLCoreDataContactManager.h
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/19/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "JLContact.h"
#import "JLContactManager.h"
@import Foundation;

@interface JLCoreDataContactManager : NSObject<JLContactManager>

- (instancetype)initWithEntityName:(NSString *)entityName
                         inContext:(NSManagedObjectContext *)context;

@end
