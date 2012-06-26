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
    
    _titleField.text = _item.text;
    _priorityControl.selectedSegmentIndex = _item.priority - 1;
    _deadlinePicker.date = _item.deadline;
}

- (IBAction)deadlinePickerChanged:(id)sender {
    if (![sender isEqual:_deadlinePicker])
        return;
    
    CMDate *previousDeadline = _item.deadline;
    _item.deadline = [[CMDate alloc] initWithDate:_deadlinePicker.date];
    
    if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
        [_delegate detailController:self didModifyItem:self.item];
    
    [_item save:^(CMObjectUploadResponse *response) {
        if (![[response.uploadStatuses objectForKey:_item.objectId] isEqualToString:@"updated"]) {
            NSString *message = @"The item could not be updated.";
            if (response.error)
                message = [response.error localizedDescription];
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [errorAlert show];
            
            _deadlinePicker.date = _item.deadline = previousDeadline;
            
            if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
                [_delegate detailController:self didModifyItem:self.item];
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
    
    NSString *previousTitle = _item.text;
    _item.text = _titleField.text;
    
    if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
        [_delegate detailController:self didModifyItem:self.item];
    
    [_item save:^(CMObjectUploadResponse *response) {
        if (![[response.uploadStatuses objectForKey:_item.objectId] isEqualToString:@"updated"]) {
            NSString *message = @"The item could not be updated.";
            if (response.error)
                message = [response.error localizedDescription];
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [errorAlert show];
            
            _titleField.text = _item.text = previousTitle;
            
            if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
                [_delegate detailController:self didModifyItem:self.item];
        }
    }];
}

- (IBAction)priorityControlChanged:(id)sender {
    if (![sender isEqual:_priorityControl])
        return;
        
    int previousPriority = _item.priority;
    _item.priority = _priorityControl.selectedSegmentIndex + 1;
    
    if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
        [_delegate detailController:self didModifyItem:self.item];
    
    [_item save:^(CMObjectUploadResponse *response) {
        if (![[response.uploadStatuses objectForKey:_item.objectId] isEqualToString:@"updated"]) {
            NSString *message = @"The item could not be updated.";
            if (response.error)
                message = [response.error localizedDescription];
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [errorAlert show];
            
            _item.priority = previousPriority;
            _priorityControl.selectedSegmentIndex = previousPriority - 1;
            
            if ([_delegate respondsToSelector:@selector(detailController:didModifyItem:)])
                [_delegate detailController:self didModifyItem:self.item];
        }
    }];
}

@end
