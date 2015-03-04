//
//  TBLoginViewController.h
//  Todoly
//
//  Copyright (c) 2015 CloudMine, Inc. All rights reserved.
//  See LICENSE file included with project for details.
//

#import <UIKit/UIKit.h>
#import "CloudMine.h"

@protocol TBLoginViewControllerDelegate;

@interface TBLoginViewController : UITableViewController <UITextFieldDelegate>

@property (weak, nonatomic) id<TBLoginViewControllerDelegate> delegate;
@property (strong, nonatomic) CMUser *user;

@end

@protocol TBLoginViewControllerDelegate <NSObject>
@optional
- (void)loginController:(TBLoginViewController *)controller didSelectUser:(CMUser *)user;
- (void)loginControllerDidCancel:(TBLoginViewController *)controller;
@end