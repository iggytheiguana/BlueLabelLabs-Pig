//
//  PIGMoreTableViewController.m
//  pig
//
//  Created by Jordan Gurrieri on 9/11/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGMoreTableViewController.h"
#import "PIGIAPHelper.h"
#import "PIGGameConstants.h"

@interface PIGMoreTableViewController () {
    NSArray *_products;
    UIActivityIndicatorView *m_ai_RestorePurchases;
}


@end

@implementation PIGMoreTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Setup vibrate setting from user defaults
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kSettingsVibrate]) {
        self.sw_vibrate.on = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsVibrate];
    }
    else {
        // Default to ON
        self.sw_vibrate.on = YES;
        
        // Save setting to user defaults
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSettingsVibrate];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Check if two-palyer game has been unlocked already
    BOOL twoPlayerProductPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:IAPUnlockTwoPlayerGameProductIdentifier];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    if (twoPlayerProductPurchased == YES) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = [UIColor lightGrayColor];
        [cell setUserInteractionEnabled:NO];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor darkGrayColor];
        [cell setUserInteractionEnabled:YES];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedTransaction:) name:IAPHelperFailedTransactionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreFailed:) name:IAPHelperRestoreFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreCanceled:) name:IAPHelperRestoreCanceledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreCompleted:) name:IAPHelperRestoreCompletedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Storyboard Methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"More_to_Rules"])
	{
		PIGRulesViewController *rulesViewController = segue.destinationViewController;
        rulesViewController.delegate = self;
	}
}

#pragma mark - In App Purchase Methods
- (void)failedTransaction:(NSString *)errorMessage {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iTunes Store Error"
                                                    message:[NSString stringWithFormat:@"Transaction error: %@", errorMessage]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)restoreFailed:(NSString *)errorMessage {
    [m_ai_RestorePurchases stopAnimating];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    cell.accessoryView = nil;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iTunes Store Error"
                                                    message:[NSString stringWithFormat:@"Transaction error: %@", errorMessage]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)restoreCanceled:(NSError *)error {
    [m_ai_RestorePurchases stopAnimating];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    cell.accessoryView = nil;
}

- (void)restoreCompleted:(NSError *)error {
    [m_ai_RestorePurchases stopAnimating];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.textLabel.textColor = [UIColor lightGrayColor];
    [cell setUserInteractionEnabled:NO];
}

#pragma mark - TableView Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
	if (indexPath.section == 0 && indexPath.row == 1) {
        // Leaderboards selected
        [self showLeaderboard];
    }
    else if (indexPath.section == 0 && indexPath.row == 2) {
        // Achievements selected
        [self showAchievements];
    }
    else if (indexPath.section == 1 && indexPath.row == 0) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityIndicator startAnimating];
        m_ai_RestorePurchases = activityIndicator;
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryView = m_ai_RestorePurchases;
        
        [[PIGIAPHelper sharedInstance] restoreCompletedTransactions];
    }
}

#pragma mark - Game Center Methods
- (void)showLeaderboard {
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.viewState = GKGameCenterViewControllerStateDefault;
        
        [self presentViewController:gameCenterController animated:YES completion:nil];
    }
}

- (void)showAchievements {
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.viewState = GKGameCenterViewControllerStateAchievements;
        
        [self presentViewController:gameCenterController animated:YES completion:nil];
    }
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PIGRulesViewController Delegate
- (void)pigRulesViewControllerDidClose {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIAction Methods
- (IBAction)onVibrateSwitchValueChanged:(id)sender {
    BOOL vibrate = self.sw_vibrate.on;
    
    // Save setting to user defaults
    [[NSUserDefaults standardUserDefaults] setBool:vibrate forKey:kSettingsVibrate];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
