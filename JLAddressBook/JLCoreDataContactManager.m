//
//  JLCoreDataContactManager.m
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/19/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "JLCoreDataContactManager.h"
#import "JLAddressBook.h"
@import CoreData;

@interface JLCoreDataContactManager ()
@property(strong, nonatomic) NSString *entityName;
@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end

@implementation JLCoreDataContactManager

- (instancetype)initWithEntityName:(NSString *)entityName
                         inContext:(NSManagedObjectContext *)context {
  self = [super init];

  if (self) {
    self.entityName = entityName;
    self.managedObjectContext = context;
  }
  return self;
}

- (id<JLContact>)newContact {
  return [NSEntityDescription
      insertNewObjectForEntityForName:self.entityName
               inManagedObjectContext:self.managedObjectContext];
}

- (NSArray *)existingContacts {
  NSFetchRequest *request =
      [NSFetchRequest fetchRequestWithEntityName:self.entityName];

  NSError *error;

  NSArray *results =
      [self.managedObjectContext executeFetchRequest:request error:&error];

  if (error) {
    NSLog(@"Error %@ while fetching %@ ", [error description], request);
  }
  return results;
}

@end
