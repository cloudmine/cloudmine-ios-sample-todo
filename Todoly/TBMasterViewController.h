//
//  TBMasterViewController.h
//  Todoly
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with project for details.
//

#import <UIKit/UIKit.h>

#import "TBLoginViewController.h"
#import "TBDetailViewController.h"

#import "PullToRefreshView.h"

@interface TBMasterViewController : UITableViewController <TBLoginViewControllerDelegate, TBDetailViewControllerDelegate, PullToRefreshViewDelegate>

@property (strong, nonatomic) CMUser *user;

@end
