//
//  ContactManager.m
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/17/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "ContactManager.h"
#import "Contact+Extension.h"

@interface ContactManager ()

@property(strong, nonatomic, readwrite)
    NSManagedObjectContext *managedObjectContext;

@end

@implementation ContactManager

+ (ContactManager *)sharedInstance {
  static ContactManager *_instance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{ _instance = [[ContactManager alloc] init]; });

  return _instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSManagedObjectContext *privateWritingContext =
        [[NSManagedObjectContext alloc]
            initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateWritingContext.persistentStoreCoordinator = [self coordinator];

    if (privateWritingContext.persistentStoreCoordinator) {
      self.managedObjectContext = [[NSManagedObjectContext alloc]
          initWithConcurrencyType:NSMainQueueConcurrencyType];
      self.managedObjectContext.parentContext = privateWritingContext;
    } else {
      return nil;
    }
  }
  return self;
}

- (void)setupManagedObjectContext {
}

- (NSPersistentStoreCoordinator *)coordinator {
  NSPersistentStoreCoordinator *coordinator =
      [[NSPersistentStoreCoordinator alloc]
          initWithManagedObjectModel:[self model]];
  NSError *error;
  [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                            configuration:nil
                                      URL:[self storeURL]
                                  options:nil
                                    error:&error];
  if (error) {
    return nil;
  }
  return coordinator;
}

- (NSManagedObjectModel *)model {
  NSURL *modelURL =
      [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Model"
                                                             ofType:@"momd"]];

  NSManagedObjectModel *managedObjectModel =
      [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  return managedObjectModel;
}

- (NSURL *)storeURL {

  NSURL *documentsDirectory =
      [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                             inDomain:NSUserDomainMask
                                    appropriateForURL:nil
                                               create:YES
                                                error:NULL];
  return [documentsDirectory
      URLByAppendingPathComponent:@"JLAddressBookExample.sqlite"];
}

#pragma mark - JLContactManager

- (id<JLContact>)newContact {
  return [Contact insertNewObjectInContext:self.managedObjectContext];
}

- (void)contactsUpdated:(NSArray *)contacts {
  NSLog(@"Found %d contacts", [contacts count]);
}

- (NSArray *)existingContacts {
  NSFetchRequest *request =
      [NSFetchRequest fetchRequestWithEntityName:[Contact entityName]];

  return [self performFetch:request];
}

- (BOOL)saveToDevice {
  return false;
}

#pragma mark - Helpers

- (NSArray *)performFetch:(NSFetchRequest *)request {
  [request setReturnsObjectsAsFaults:false];

  NSManagedObjectContext *managedObjectContext = self.managedObjectContext;

  __block NSArray *results;
  [managedObjectContext performBlockAndWait:^{
      NSError *error = nil;

      results = [managedObjectContext executeFetchRequest:request error:&error];

      if (error) {
        NSLog(@"Error %@ while fetching %@ ", [error description],
                   request);
      }
  }];
  return results;
}

@end
