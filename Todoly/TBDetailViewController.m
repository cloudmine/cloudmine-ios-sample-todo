//
//  TBDetailViewController.m
//  Todoly
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with project for details.
//

#import "TBDetailViewController.h"

@implementation TBDetailViewController

@synthesize delegate = _delegate;
@synthesize item = _item;
@synthesize deadlinePicker = _deadlinePicker;
@synthesize titleField = _titleField;
@synthesize priorityControl = _priorityControl;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Load initial view state from item
    _titleField.text = _item.text;
    _priorityControl.selectedSegmentIndex = _item.priority - 1;
    _deadlinePicker.date = _item.deadline;
}

- (IBAction)deadlinePickerChanged:(id)sender {
    if (![sender isEqual:_deadlinePicker])
        return;
    
    // Update item from date picker
    CMDate *previousDeadline = _item.deadline;
    _item.deadline = [[CMDate alloc] initWithDate:_deadlinePicker.date];
    
    if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
        [_delegate detailController:self didModifyItem:self.item];
    
    // Update the item in CloudMine's object store
    [_item save:^(CMObjectUploadResponse *response) {
        // If the item was *not* successfully updated, fix the mess
        if (![[response.uploadStatuses objectForKey:_item.objectId] isEqualToString:@"updated"]) {
            
            // Revert the date picker and item
            _deadlinePicker.date = _item.deadline = previousDeadline;
            
            if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
                [_delegate detailController:self didModifyItem:self.item];
            
            // Alert the user
            NSString *message = @"The item could not be updated.";
            if (response.error)
                message = [response.error localizedDescription];
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [errorAlert show];
        }
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)titleFieldChanged:(id)sender {
    if (![sender isEqual:_titleField])
        return;
    
    // Update item from title text field
    NSString *previousTitle = _item.text;
    _item.text = _titleField.text;
    
    if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
        [_delegate detailController:self didModifyItem:self.item];
    
    // Update the item in CloudMine's object store
    [_item save:^(CMObjectUploadResponse *response) {
        // If the item was *not* successfully updated, fix the mess
        if (![[response.uploadStatuses objectForKey:_item.objectId] isEqualToString:@"updated"]) {
            
            // Revert the text field and item
            _titleField.text = _item.text = previousTitle;
            
            if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
                [_delegate detailController:self didModifyItem:self.item];
            
            // Alert the user
            NSString *message = @"The item could not be updated.";
            if (response.error)
                message = [response.error localizedDescription];
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [errorAlert show];
        }
    }];
}

- (IBAction)priorityControlChanged:(id)sender {
    if (![sender isEqual:_priorityControl])
        return;
    
    // Update item from priority control
    int previousPriority = _item.priority;
    _item.priority = _priorityControl.selectedSegmentIndex + 1;
    
    if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
        [_delegate detailController:self didModifyItem:self.item];
    
    // Update the item in CloudMine's object store
    [_item save:^(CMObjectUploadResponse *response) {
        // If the item was *not* successfully updated, fix the mess
        if (![[response.uploadStatuses objectForKey:_item.objectId] isEqualToString:@"updated"]) {
            
            // Revert the priority control and item
            _item.priority = previousPriority;
            _priorityControl.selectedSegmentIndex = previousPriority - 1;
            
            if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
                [_delegate detailController:self didModifyItem:self.item];
            
            // Alert the user
            NSString *message = @"The item could not be updated.";
            if (response.error)
                message = [response.error localizedDescription];
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [errorAlert show];
        }
    }];
}

@end
