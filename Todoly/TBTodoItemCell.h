//
//  TBTodoItemCell.h
//  Todoly
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with project for details.
//

#import <UIKit/UIKit.h>

@interface TBTodoItemCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *priorityLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
