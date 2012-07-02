//
//  TBTodoItem.h
//  Todoly
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with project for details.
//

#import <CloudMine/CloudMine.h>

@interface TBTodoItem : CMObject

@property (strong) NSString *text;
@property (strong) CMDate *deadline;
@property BOOL done;
@property int priority;

- (id)initWithText:(NSString *)text;

@end
