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

@interface PIGMultiplayerViewController ()

@end

@implementation PIGMultiplayerViewController {
    NSArray *_existingMatches;
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

    [self reloadTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    // Hide the Navigation bar line
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]]) {
                [view2 removeFromSuperview];
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Instance Methods
-(void)reloadTableView {
    [GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            NSMutableArray *yourTurnMatches = [NSMutableArray array];
            NSMutableArray *theirTurnMatches = [NSMutableArray array];
            NSMutableArray *completedMatches = [NSMutableArray array];
            
            for (GKTurnBasedMatch *match in matches) {
                GKTurnBasedMatchOutcome yourOutcome;
                for (GKTurnBasedParticipant *participant in match.participants) {
                    if ([participant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
                        yourOutcome = participant.matchOutcome;
                    }
                }
                
                if (match.status != GKTurnBasedMatchStatusEnded && yourOutcome != GKTurnBasedMatchOutcomeQuit) {
                    if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
                        [yourTurnMatches addObject:match];
                    } else {
                        [theirTurnMatches addObject:match];
                    }
                } else {
                    [completedMatches addObject:match];
                }
            }
            
            _existingMatches = [[NSArray alloc] initWithObjects:yourTurnMatches, theirTurnMatches, completedMatches, nil];
            NSLog(@"Matches: %@", _existingMatches);
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Local Game";
    }
    else if (section == 1) {
        return @"Your Turn";
    }
    else if (section == 2) {
        return @"Their Turn";
    } else {
        return @"Completed Games";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        // Local Game
        return 1;
    }
    else if (section == 1) {
        // Your Turn Multiplayer Games
        if ([[_existingMatches objectAtIndex:(section - 1)] count] == 0) {
            // For the New Game row
            return 1;
        }
        else {
            return [[_existingMatches objectAtIndex:(section - 1)] count] + 1;
        }
    }
    else {
        // Multiplayer Games
        return [[_existingMatches objectAtIndex:(section - 1)] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        // New Local Two Player Game
        CellIdentifier = @"LocalGameCell";
    }
    else if (indexPath.section == 1 && indexPath.row == [[_existingMatches objectAtIndex:0] count]) {
        // New Multiplayer Player Game
        CellIdentifier = @"NewMultiplayerGameCell";
    }
    else {
        // Existing Game
        CellIdentifier = @"MultiplayerGameCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if ([CellIdentifier isEqualToString:@"MultiplayerGameCell"]) {
        GKTurnBasedMatch *match = [[_existingMatches objectAtIndex:(indexPath.section - 1)] objectAtIndex:indexPath.row];
        
        if ([match.matchData length] > 0) {
            NSDictionary *matchDataDict = [NSPropertyListSerialization propertyListFromData:match.matchData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
            
            NSString *opponentName = [matchDataDict objectForKey:@"player1ID"];
            NSString *scoreString = [NSString stringWithFormat:@"%d vs %d", [[matchDataDict objectForKey:@"score1"] intValue], [[matchDataDict objectForKey:@"score2"] intValue]];
            
            cell.textLabel.text = opponentName;
            cell.detailTextLabel.text = scoreString;
        }
    }
    
    return cell;
}

#pragma mark - TableView Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
	if (indexPath.section == 0 && indexPath.row == 0) {
        // Local Two Player Game selected
        PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
        gameplayViewController.delegate = self;
        gameplayViewController.gameType = kTWOPLAYERGAMELOCAL;
        [self.navigationController pushViewController:gameplayViewController animated:YES];
    }
    else if (indexPath.section == 1 && indexPath.row == [[_existingMatches objectAtIndex:0] count]) {
//        [[PIGGCHelper sharedInstance] findMatchWithMinPlayers:kTurnBasedGameMinPlayers maxPlayers:kTurnBasedGameMaxPlayers viewController:self showExistingMatches:NO];
//        [PIGGCHelper sharedInstance].delegate = self;
//
//        [self.gamePlayViewController dismissViewControllerAnimated:YES completion:nil];
//        [[PIGGCHelper sharedInstance] turnBasedMatchmakerViewController:nil didFindMatch:match];
        
        GKMatchRequest *request = [[GKMatchRequest alloc] init];
        
        request.maxPlayers = 12;
        request.minPlayers = 2;
        
        [GKTurnBasedMatch findMatchForRequest:request withCompletionHandler:^(GKTurnBasedMatch *match, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription );
            } else {
                NSLog(@"match found!");
                [self dismissViewControllerAnimated:YES completion:nil];
                
                PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
                gameplayViewController.delegate = self;
                gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
                [PIGGCHelper sharedInstance].delegate = gameplayViewController;
                [self.navigationController pushViewController:gameplayViewController animated:YES];
                
                [[PIGGCHelper sharedInstance] turnBasedMatchmakerViewController:nil didFindMatch:match];
            }
        }];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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
    
    [self presentViewController:gameplayViewController animated:YES completion:^{
        [gameplayViewController enterNewGame:match];
    }];
}

-(void)takeTurn:(GKTurnBasedMatch *)match {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
    [PIGGCHelper sharedInstance].delegate = gameplayViewController;
    
    [self presentViewController:gameplayViewController animated:YES completion:^{
        [gameplayViewController takeTurn:match];
    }];
}

-(void)layoutMatch:(GKTurnBasedMatch *)match {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
    [PIGGCHelper sharedInstance].delegate = gameplayViewController;
    
    [self presentViewController:gameplayViewController animated:YES completion:^{
        [gameplayViewController layoutMatch:match];
    }];
}

- (void)sendNotice:(NSString *)notice forMatch:(GKTurnBasedMatch *)match {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
    [PIGGCHelper sharedInstance].delegate = gameplayViewController;
    
    [self presentViewController:gameplayViewController animated:YES completion:^{
        [gameplayViewController sendNotice:notice forMatch:match];
    }];
}

#pragma mark - PIGViewController Delegate
- (void)pigViewControllerDidClose {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
