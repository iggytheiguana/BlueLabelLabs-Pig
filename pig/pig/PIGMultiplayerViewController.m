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

@interface PIGMultiplayerViewController ()

@end

@implementation PIGMultiplayerViewController {
    NSArray *_existingMatches;
    UIActivityIndicatorView *m_ai_loadMatches;
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
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    // Temporarily disable the New Game button until we have confirmed that the tableview has been reloaded will all the matches
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    [PIGGCHelper sharedInstance].delegate = self;
    
    [self reloadTableView:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Instance Methods
-(void)reloadTableView:(id)sender {
//    [self.refreshControl beginRefreshing];
    
//    if (self.tableView.contentOffset.y == 0.0) {
//        [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
//    }
    
    if ([sender isKindOfClass:[UIRefreshControl class]] == NO) {
        [self.navigationItem setTitleView:m_ai_loadMatches];
        [m_ai_loadMatches startAnimating];
    }
    
    // Refresh the matches form Game Center, then reload the tableview
    [GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
//        else {
//            NSMutableArray *yourTurnMatches = [NSMutableArray array];
//            NSMutableArray *theirTurnMatches = [NSMutableArray array];
//            NSMutableArray *completedMatches = [NSMutableArray array];
//            
//            for (GKTurnBasedMatch *match in matches) {
//                GKTurnBasedMatchOutcome yourOutcome;
//                for (GKTurnBasedParticipant *participant in match.participants) {
//                    if ([participant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
//                        yourOutcome = participant.matchOutcome;
//                    }
//                }
//                
//                if (match.status != GKTurnBasedMatchStatusEnded && yourOutcome != GKTurnBasedMatchOutcomeQuit) {
//                    if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
//                        [yourTurnMatches addObject:match];
//                    }
//                    else {
//                        [theirTurnMatches addObject:match];
//                    }
//                }
//                else {
//                    [completedMatches addObject:match];
//                }
//            }
//            
//            _existingMatches = [[NSArray alloc] initWithObjects:yourTurnMatches, theirTurnMatches, completedMatches, nil];
//            NSLog(@"Matches: %@", _existingMatches);
//            [self.tableView reloadData];
//        }
        else {
            NSMutableArray *allMatches = [NSMutableArray array];
            
            for (GKTurnBasedMatch *match in matches) {
                GKTurnBasedMatchOutcome yourOutcome;
                for (GKTurnBasedParticipant *participant in match.participants) {
                    if ([participant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
                        yourOutcome = participant.matchOutcome;
                    }
                }
                
                if (match.status != GKTurnBasedMatchStatusEnded && yourOutcome != GKTurnBasedMatchOutcomeQuit) {
                    [allMatches addObject:match];
                }
            }
            
            _existingMatches = [[NSArray alloc] initWithArray:allMatches];
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
    if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
        [PIGGCHelper sharedInstance].delegate = self;
        [[PIGGCHelper sharedInstance] turnBasedMatchmakerViewController:nil playerQuitForMatch:match];
    }
    else {
        [PIGGCHelper sharedInstance].delegate = self;
        [match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeQuit withCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
    
    [match removeWithCompletionHandler:^(NSError *error) {
        [self reloadTableView:nil];
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
//    return 4;
    return 1;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    if (section == 0) {
//        return @"Local Game";
//    }
//    else if (section == 1) {
//        return @"Your Turn";
//    }
//    else if (section == 2) {
//        return @"Their Turn";
//    } else {
//        return @"Completed Games";
//    }
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    if (section == 0) {
//        // Local Game
//        return 1;
//    }
//    else if (section == 1) {
//        // Your Turn Multiplayer Games
//        if ([[_existingMatches objectAtIndex:(section - 1)] count] == 0) {
//            // For the New Game row
//            return 1;
//        }
//        else {
//            return [[_existingMatches objectAtIndex:(section - 1)] count] + 1;
//        }
//    }
//    else {
//        // Multiplayer Games
//        return [[_existingMatches objectAtIndex:(section - 1)] count];
//    }
    return [_existingMatches count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSString *CellIdentifier;
//    
//    if (indexPath.section == 0 && indexPath.row == 0) {
//        // New Local Two Player Game
//        CellIdentifier = @"LocalGameCell";
//    }
//    else if (indexPath.section == 1 && indexPath.row == [[_existingMatches objectAtIndex:0] count]) {
//        // New Multiplayer Player Game
//        CellIdentifier = @"NewMultiplayerGameCell";
//    }
//    else {
//        // Existing Game
//        CellIdentifier = @"MultiplayerGameCell";
//    }
//    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//    
//    if ([CellIdentifier isEqualToString:@"MultiplayerGameCell"]) {
//        GKTurnBasedMatch *match = [[_existingMatches objectAtIndex:(indexPath.section - 1)] objectAtIndex:indexPath.row];
//        
//        if ([match.matchData length] > 0) {
//            NSDictionary *matchDataDict = [NSPropertyListSerialization propertyListFromData:match.matchData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
//            
//            NSString *opponentName = [matchDataDict objectForKey:@"player1ID"];
//            NSString *scoreString = [NSString stringWithFormat:@"%d vs %d", [[matchDataDict objectForKey:@"score1"] intValue], [[matchDataDict objectForKey:@"score2"] intValue]];
//            
//            cell.textLabel.text = opponentName;
//            cell.detailTextLabel.text = scoreString;
//        }
//    }
//    
//    return cell;
    
//    static NSString *CellIdentifier = @"MultiplayerGameCell";
//    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//    
//    GKTurnBasedMatch *match = [_existingMatches objectAtIndex:indexPath.row];
//    
//    if ([match.matchData length] > 0) {
//        NSDictionary *matchDataDict = [NSPropertyListSerialization propertyListFromData:match.matchData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
//        
//        NSString *opponentName = [matchDataDict objectForKey:@"player1ID"];
//        NSString *scoreString = [NSString stringWithFormat:@"%d vs %d", [[matchDataDict objectForKey:@"score1"] intValue], [[matchDataDict objectForKey:@"score2"] intValue]];
//        
//        cell.textLabel.text = opponentName;
//        cell.detailTextLabel.text = scoreString;
//    }

    static NSString *CellIdentifier = @"MultiplayerGameCellv2";
    
    PIGMultiplayerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    GKTurnBasedMatch *match = [_existingMatches objectAtIndex:indexPath.row];
    
    if ([match.matchData length] > 0) {
        NSDictionary *matchDataDict = [NSPropertyListSerialization propertyListFromData:match.matchData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
        
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
        
        // Determine whose turn it is
        if ([match.currentParticipant.playerID isEqualToString:localPlayer.playerID]) {
            // It is the local player's turn
            cell.lbl_turn.text = @"Your turn";
            [cell.contentView setAlpha:1.0];
        }
        else if ([opponentName isEqualToString:@"Opponent"]) {
            cell.lbl_turn.text = @"Waiting for match";
            [cell.contentView setAlpha:0.4];
        }
        else {
            cell.lbl_turn.text = @"Their turn";
            [cell.contentView setAlpha:0.4];
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
    
//	if (indexPath.section == 0 && indexPath.row == 0) {
//        // Local Two Player Game selected
//        PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
//        gameplayViewController.delegate = self;
//        gameplayViewController.gameType = kTWOPLAYERGAMELOCAL;
//        
//        [self presentViewController:gameplayViewController animated:YES completion:nil];
//    }
//    else if (indexPath.section == 1 && indexPath.row == [[_existingMatches objectAtIndex:0] count]) {
//        [[PIGGCHelper sharedInstance] findMatchWithMinPlayers:kTurnBasedGameMinPlayers maxPlayers:kTurnBasedGameMaxPlayers viewController:self showExistingMatches:NO];
//        [PIGGCHelper sharedInstance].delegate = self;
////
////        [self.gamePlayViewController dismissViewControllerAnimated:YES completion:nil];
////        [[PIGGCHelper sharedInstance] turnBasedMatchmakerViewController:nil didFindMatch:match];
//        
////        GKMatchRequest *request = [[GKMatchRequest alloc] init];
////        
////        request.maxPlayers = 2;
////        request.minPlayers = 2;
////        
////        [GKTurnBasedMatch findMatchForRequest:request withCompletionHandler:^(GKTurnBasedMatch *match, NSError *error) {
////            if (error) {
////                NSLog(@"%@", error.localizedDescription );
////            } else {
////                NSLog(@"match found!");
//////                [self dismissViewControllerAnimated:YES completion:nil];
////                
////                PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
////                gameplayViewController.delegate = self;
////                gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
////                [PIGGCHelper sharedInstance].delegate = gameplayViewController;
////                [self.navigationController pushViewController:gameplayViewController animated:YES];
////                
////                [[PIGGCHelper sharedInstance] turnBasedMatchmakerViewController:nil didFindMatch:match];
////            }
////        }];
//    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Game in Progress"
                                                        message:@"Are you sure you want to remove this game?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Remove", nil];
        [alert show];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Remove";
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

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
        [PIGGCHelper sharedInstance].delegate = self;
        [[PIGGCHelper sharedInstance] findMatchWithMinPlayers:kTurnBasedGameMinPlayers maxPlayers:kTurnBasedGameMaxPlayers viewController:self showExistingMatches:NO];
    }
    else if (buttonIndex == 1) {
        // Local Game
        PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
        gameplayViewController.delegate = self;
        gameplayViewController.gameType = kTWOPLAYERGAMELOCAL;
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gameplayViewController];
        [navigationController applyCustomStyle];
        
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

#pragma mark - UIAlert Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex > 0 && buttonIndex < alertView.numberOfButtons) {
        GKTurnBasedMatch *match = [_existingMatches objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        [self quitMatch:match];
    }
}

#pragma mark - UIAction Methods
- (IBAction)onNewTwoPlayerGameButtonPressed:(id)sender {
    // Check if two-palyer game has been unlocked already
    BOOL twoPlayerProductPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:IAPUnlockTwoPlayerGameProductIdentifier];
    
    if (twoPlayerProductPurchased == NO && [_existingMatches count] > 1) {
        PIGViewController *upgradeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UpgradeIdentifier"];
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
