//
//  TBMasterViewController.h
//  Todoly
//
//  Copyright (c) 2015 CloudMine, Inc. All rights reserved.
//  See LICENSE file included with project for details.
//

#import <UIKit/UIKit.h>

#import "TBLoginViewController.h"
#import "TBDetailViewController.h"

@interface TBMasterViewController : UITableViewController <TBLoginViewControllerDelegate, TBDetailViewControllerDelegate>

@property (strong, nonatomic) CMUser *user;

@end
