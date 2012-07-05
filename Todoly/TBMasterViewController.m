//
//  TBMasterViewController.m
//  Todoly
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with project for details.
//

#import "TBMasterViewController.h"

#import "TBTodoItem.h"
#import "TBTodoItemCell.h"

@interface TBMasterViewController () {
    __strong PullToRefreshView *_pull;

    __strong NSMutableArray *_items;
    __strong NSDate *_refreshedDate;
}
- (void)reloadData;
- (void)sortItems;
@end

@implementation TBMasterViewController

@synthesize user = _user;

- (void)loadView {
    [super loadView];
    
    // Load the pull-to-refresh view
    _pull = [[PullToRefreshView alloc] initWithScrollView:self.tableView];
    [_pull setDelegate:self];
    [self.tableView addSubview:_pull];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set up the buttons on the navigation bar
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewItem:)];
    
    if (!self.user.isLoggedIn)
        // If the user is not logged in, prompt them to do so
        [self performSegueWithIdentifier:@"Login" sender:self];
    else
        // If they are logged in, begin the initial refresh
        [self reloadData];
}

- (void)viewDidUnload {
    [_pull containingViewDidUnload];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Login

- (void)loginController:(TBLoginViewController *)controller didSelectUser:(CMUser *)user {
    // If a user is logd, re-set the user property (saving it), and reload data
    self.user = user;
    [self reloadData];
    
    // Dismiss the login controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (CMUser *)user {
    if (!_user) {
        // Attempt to load the user from preferences
        NSData *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
        if (userData)
            _user = [NSKeyedUnarchiver unarchiveObjectWithData:userData];
        
        // If no user was found, create one
        if (!_user)
            _user = [[CMUser alloc] init];
        
        // Set this user as the user of the default store
        CMStore *store = [CMStore defaultStore];
        store.user = _user;
    }
    
    return _user;
}

- (void)setUser:(CMUser *)user {
    _user = user;
    
    // Set this user as the user of the default store
    CMStore *store = [CMStore defaultStore];
    store.user = _user;
    
    // Save the user to preferences
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_user] forKey:@"User"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Items

- (void)detailController:(TBDetailViewController *)controller didModifyItem:(TBTodoItem *)item {
    // Update the row of the item that is currently being edited
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_items indexOfObject:item] inSection:0];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    
    // Update the ordering of the table
    [self sortItems];
    [self.tableView reloadData];
}

- (void)reloadData {
    CMStore *store = [CMStore defaultStore];
    [_pull beginLoading];
    
    // Begin to fetch all of the to do items for the user
    [store allUserObjectsOfClass:[TBTodoItem class]
               additionalOptions:nil
                        callback:^(CMObjectFetchResponse *response) {
                            // If an error occurred, alert the user!
                            if (response.error) {
                                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:[response.error localizedDescription] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                                [errorAlert show];
                            }
                            
                            // Replace local items with those loaded from the server
                            if (response.objects.count) {
                                if (!_items)
                                    _items = [[NSMutableArray alloc] init];
                                else
                                    [_items removeAllObjects];
                                
                                [_items addObjectsFromArray:response.objects];
                            }
                            
                            // Sort the items
                            [self sortItems];
                            
                            // Display the items
                            [self.tableView reloadData];
                            
                            _refreshedDate = [NSDate date];
                            [_pull finishedLoading];
                            [_pull refreshLastUpdatedDate];
                        }];
}

- (void)sortItems {
    // Sort the items, taking into account completion status, priority, and alphabetical order
    [_items sortUsingComparator:^NSComparisonResult (TBTodoItem *obj1, TBTodoItem *obj2) {
        if ([obj1 done] != [obj2 done])
            return ([obj1 done] ? NSOrderedAscending : NSOrderedDescending);
        
        if ([obj1 priority] > [obj2 priority])
            return NSOrderedDescending;
        else if ([obj1 priority] < [obj2 priority])
            return NSOrderedAscending;
        else
            return [[obj1 text] compare:[obj2 text] options:NSCaseInsensitiveSearch];
    }];
}

- (void)insertNewItem:(id)sender {
    if (!_items)
        _items = [[NSMutableArray alloc] init];
    
    // Create a new to do item
    TBTodoItem *todoItem = [[TBTodoItem alloc] initWithText:@"New Todo Item"];
    [_items addObject:todoItem];
    
    // Re-sort the list
    [self sortItems];
    
    // Insert the item into the table in the correct location
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_items indexOfObject:todoItem] inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    // Create new item in CloudMine object store
    __block UINavigationController *navController = self.navigationController;
    [todoItem saveWithUser:self.user
                  callback:^(CMObjectUploadResponse *response) {
                      // If the item was *not* successfully created, fix the mess
                      if (![[response.uploadStatuses objectForKey:todoItem.objectId] isEqualToString:@"created"]) {
                          
                          // Pop the detail view controller if it is editing the failed item
                          if ([[navController topViewController] isKindOfClass:[TBDetailViewController class]]) {
                              TBDetailViewController *detailController = (TBDetailViewController *)[navController topViewController];
                              if ([detailController.item isEqual:todoItem]) {
                                  [navController popViewControllerAnimated:YES];
                              }
                          }
                          
                          // Delete it from its spot in the table view
                          NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_items indexOfObject:todoItem] inSection:0];
                          [_items removeObject:todoItem];
                          [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                          
                          // Alert the user
                          NSString *message = @"The item could not be created.";
                          if (response.error)
                              message = [response.error localizedDescription];
                          UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:[response.error localizedDescription] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                          [errorAlert show];
                      }
                  }];
}

#pragma mark - Storyboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *identifier = [segue identifier];
    if ([identifier isEqualToString:@"Login"]) {
        UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
        
        TBLoginViewController *loginController = (TBLoginViewController *)navController.topViewController;
        loginController.user = self.user;
        loginController.delegate = self;
    } else if ([identifier isEqualToString:@"Detail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        TBTodoItem *item = [_items objectAtIndex:indexPath.row];
        
        TBDetailViewController *detailController = (TBDetailViewController *)segue.destinationViewController;
        detailController.delegate = self;
        detailController.item = item;
    }
}

#pragma mark - Table View

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view {
    [self reloadData];
}

- (NSDate *)pullToRefreshViewLastUpdated:(PullToRefreshView *)view {
    return _refreshedDate;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TBTodoItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.todoItem = [_items objectAtIndex:indexPath.row];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (tableView.editing) {
        // If editing, then proceed to the detail view
        [self performSegueWithIdentifier:@"Detail" sender:cell];
    } else {
        // If not editing, then proceed to change completion status
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        TBTodoItem *item = [_items objectAtIndex:indexPath.row];
        
        // Flip flop completion status
        item.done = !item.done;        
        cell.accessoryType = item.done ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        // Order may change, because completion status affects order
        [self sortItems];
        
        // Animate row to new position
        NSIndexPath *changedPath = [NSIndexPath indexPathForRow:[_items indexOfObject:item] inSection:0];
        [self.tableView moveRowAtIndexPath:indexPath toIndexPath:changedPath];
        
        // Update item in CloudMine object store
        [item save:^(CMObjectUploadResponse *response) {
            // If the item was *not* successfully updated, fix the mess
            if (![[response.uploadStatuses objectForKey:item.objectId] isEqualToString:@"updated"]) {
                
                // Revert completion status
                item.done = !item.done;
                cell.accessoryType = item.done ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

                [self sortItems];
                
                // Animate row back to old position
                NSIndexPath *revertedPath = [NSIndexPath indexPathForRow:[_items indexOfObject:item] inSection:0];
                [self.tableView moveRowAtIndexPath:changedPath toIndexPath:revertedPath];
                
                // Alert the user
                NSString *message = @"The item could not be updated.";
                if (response.error)
                    message = [response.error localizedDescription];
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                [errorAlert show];
            }
        }];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Handle item deletion
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TBTodoItem *todoItem = [_items objectAtIndex:indexPath.row];
        
        // Delete item from table
        [_items removeObject:todoItem];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        // Delete item from CloudMine object store
        CMStore *store = [CMStore defaultStore];
        [store deleteUserObject:todoItem
              additionalOptions:nil
                       callback:^(CMDeleteResponse *response) {
                           // If the item was *not* successfully deleted, fix the mess
                           if (response.success.count < 1) {
                               // Thanks to this block, the previous todoItem is retained
                               [_items addObject:todoItem];
                               
                               [self sortItems];
                               
                               // Re-insert item into table view
                               NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_items indexOfObject:todoItem] inSection:0];
                               [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                               
                               // Alert the user
                               NSString *message = @"The item could not be deleted.";
                               if (response.error)
                                   message = [response.error localizedDescription];
                               UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:[response.error localizedDescription] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                               [errorAlert show];
                           }
                       }
         ];
    }
}

@end
