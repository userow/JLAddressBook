//
//  JLDataManager.m
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/17/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "JLDataManager.h"
@import CoreData;

@interface JLDataManager ()

@property(strong, nonatomic, readwrite)
    NSManagedObjectContext *managedObjectContext;
@property(strong, nonatomic) NSPersistentStore *persistentStore;

@end

@implementation JLDataManager

+ (JLDataManager *)sharedInstance {
  static JLDataManager *_instance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{ _instance = [[JLDataManager alloc] init]; });

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
      [self.managedObjectContext setMergePolicy:NSOverwriteMergePolicy];
    } else {
      return nil;
    }
  }
  return self;
}

- (void)reset {
  NSLog(@"Resetting persistent store");

  NSPersistentStoreCoordinator *coordinator =
      self.managedObjectContext.parentContext.persistentStoreCoordinator;

  [coordinator removePersistentStore:self.persistentStore error:nil];

  NSError *error;

  [[NSFileManager defaultManager] removeItemAtURL:[self storeURL] error:&error];

  self.persistentStore =
      [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                configuration:nil
                                          URL:[self storeURL]
                                      options:nil
                                        error:&error];
}

- (void)save {
  if (![self.managedObjectContext save:nil]) {
    NSLog(@"Could not save context");
  } else {
    [self.managedObjectContext.parentContext performBlock:^{
        if (![self.managedObjectContext.parentContext save:nil]) {
          NSLog(@"Could not save parent context");
        }
    }];
  }
}

- (NSPersistentStoreCoordinator *)coordinator {
  NSPersistentStoreCoordinator *coordinator =
      [[NSPersistentStoreCoordinator alloc]
          initWithManagedObjectModel:[self model]];
  NSError *error;
  self.persistentStore =
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

@end
