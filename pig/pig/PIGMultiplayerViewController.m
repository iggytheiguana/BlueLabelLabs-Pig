//
//  PIGMultiplayerViewController.m
//  pig
//
//  Created by Jordan Gurrieri on 9/14/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGMultiplayerViewController.h"
#import <GameKit/GameKit.h>
#import "PIGGameConstants.h"
#import "UIColor+PIGCustomColors.h"
#import "UINavigationController+PIGCustomNavigationController.h"
#import "PIGIAPHelper.h"
#import "PIGMultiplayerCell.h"
#import "Reachability.h"

#define IS_IPHONE6 (([[UIScreen mainScreen] bounds].size.height-568)?NO:YES)
#define IS_IPHONE_X_MAX (([[UIScreen mainScreen] bounds].size.height-812)?NO:YES)


@interface PIGMultiplayerViewController ()

@end

@implementation PIGMultiplayerViewController {
    NSArray *_existingMatches;
    UIActivityIndicatorView *m_ai_loadMatches;
    GKTurnBasedMatch *_matchToDelete;
    
    UIActionSheet *_as_newGame;
    UIAlertView *_av_noInternet;
    UIAlertView *_av_deleteMatch;
}

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
        CGRect viewFrame = CGRectMake(0.0, 0.0, 320.0, 66.0);
        UIView *titleView = [[UIView alloc] initWithFrame:viewFrame];
        [titleView setContentMode:UIViewContentModeCenter];
        
        CGRect labelFrame = CGRectMake(0.0, 4.0, 320.0, 36.0);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:labelFrame];
        [titleLabel setBackgroundColor:[UIColor whiteColor]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setFont:[UIFont systemFontOfSize:30.0]];
        [titleLabel setTextColor:[UIColor pigBlueColor]];
        [titleLabel setText:@"Two Player Games"];
        
        [titleView addSubview:titleLabel];
        [self.tableView setTableHeaderView:titleView];
        
    } else if IS_IPHONE_X_MAX {
        CGRect viewFrame = CGRectMake(100.0, 100.0, 375.0, 25);
        UIView *titleView = [[UIView alloc] initWithFrame:viewFrame];
        [titleView setContentMode:UIViewContentModeCenter];
        
        CGRect labelFrame = CGRectMake(0, -35, 375, 35);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:labelFrame];
        [titleLabel setBackgroundColor:[UIColor whiteColor]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setFont:[UIFont systemFontOfSize:30.0]];
        [titleLabel setTextColor:[UIColor pigBlueColor]];
        [titleLabel setText:@"Two Player Games"];
        
        [titleView addSubview:titleLabel];
        [self.tableView setTableHeaderView:titleView];
  
    } else {
        CGRect viewFrame = CGRectMake(0.0, 0.0, 375.0, 66.0);
        UIView *titleView = [[UIView alloc] initWithFrame:viewFrame];
        [titleView setContentMode:UIViewContentModeCenter];
        
        CGRect labelFrame = CGRectMake(0.0, 4.0, 375, 36.0);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:labelFrame];
        [titleLabel setBackgroundColor:[UIColor whiteColor]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setFont:[UIFont systemFontOfSize:30.0]];
        [titleLabel setTextColor:[UIColor pigBlueColor]];
        [titleLabel setText:@"Two Player Games"];
        
        [titleView addSubview:titleLabel];
        [self.tableView setTableHeaderView:titleView];
    }
    
    // Initialize Refresh Control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadTableView:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];
    
    // Setup activity indicator in the navigation bar
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    m_ai_loadMatches = activityIndicator;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if IS_IPHONE_X_MAX {
        for (UIView *subview in self.navigationController.navigationBar.subviews) {
            if ([NSStringFromClass([subview class]) containsString:@"BarBackground"]) {
                CGRect subViewFrame = subview.frame;
                subViewFrame.origin.y = -20;
                subViewFrame.size.height = 100;
                [subview setFrame: subViewFrame];
            }
        }
    }
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    // Temporarily disable the New Game button until we have confirmed that the tableview has been reloaded will all the matches
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    [PIGGCHelper sharedInstance].delegate = self;
    
    // We need to reload the tableview when the app resumes from background state
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [self reloadTableView:nil];
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

#pragma mark - Instance Methods
-(void)reloadTableView:(id)sender {
    Reachability *internetReachable = [Reachability reachabilityWithHostname:@"www.itunes.com"];
    
    if (internetReachable.isReachable == NO) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No internet connection available"
                                                        message:@"Game Center matches cannot be loaded. Do you want to start a Local Two Player Match?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Local Match", nil];
        _av_noInternet = alert;
        [_av_noInternet show];
        
        if ([sender isKindOfClass:[UIRefreshControl class]] == NO) {
            [m_ai_loadMatches stopAnimating];
            [self.navigationItem setTitleView:nil];
        }
        else {
            [self.refreshControl endRefreshing];
        }
        
        // Enable the New Game button
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        
        return;
    }
    
    if ([sender isKindOfClass:[UIRefreshControl class]] == NO) {
        [self.navigationItem setTitleView:m_ai_loadMatches];
        [m_ai_loadMatches startAnimating];
    }
    
    // Refresh the matches form Game Center, then reload the tableview
    [GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            for (GKTurnBasedMatch *match in matches) {
                // We need to update the match data for all matches downloaded
                [match loadMatchDataWithCompletionHandler:^(NSData *matchData, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        
                    }
                }];
            }
            
            _existingMatches = [[NSArray alloc] initWithArray:matches];
            
            NSLog(@"Matches: %@", _existingMatches);
            [self.tableView reloadData];
        }
        
        if ([sender isKindOfClass:[UIRefreshControl class]] == NO) {
            [m_ai_loadMatches stopAnimating];
            [self.navigationItem setTitleView:nil];
        }
        else {
            [self.refreshControl endRefreshing];
        }
        
        // Enable the New Game button
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }];
}

- (IBAction)quitMatch:(GKTurnBasedMatch *)match {
    // Quit and remove the match from Game Center
    if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
        [PIGGCHelper sharedInstance].delegate = self;
        [[PIGGCHelper sharedInstance] turnBasedMatchmakerViewController:nil playerQuitForMatch:match];
        
        _matchToDelete = nil;
    }
    else {
        
        [PIGGCHelper sharedInstance].delegate = self;
        [[PIGGCHelper sharedInstance] playerQuitOutOfTurnForMatch:match];
        
        _matchToDelete = nil;
    }
}

- (void)applicationDidBecomeActive {
    [self reloadTableView:nil];
}

- (void)startLocalMatch {
    
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMELOCAL;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gameplayViewController];
    [navigationController applyCustomStyle];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)startGameCenterMatch {
    
    [PIGGCHelper sharedInstance].delegate = self;
    [[PIGGCHelper sharedInstance] findMatchWithMinPlayers:kTurnBasedGameMinPlayers maxPlayers:kTurnBasedGameMaxPlayers viewController:self showExistingMatches:NO];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_existingMatches count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MultiplayerGameCellv2";
    
    PIGMultiplayerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    GKTurnBasedMatch *match = [_existingMatches objectAtIndex:indexPath.row];
    
    if ([match.matchData length] > 0) {
        NSDictionary *matchDataDict = [NSPropertyListSerialization propertyListWithData:match.matchData options:NSPropertyListMutableContainersAndLeaves format:nil error:nil];
        
        // Determine which player the current user is
        NSString *player1ID = [matchDataDict objectForKey:@"player1ID"];
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        
        NSString *opponentName;
        int opponentScore;
        int playerScore;
        if ([localPlayer.playerID isEqualToString:player1ID]) {
            // The current user is player 1
            opponentName = [matchDataDict objectForKey:@"player2Name"];
            opponentScore = [[matchDataDict objectForKey:@"score2"] intValue];
            playerScore = [[matchDataDict objectForKey:@"score1"] intValue];
            [cell.iv_opponentLabel setImage:[UIImage imageNamed:@"player-bg-blue-reverse.png"]];
        }
        else {
            // The current user is player 2
            opponentName = [matchDataDict objectForKey:@"player1Name"];
            opponentScore = [[matchDataDict objectForKey:@"score1"] intValue];
            playerScore = [[matchDataDict objectForKey:@"score2"] intValue];
            [cell.iv_opponentLabel setImage:[UIImage imageNamed:@"player-bg-pink.png"]];
        }
        
        if (opponentName == nil) {
            opponentName = @"Opponent";
        }
        
        cell.lbl_nameOpponent.text = opponentName;
        cell.lbl_pointsOpponent.text = [NSString stringWithFormat:@"%d", opponentScore];
        cell.lbl_pointsPlayer.text = [NSString stringWithFormat:@"%d", playerScore];
        
        // Determine the state of the match and whose turn it is
        GKTurnBasedMatchOutcome yourOutcome;
        for (GKTurnBasedParticipant *participant in match.participants) {
            if ([participant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
                yourOutcome = participant.matchOutcome;
            }
        }
        
        if (match.status != GKTurnBasedMatchStatusEnded && yourOutcome != GKTurnBasedMatchOutcomeQuit) {
            if ([match.currentParticipant.playerID isEqualToString:localPlayer.playerID]) {
                // It is the local player's turn
                cell.lbl_turn.text = @"Your turn";
                [cell.contentView setAlpha:1.0];
                [cell.contentView setBackgroundColor:[UIColor clearColor]];
            }
            else if ([opponentName isEqualToString:@"Opponent"]) {
                // No opponent has joined the game yet
                cell.lbl_turn.text = @"Waiting for match";
                [cell.contentView setAlpha:0.4];
                [cell.contentView setBackgroundColor:[UIColor clearColor]];
            }
            else {
                // It is the other player's turn
                cell.lbl_turn.text = @"Their turn";
                [cell.contentView setAlpha:0.4];
                [cell.contentView setBackgroundColor:[UIColor clearColor]];
            }
        }
        else {
            // The match has ended
            cell.lbl_turn.text = @"Game Over";
            [cell.contentView setAlpha:1.0];
            [cell.contentView setBackgroundColor:[UIColor pigLightGray]];
        }
    }
    
    return cell;
}

#pragma mark - TableView Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    GKTurnBasedMatch *match = [_existingMatches objectAtIndex:indexPath.row];
    
    [PIGGCHelper sharedInstance].delegate = self;
    [[PIGGCHelper sharedInstance] turnBasedMatchmakerViewController:nil didFindMatch:match];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Select the match associated with this row
        _matchToDelete = [_existingMatches objectAtIndex:indexPath.row];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Game in Progress"
                                                        message:@"Are you sure you want to remove and forfeit this game?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Remove", nil];
        _av_deleteMatch = alert;
        [_av_deleteMatch show];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Remove";
}

#pragma mark - GCHelperDelegate Multiplayer Methods
-(void)enterNewGame:(GKTurnBasedMatch *)match {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
    [PIGGCHelper sharedInstance].delegate = gameplayViewController;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gameplayViewController];
    [navigationController applyCustomStyle];
    
    [self presentViewController:navigationController animated:YES completion:^{
        [gameplayViewController enterNewGame:match];
    }];
}

-(void)takeTurn:(GKTurnBasedMatch *)match {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
    [PIGGCHelper sharedInstance].delegate = gameplayViewController;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gameplayViewController];
    [navigationController applyCustomStyle];
    
    [self presentViewController:navigationController animated:YES completion:^{
        [gameplayViewController takeTurn:match];
    }];
}

-(void)layoutMatch:(GKTurnBasedMatch *)match {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
    [PIGGCHelper sharedInstance].delegate = gameplayViewController;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gameplayViewController];
    [navigationController applyCustomStyle];
    
    [self presentViewController:navigationController animated:YES completion:^{
        [gameplayViewController layoutMatch:match];
    }];
}

- (void)sendNotice:(NSString *)notice forMatch:(GKTurnBasedMatch *)match {
    [self reloadTableView:nil];
}

-(void)recieveEndGame:(GKTurnBasedMatch *)match {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
    [PIGGCHelper sharedInstance].delegate = gameplayViewController;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gameplayViewController];
    [navigationController applyCustomStyle];
    
    [self presentViewController:navigationController animated:YES completion:^{
        [gameplayViewController recieveEndGame:match];
    }];
}

#pragma mark - PIGViewController Delegate
- (void)pigViewControllerDidClose {
//    [self.navigationController popViewControllerAnimated:YES];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PIGUpgradeViewController Delegate
- (void)pigUpgradeViewControllerDidClose {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Gamecenter Matchmaker game
        [self startGameCenterMatch];
    }
    else if (buttonIndex == 1) {
        // Local Game
        [self startLocalMatch];
    }
}

#pragma mark - UIAlert Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == _av_noInternet) {
        if (buttonIndex == 1) {
            // Start Local Match
            [self startLocalMatch];
        }
    }
    else if (alertView == _av_deleteMatch) {
        if (buttonIndex == 1) {
            // User confirmed "Delete" match
            [self quitMatch:_matchToDelete];
        }
    }
}

#pragma mark - UIAction Methods
- (IBAction)onNewTwoPlayerGameButtonPressed:(id)sender {
    // Check if two-palyer game has been unlocked already
    BOOL twoPlayerProductPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:IAPUnlockTwoPlayerGameProductIdentifier];
    
    // Check number of active games
    int activeMatches = 0;
    for (GKTurnBasedMatch *match in _existingMatches) {
        if (match.status != GKTurnBasedMatchStatusEnded && match.status != GKTurnBasedMatchStatusUnknown) {
            activeMatches++;
        }
    }
    
    if (twoPlayerProductPurchased == NO && activeMatches >= 2) {
        PIGUpgradeViewController *upgradeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UpgradeIdentifier"];
        upgradeViewController.delegate = self;
        [self.navigationController pushViewController:upgradeViewController animated:YES];
    }
    else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Online Matchmaker", @"Local Match", nil];
        [actionSheet showFromBarButtonItem:self.btn_newGame animated:YES];
    }
}

@end
