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
#import "UIColor+PIGCustomColors.h"

#define IS_IPHONE6 (([[UIScreen mainScreen] bounds].size.height-568)?NO:YES)
#define IS_IPHONE_X_MAX (([[UIScreen mainScreen] bounds].size.height-812)?NO:YES)

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
    
    // Add title view
    if (IS_IPHONE6) {
        CGRect viewFrame = CGRectMake(0.0, 0.0, 320.0, 36.0);
        UIView *titleView = [[UIView alloc] initWithFrame:viewFrame];
        [titleView setContentMode:UIViewContentModeCenter];
        
        CGRect labelFrame = CGRectMake(0.0, 4.0, 320.0, 36.0);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:labelFrame];
        [titleLabel setBackgroundColor:[UIColor clearColor]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setFont:[UIFont systemFontOfSize:25.0]];
        [titleLabel setTextColor:[UIColor pigBlueColor]];
        [titleLabel setText:@"More"];
        
        [titleView addSubview:titleLabel];
        [self.tableView setTableHeaderView:titleView];
    } else if IS_IPHONE_X_MAX {
        CGRect viewFrame = CGRectMake(0, 0.0, 375.0, 30);
        UIView *titleView = [[UIView alloc] initWithFrame:viewFrame];
        [titleView setContentMode:UIViewContentModeCenter];
        
        CGRect labelFrame = CGRectMake(0.0, 0.0, 375.0, 25.0);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:labelFrame];
        [titleLabel setBackgroundColor:[UIColor clearColor]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setFont:[UIFont systemFontOfSize:30.0]];
        [titleLabel setTextColor:[UIColor pigBlueColor]];
        [titleLabel setText:@"More"];
        
        [titleView addSubview:titleLabel];
        [self.tableView setTableHeaderView:titleView];
    } else {
        CGRect viewFrame = CGRectMake(0.0, 0.0, 375.0, 45);
        UIView *titleView = [[UIView alloc] initWithFrame:viewFrame];
        [titleView setContentMode:UIViewContentModeCenter];
        
        CGRect labelFrame = CGRectMake(0.0, 5.0, 375.0, 25.0);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:labelFrame];
        [titleLabel setBackgroundColor:[UIColor clearColor]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setFont:[UIFont systemFontOfSize:30.0]];
        [titleLabel setTextColor:[UIColor pigBlueColor]];
        [titleLabel setText:@"More"];
        
        [titleView addSubview:titleLabel];
        [self.tableView setTableHeaderView:titleView];
    }
    
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
    
    if IS_IPHONE_X_MAX {
        [self.navigationController.navigationBar setFrame:CGRectMake(0, 30, self.view.frame.size.width,80.0)];
    }
    // Check if two-palyer game has been unlocked already
    BOOL twoPlayerProductPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:IAPUnlockTwoPlayerGameProductIdentifier];
    UITableViewCell *removeAdsCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    UITableViewCell *restorePurchasesCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    if (twoPlayerProductPurchased == YES) {
        removeAdsCell.accessoryType = UITableViewCellAccessoryCheckmark;
        removeAdsCell.textLabel.textColor = [UIColor lightGrayColor];
        [removeAdsCell setUserInteractionEnabled:NO];
        
        restorePurchasesCell.accessoryType = UITableViewCellAccessoryCheckmark;
        restorePurchasesCell.textLabel.textColor = [UIColor lightGrayColor];
        [restorePurchasesCell setUserInteractionEnabled:NO];
    }
    else {
        removeAdsCell.accessoryType = UITableViewCellAccessoryNone;
        removeAdsCell.textLabel.textColor = [UIColor darkGrayColor];
        [removeAdsCell setUserInteractionEnabled:YES];
        
        restorePurchasesCell.accessoryType = UITableViewCellAccessoryNone;
        restorePurchasesCell.textLabel.textColor = [UIColor darkGrayColor];
        [restorePurchasesCell setUserInteractionEnabled:YES];
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
        PIGUpgradeViewController *upgradeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UpgradeIdentifier"];
        upgradeViewController.delegate = self;
        [self.navigationController pushViewController:upgradeViewController animated:YES];
    }
    else if (indexPath.section == 1 && indexPath.row == 1) {
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

#pragma mark - PIGUpgradeViewController Delegate
- (void)pigUpgradeViewControllerDidClose {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIAction Methods
- (IBAction)onVibrateSwitchValueChanged:(id)sender {
    BOOL vibrate = self.sw_vibrate.on;
    
    if (vibrate == YES) {
    }
    else {
    }
    
    // Save setting to user defaults
    [[NSUserDefaults standardUserDefaults] setBool:vibrate forKey:kSettingsVibrate];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
