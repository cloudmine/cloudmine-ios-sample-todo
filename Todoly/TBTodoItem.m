//
//  TBTodoItem.m
//  Todoly
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with project for details.
//

#import "TBTodoItem.h"

@implementation TBTodoItem

@synthesize text = _text;
@synthesize deadline = _deadline;
@synthesize done = _done;
@synthesize priority = _priority;
@synthesize location = _location;
@synthesize picture = _picture;

- (id)initWithText:(NSString *)text {
    if(self = [super init]) {
        self.text = text;
        self.deadline = [[CMDate alloc] initWithDate:[NSDate date]];
        self.priority = 2;
        self.done = NO;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder]) {
        self.text = [coder decodeObjectForKey:@"text"];
        self.deadline = [coder decodeObjectForKey:@"deadline"];
        self.done = [coder decodeBoolForKey:@"done"];
        self.priority = [coder decodeIntForKey:@"priority"];
        self.location = [coder decodeObjectForKey:@"location"];
        self.picture = [coder decodeObjectForKey:@"picture"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:_text forKey:@"text"];
    [coder encodeObject:_deadline forKey:@"deadline"];
    [coder encodeBool:_done forKey:@"done"];
    [coder encodeInt:_priority forKey:@"priority"];
    [coder encodeObject:_location forKey:@"location"];
    [coder encodeObject:_picture forKey:@"picture"];
}



@end
