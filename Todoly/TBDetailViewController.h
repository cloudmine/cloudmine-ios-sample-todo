//
//  TBDetailViewController.h
//  Todoly
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with project for details.
//

#import <UIKit/UIKit.h>

#import "TBTodoItem.h"

@protocol TBDetailViewControllerDelegate;

@interface TBDetailViewController : UITableViewController <UITextFieldDelegate>

@property (weak, nonatomic) id<TBDetailViewControllerDelegate> delegate;
@property (strong, nonatomic) TBTodoItem *item;

@end

@protocol TBDetailViewControllerDelegate <NSObject>
@optional
- (void)detailController:(TBDetailViewController *)controller didModifyItem:(TBTodoItem *)item;
@end