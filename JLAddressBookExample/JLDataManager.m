//
//  JLDataManager.m
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/17/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "JLDataManager.h"
#import "Contact+Extension.h"
#import "JLCoreDataContactManager.h"

@interface JLDataManager ()

@property(strong, nonatomic, readwrite)
    NSManagedObjectContext *managedObjectContext;
@property(strong, nonatomic, readwrite) id<JLContactManager> contactManager;

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
    } else {
      return nil;
    }
    self.contactManager = [[JLCoreDataContactManager alloc]
        initWithEntityName:[Contact entityName]
                 inContext:self.managedObjectContext];
  }
  return self;
}

- (void)reset {
  [self.managedObjectContext reset];
}

- (void)save {
  [self.managedObjectContext save:NULL];
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

@end
