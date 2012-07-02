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
    
    // Prevents retain cycle
    __block TBLoginViewController *unretainedSelf = self;
    
    // Setup user operation callback
    userCallback = ^(CMUserAccountResult resultCode, NSArray *messages) {
        unretainedSelf.authenticating = NO;
        switch (resultCode) {
            // If the login succeded, notify the delegate
            case CMUserAccountLoginSucceeded:
                if ([unretainedSelf.delegate respondsToSelector:@selector(loginController:didSelectUser:)])
                    [unretainedSelf.delegate loginController:unretainedSelf didSelectUser:unretainedSelf.user];
                break;
            
            // If the login failed, clear the password field and alert the user
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add a pretty CloudMine logo to the top of the login view
    UIImageView *headerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cloudmine-clouds"]];
    headerView.frame = (CGRect){self.tableView.bounds.origin,{self.tableView.bounds.size.width, 88}};
    headerView.contentMode = UIViewContentModeScaleAspectFit;
    self.tableView.tableHeaderView = headerView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Register for text field change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
    
    // Make the first field, the username field, active
    [_usernameField becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated {
    // Unregister for text field change notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidDisappear:animated];
}

- (void)cancel {
    /*
     This is not an option currently (mandatory login), but if it was,
     this method could be called upon hitting cancel and the delegate
     would be notified
     */
    if ([_delegate respondsToSelector:@selector(loginControllerDidCancel:)])
        [_delegate loginControllerDidCancel:self];
}

- (void)login {
    if (!_user.userId.length || !_user.password.length)
        return;
    
    // Begin login process
    self.authenticating = YES;
    [_user loginWithCallback:userCallback];
}

- (void)createAccountAndLogin {
    if (!_user.userId.length || !_user.password.length)
        return;
    
    // Being user account creation and login process
    self.authenticating = YES;
    [_user createAccountAndLoginWithCallback:userCallback];
}

- (void)setAuthenticating:(BOOL)authenticating {
    /*
     Makes interface changes when attempting to authenticate.
     One could activate an UIActivityView, for example, here.
     */
    UIApplication *application = [UIApplication sharedApplication];
    if (authenticating) {
        [application beginIgnoringInteractionEvents];
    } else {
        [application endIgnoringInteractionEvents];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:_usernameField])
        // Go to the password field if in the username field
        [_passwordField becomeFirstResponder];
    else if ([textField isEqual:_passwordField])
        // And attempt to login if in the password field
        [self login];
    
    return NO;
}

- (void)textFieldDidChange:(NSNotification *)notification {
    UITextField *textField = (UITextField *)[notification object];
    
    // Update the user property as the text fields change
    if ([textField isEqual:_usernameField])
        _user.userId = _usernameField.text;
    else if ([textField isEqual:_passwordField])
        _user.password = _passwordField.text;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // If the user selects the login button
    if ([[tableView cellForRowAtIndexPath:indexPath] isEqual:_loginCell])
        [self login];
    
    // If the user selects the create account button
    if ([[tableView cellForRowAtIndexPath:indexPath] isEqual:_createAccountCell])
        [self createAccountAndLogin];
}

@end
