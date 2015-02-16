//
//  JLViewController.m
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/17/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "JLViewController.h"
#import "AddressBookContact+Extension.h"
#import "JLDataManager.h"
#import "JLAddressBook.h"
#import "JLCoreDataContactManager.h"

@interface JLViewController ()

@property(strong, nonatomic) JLAddressBook *addressBook;

@end

@implementation JLViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [JLAddressBook attemptToAuthorize:^(bool granted, NSError *error) {
      if (granted) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self loadData]; });
      } else {
        NSLog(@"User denied contact access %@", error);
      }
  }];
}

- (void)loadData {
  JLDataManager *dataManager = [JLDataManager sharedInstance];
  [dataManager reset];

  JLCoreDataContactManager *contactManager = [[JLCoreDataContactManager alloc]
      initWithEntityName:[AddressBookContact entityName]
               inContext:dataManager.managedObjectContext];

  self.addressBook =
      [[JLAddressBook alloc] initWithContactManager:contactManager];

  NSFetchRequest *request =
      [NSFetchRequest fetchRequestWithEntityName:[AddressBookContact entityName]];
  request.sortDescriptors = @[
    [NSSortDescriptor sortDescriptorWithKey:@"lastName"
                                  ascending:YES
                                   selector:@selector(caseInsensitiveCompare:)]
  ];

  self.fetchedResultsController = [[NSFetchedResultsController alloc]
      initWithFetchRequest:request
      managedObjectContext:dataManager.managedObjectContext
        sectionNameKeyPath:nil
                 cacheName:nil];

  [self.addressBook syncContacts];
  [dataManager save];
  [self.tableView reloadData];
}

#pragma mark - CoreDataTableViewController

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  UITableViewCell *cell =
      [self.tableView dequeueReusableCellWithIdentifier:@"ContactCell"
                                           forIndexPath:indexPath];

  AddressBookContact *contact =
      [self.fetchedResultsController objectAtIndexPath:indexPath];
  cell.textLabel.text = contact.fullName;
  cell.detailTextLabel.text = [contact.phoneNumbers componentsJoinedByString:@", "];
  [cell.imageView setImage:contact.thumbnail];
  return cell;
}

@end
