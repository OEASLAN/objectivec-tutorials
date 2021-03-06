//
//  UserListVCViewController.m
//  Library Application with CoreData
//
//  Created by Ömer Emre Aslan on 11/07/15.
//  Copyright (c) 2015 omer. All rights reserved.
//

#import "UserListVCViewController.h"
#import "User.h"
#import "UserManager.h"
#import "UserDetailVC.h"

@interface UserListVCViewController ()
@property (strong, nonatomic) NSMutableArray *userArray;
@property (strong, nonatomic) NSMutableArray *userFilterArray;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) UserManager *userManager;
//Core Data context variable
@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;
@end


@implementation UserListVCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUsers];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = false;
    self.searchController.delegate = self;
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    [self.tableView reloadData];
}



- (UserManager *)userManager
{
    if (!_userManager) {
        _userManager = [UserManager sharedInstance];
    }
    return _userManager;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initUsers];
    [self.tableView reloadData];
}

#pragma mark - Core Data method

- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

#pragma mark - User Init
- (void)initUsers
{
    self.userArray = [self.userManager getAllUser];
}


- (void)willPresentSearchController:(UISearchController *)searchController
{
    
    self.tableView.backgroundColor = [[UIColor alloc]initWithRed:255 green:255 blue:255 alpha:0.90];
}

- (NSArray *)userFilterArray
{
    if (!_userFilterArray) {
        _userFilterArray = [NSMutableArray new];
    }
    return _userFilterArray;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (self.searchController.active) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"whiteCell"];
        self.tableView.backgroundColor = [[UIColor alloc]initWithRed:255 green:255 blue:255 alpha:1];
        User *user = [self.userFilterArray objectAtIndex:indexPath.row];
        cell.textLabel.text = user.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@",user.username];
    } else {
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"whiteCell"];
        self.tableView.backgroundColor = [[UIColor alloc]initWithRed:255 green:255 blue:255 alpha:1];
        User *user = [self.userArray objectAtIndex:indexPath.row];
        cell.textLabel.text = user.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@",user.username];
    }
    UILongPressGestureRecognizer *longPressTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showMenus:)];
    
    longPressTap.minimumPressDuration = 1.0;
    
    [cell addGestureRecognizer:longPressTap];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        if (self.searchController.active) {
        return self.userFilterArray.count;
    } else {
        return self.userArray.count;
    }
}

- (void)showMenus:(UILongPressGestureRecognizer *)lpt
{
    if (lpt.state == UIGestureRecognizerStateBegan)
        //or check for UIGestureRecognizerStateEnded instead
    {
        
        CGPoint location = [lpt locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
        User *user = [self.userArray objectAtIndex:indexPath.row];
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:[NSString stringWithFormat:@"@%@",user.username]
                              message:[NSString stringWithFormat:@"%@",user.name]
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:@"Delete",@"Detail", nil];
        [alert show];
    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self deleteUser:[alertView.title substringFromIndex:1]];
        [self initUsers];
        [self.tableView reloadData];
    } else if (buttonIndex == 2) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
        [self.searchController setActive:NO];
        [self performSegueWithIdentifier:@"userDetail" sender:cell];
        
    }
}

- (void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"userDetail" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Delete" handler:^(UITableViewRowAction * __nonnull action, NSIndexPath * __nonnull indexPath) {
        
        User *user = [self.userArray objectAtIndex:indexPath.row];
        
        NSManagedObjectID *objectId = [user objectID];
        int adminPK = [[[[[objectId URIRepresentation] absoluteString] lastPathComponent] substringFromIndex:1] intValue];
        if (adminPK == 1) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Delete process failed" message:@"You cannot delete super admin." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
            [alert show];
        } else if ([user.username isEqualToString:[self.userManager getCurrentUser].username]) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Delete process failed" message:@"You cannot delete yourself. Calm Down." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
            [alert show];
        } else {
            [self deleteUser:user.username];
            
            [tableView beginUpdates];
            
            [self initUsers];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView endUpdates];
        }
    }];
    deleteAction.backgroundColor = [UIColor redColor];
    UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Edit" handler:^(UITableViewRowAction * __nonnull action, NSIndexPath * __nonnull indexPath) {
        //User edit may be added later
    }];
    editAction.backgroundColor = [UIColor orangeColor];
    return @[deleteAction, editAction];
}

- (void)deleteUser:(NSString *)username
{
    User *user = [self.userManager getUserFromUserName:username];
    @try {
        [self.userManager deleteUser:user];
    }
    @catch (NSException *exception) {
        
        if ([exception.reason isEqualToString:@"superAdmin"]) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Delete process failed" message:@"You cannot delete super admin." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
            [alert show];
        } else if ([exception.reason isEqualToString:@"kamikaze"]) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Delete process failed" message:@"You cannot delete yourself. Calm Down." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Delete process failed" message:@"Please try again." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    @finally {
        
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    //self.filteredCountries.removeAll()
    [self.userFilterArray removeAllObjects];
    NSString *searching = searchController.searchBar.text;
    if (![searching isEqualToString:@""]) {
        for (User *user in self.userArray) {
            if ([user.name.lowercaseString containsString:searching.lowercaseString] || [user.username.lowercaseString containsString:searching.lowercaseString]) {
                [self.userFilterArray addObject:user];
            }
        }
    } else {
        self.tableView.backgroundColor = [[UIColor alloc]initWithRed:255 green:255 blue:255 alpha:0.90];
    }
    [self.tableView reloadData];
}

-(void)prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable id)sender
{
    
    UITableViewCell *cell = sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    if ([segue.identifier isEqualToString:@"userDetail"]) {
        UserDetailVC *vc = segue.destinationViewController;
        User *user;
        if (self.searchController.active) {
            user = [self.userFilterArray objectAtIndex:indexPath.row];
            
        } else {
            user = [self.userArray objectAtIndex:indexPath.row];
        }
        vc.username = user.username;
        vc.title = vc.username;
        
    }
    self.searchController.active = NO;
}

@end
