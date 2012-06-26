//
//  TBLoginViewController.m
//  Todoly
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with project for details.
//

#import "TBLoginViewController.h"

@interface TBLoginViewController () {
    __strong CMUserOperationCallback userCallback;
}
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITableViewCell *loginCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *createAccountCell;

- (void)login;
- (void)createAccountAndLogin;
@end

@implementation TBLoginViewController

@synthesize user = _user;
@synthesize delegate = _delegate;
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize loginCell = _loginCell;
@synthesize createAccountCell = _createAccountCell;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Setup user operation callback
    __block TBLoginViewController *unretainedSelf = self;
    userCallback = ^(CMUserAccountResult resultCode, NSArray *messages) {
        unretainedSelf.authenticating = NO;
        switch (resultCode) {
            case CMUserAccountLoginSucceeded:
                if ([unretainedSelf.delegate respondsToSelector:@selector(loginController:didSelectUser:)])
                    [unretainedSelf.delegate loginController:unretainedSelf didSelectUser:unretainedSelf.user];
                break;
                
            case CMUserAccountLoginFailedIncorrectCredentials: {
                unretainedSelf.passwordField.text = nil;
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your username or password was incorrect" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                [errorAlert show];
                break;
            }
                
            default:
                break;
        }
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
    
    [_usernameField becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated {    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidDisappear:animated];
}

- (void)cancel {
    if ([_delegate respondsToSelector:@selector(loginControllerDidCancel:)])
        [_delegate loginControllerDidCancel:self];
}

- (void)login {
    if (!_user.userId.length || !_user.password.length)
        return;
    
    self.authenticating = YES;
    [_user loginWithCallback:userCallback];
}

- (void)createAccountAndLogin {
    if (!_user.userId.length || !_user.password.length)
        return;
    
    self.authenticating = YES;
    [_user createAccountAndLoginWithCallback:userCallback];
}

- (void)setAuthenticating:(BOOL)authenticating {
    UIApplication *application = [UIApplication sharedApplication];
    if (authenticating) {
        [application beginIgnoringInteractionEvents];
    } else {
        [application endIgnoringInteractionEvents];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:_usernameField])
        [_passwordField becomeFirstResponder];
    else if ([textField isEqual:_passwordField])
        [self login];
    
    return NO;
}

- (void)textFieldDidChange:(NSNotification *)notification {
    UITextField *textField = (UITextField *)[notification object];
    
    if ([textField isEqual:_usernameField])
        _user.userId = _usernameField.text;
    else if ([textField isEqual:_passwordField])
        _user.password = _passwordField.text;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([[tableView cellForRowAtIndexPath:indexPath] isEqual:_loginCell])
        [self login];
    
    if ([[tableView cellForRowAtIndexPath:indexPath] isEqual:_createAccountCell])
        [self createAccountAndLogin];
}

@end
