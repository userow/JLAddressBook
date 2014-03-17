//
//  JLViewController.m
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/17/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

#import "JLViewController.h"
#import "Contact+Extension.h"
#import "ContactManager.h"
#import "JLAddressBook.h"

@interface JLViewController ()

@property(strong, nonatomic) ContactManager *contactManager;
@property(strong, nonatomic) JLAddressBook *addressBook;

@end

@implementation JLViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.contactManager = [ContactManager sharedInstance];
  self.addressBook =
      [[JLAddressBook alloc] initWithContactManager:self.contactManager];

  NSFetchRequest *request =
      [NSFetchRequest fetchRequestWithEntityName:[Contact entityName]];
  request.sortDescriptors = @[
    [NSSortDescriptor sortDescriptorWithKey:@"lastName"
                                  ascending:NO
                                   selector:@selector(compare:)]
  ];

  self.fetchedResultsController = [[NSFetchedResultsController alloc]
      initWithFetchRequest:request
      managedObjectContext:self.contactManager.managedObjectContext
        sectionNameKeyPath:nil
                 cacheName:nil];

  [self.addressBook attemptToAuthorize:^(bool granted, NSError *error) {
      if (granted) {
        [self.addressBook syncContactsAndThen:^{
            dispatch_async(dispatch_get_main_queue(),
                           ^{ [self.tableView reloadData]; });
        }];
      } else {
        NSLog(@"User denied contact access %@", error);
      }
  }];
}

#pragma mark - CoreDataTableViewController

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  UITableViewCell *cell =
      [self.tableView dequeueReusableCellWithIdentifier:@"ContactCell"
                                           forIndexPath:indexPath];

  Contact *contact =
      [self.fetchedResultsController objectAtIndexPath:indexPath];
  cell.textLabel.text = contact.fullName;
  cell.detailTextLabel.text = [contact.emails firstObject];
  return cell;
}

@end
