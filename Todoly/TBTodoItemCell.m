//
//  TBTodoItemCell.m
//  Todoly
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with project for details.
//

#import "TBTodoItemCell.h"

@interface TBTodoItemCell ()
@property (weak, nonatomic) IBOutlet UIImageView *priorityView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@end

static __strong NSArray *priorityImages;

@implementation TBTodoItemCell

@synthesize todoItem = _todoItem;
@synthesize priorityView = _priorityView;
@synthesize titleLabel = _titleLabel;

+ (void)load {
    priorityImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"priority-red"], [UIImage imageNamed:@"priority-yellow"], [UIImage imageNamed:@"priority-green"], nil];
}

- (void)setTodoItem:(TBTodoItem *)todoItem {
    _todoItem = todoItem;
    
    self.priorityView.image = [priorityImages objectAtIndex:(todoItem.priority - 1)];
    self.titleLabel.text = _todoItem.text;
    self.accessoryType = _todoItem.done ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;    
}

@end
