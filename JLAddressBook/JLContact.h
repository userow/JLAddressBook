//
//  JLContact.h
//  JLAddressBookExample
//
//  Created by Joseph Laws on 3/19/14.
//  Copyright (c) 2014 Joe Laws. All rights reserved.
//

@import Foundation;

@protocol JLContact<NSObject>

@optional

@property(nonatomic, strong) NSString *firstName;
@property(nonatomic, strong) NSString *lastName;
@property(nonatomic, strong) NSString *fullName;
@property(nonatomic, strong) NSArray *phoneNumbers;    // NSString's
@property(nonatomic, strong) NSArray *emails;          // NSString's
@property(nonatomic, strong) NSArray *addressBookIDs;  // NSNumbers's
@property(nonatomic, strong) UIImage *thumbnail;
@property(nonatomic, strong) UIImage *photo;

@end