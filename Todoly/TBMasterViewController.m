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
    
    _pull = [[PullToRefreshView alloc] initWithScrollView:self.tableView];
    [_pull setDelegate:self];
    [self.tableView addSubview:_pull];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewItem:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    if (!self.user.isLoggedIn)
        [self performSegueWithIdentifier:@"Login" sender:self];
    else
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
    self.user = user;
    [self reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (CMUser *)user {
    if (!_user) {
        NSData *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
        if (userData)
            _user = [NSKeyedUnarchiver unarchiveObjectWithData:userData];
        if (!_user)
            _user = [[CMUser alloc] init];
        CMStore *store = [CMStore defaultStore];
        store.user = _user;
    }
    
    return _user;
}

- (void)setUser:(CMUser *)user {
    _user = user;
    
    CMStore *store = [CMStore defaultStore];
    store.user = _user;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_user] forKey:@"User"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Items

- (void)detailController:(TBDetailViewController *)controller didModifyItem:(TBTodoItem *)item {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_items indexOfObject:item] inSection:0];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)reloadData {
    CMStore *store = [CMStore defaultStore];
    [_pull beginLoading];
    [store allUserObjectsOfClass:[TBTodoItem class]
               additionalOptions:nil
                        callback:^(CMObjectFetchResponse *response) {
                            if (response.error) {
                                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:[response.error localizedDescription] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                                [errorAlert show];
                            }
                            
                            if (response.objects.count) {
                                if (!_items)
                                    _items = [[NSMutableArray alloc] init];
                                else
                                    [_items removeAllObjects];
                                
                                [_items addObjectsFromArray:response.objects];
                            }
                            
                            [self sortItems];
                            
                            [self.tableView reloadData];
                            
                            _refreshedDate = [NSDate date];
                            [_pull finishedLoading];
                            [_pull refreshLastUpdatedDate];
                        }];
}

- (void)sortItems {
    [_items sortUsingComparator:^NSComparisonResult (TBTodoItem *obj1, TBTodoItem *obj2) {
        if ([obj1 done] != [obj2 done]) {
            return ([obj1 done] ? NSOrderedAscending : NSOrderedDescending);
        }
        
        if ([obj1 priority] > [obj2 priority]) {
            return NSOrderedDescending;
        } else if ([obj1 priority] < [obj2 priority]) {
            return NSOrderedAscending;
        } else {
            return [[obj1 text] compare:[obj2 text] options:NSCaseInsensitiveSearch];
        }
    }];
}

- (void)insertNewItem:(id)sender {
    if (!_items)
        _items = [[NSMutableArray alloc] init];
    
    TBTodoItem *todoItem = [[TBTodoItem alloc] initWithText:@"New Todo Item"];
    [_items addObject:todoItem];
    
    [self sortItems];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_items indexOfObject:todoItem] inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    __block UINavigationController *navController = self.navigationController;
    [todoItem saveWithUser:self.user
                  callback:^(CMObjectUploadResponse *response) {
                      if (![[response.uploadStatuses objectForKey:todoItem.objectId] isEqualToString:@"created"]) {
                          if ([[navController topViewController] isKindOfClass:[TBDetailViewController class]]) {
                              TBDetailViewController *detailController = (TBDetailViewController *)[navController topViewController];
                              if ([detailController.item isEqual:todoItem]) {
                                  [navController popViewControllerAnimated:YES];
                              }
                          }
                          
                          NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_items indexOfObject:todoItem] inSection:0];
                          [_items removeObject:todoItem];
                          [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                          
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
        [self performSegueWithIdentifier:@"Detail" sender:cell];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        TBTodoItem *item = [_items objectAtIndex:indexPath.row];
        
        item.done = !item.done;        
        cell.accessoryType = item.done ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        [self sortItems];
        
        NSIndexPath *changedPath = [NSIndexPath indexPathForItem:[_items indexOfObject:item] inSection:0];
        [self.tableView moveRowAtIndexPath:indexPath toIndexPath:changedPath];
        
        [item save:^(CMObjectUploadResponse *response) {
            if (![[response.uploadStatuses objectForKey:item.objectId] isEqualToString:@"updated"]) {
                NSString *message = @"The item could not be updated.";
                if (response.error)
                    message = [response.error localizedDescription];
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                [errorAlert show];
                
                item.done = !item.done;
                
                [self sortItems];
                
                NSIndexPath *revertedPath = [NSIndexPath indexPathForItem:[_items indexOfObject:item] inSection:0];
                [self.tableView moveRowAtIndexPath:changedPath toIndexPath:revertedPath];
            }
            
            cell.accessoryType = item.done ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TBTodoItem *todoItem = [_items objectAtIndex:indexPath.row];
        
        [_items removeObject:todoItem];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        CMStore *store = [CMStore defaultStore];
        [store deleteUserObject:todoItem
              additionalOptions:nil
                       callback:^(CMDeleteResponse *response) {
                           if (response.success.count < 1) {
                               [_items addObject:todoItem];
                               [self sortItems];
                               NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_items indexOfObject:todoItem] inSection:0];
                               [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                               
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
