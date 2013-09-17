//
//  GCHelper.m
//  pig
//
//  Created by Jordan Gurrieri on 9/6/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "GCHelper.h"

#define kTurnBasedGameMaxPlayers 2
#define kTurnBasedGameMinPlayers 2

@implementation GCHelper

static GCHelper *sharedHelper = nil;

#pragma mark - Initialization
+ (GCHelper *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelper = [[GCHelper alloc] init];
    });
    return sharedHelper;
}

- (BOOL)isGameCenterAvailable {
    // check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // check if the device is running iOS 7.0 or later
    NSString *reqSysVer = @"7.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

- (id)init {
    if ((self = [super init])) {
        //** UNCOMMENT IF NOT SUBCLASSING **//
//        _gameCenterAvailable = [self isGameCenterAvailable];
//        if (_gameCenterAvailable) {
//            NSNotificationCenter *nc =
//            [NSNotificationCenter defaultCenter];
//            [nc addObserver:self
//                   selector:@selector(authenticationChanged)
//                       name:GKPlayerAuthenticationDidChangeNotificationName
//                     object:nil];
//        }
    }
    return self;
}

- (void)authenticationChanged {
    if ([GKLocalPlayer localPlayer].isAuthenticated && !_playerAuthenticated) {
        NSLog(@"Authentication changed: player authenticated.");
        _playerAuthenticated = YES;
        _gameCenterFeaturesEnabled = YES;
    }
    else if (![GKLocalPlayer localPlayer].isAuthenticated && _playerAuthenticated) {
        NSLog(@"Authentication changed: player not authenticated");
        _playerAuthenticated = NO;
        _gameCenterFeaturesEnabled = NO;
    }
}

#pragma mark - User functions
- (void)authenticateLocalUserFromViewController:(UIViewController *)authenticationPresentingViewController {
    if (!_gameCenterAvailable)
        return;
    
    NSLog(@"Authenticating local user . . .");
    
    _presentingViewController = authenticationPresentingViewController;
    
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        [self setLastError:error];
        
        if ([GKLocalPlayer localPlayer].authenticated) {
            _playerAuthenticated = YES;
            _gameCenterFeaturesEnabled = YES;
            
            [[GKLocalPlayer localPlayer] registerListener:self];
            
            // Used to clean up maches while in development
//            [self deleteAllMatches];
        }
        else if (viewController) {
//            [self presentViewController:viewController];
            [authenticationPresentingViewController presentViewController:viewController animated:YES completion:^{
                _playerAuthenticated = YES;
                _gameCenterFeaturesEnabled = YES;

                [[GKLocalPlayer localPlayer] registerListener:self];
                
//                [self deleteAllMatches];
            }];
        }
        else {
            _playerAuthenticated = NO;
            _gameCenterFeaturesEnabled = NO;
        }
    };
}

#pragma mark - Property Setters
- (void)setLastError:(NSError*)error {
    _lastError = [error copy];
    if (_lastError) {
        NSLog(@"GCHelper ERROR: %@", [[_lastError userInfo]
                                           description]);
    }
}

#pragma mark - Turn-based Matchmaker Methods
- (void)findMatchWithMinPlayers:(int)minPlayers
                     maxPlayers:(int)maxPlayers
                 viewController:(UIViewController *)viewController
            showExistingMatches:(BOOL)showExistingMatches
{
    if (!_gameCenterAvailable)
        return;
    
    _presentingViewController = viewController;
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = minPlayers;
    request.maxPlayers = maxPlayers;
    
    GKTurnBasedMatchmakerViewController *mmvc = [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.turnBasedMatchmakerDelegate = self;
    mmvc.showExistingMatches = showExistingMatches;
    
    [_presentingViewController presentViewController:mmvc animated:YES completion:nil];
}

// Used for cleaning out matches when in development
-(void)deleteAllMatches {
    [GKTurnBasedMatch loadMatchesWithCompletionHandler:
     ^(NSArray *matches, NSError *error) {
         for (GKTurnBasedMatch *match in matches) {
             NSLog(@"%@", match.matchID);
             
             if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
                 NSUInteger currentIndex = [match.participants indexOfObject:match.currentParticipant];
                 GKTurnBasedParticipant *participant;
                 
                 NSMutableArray *nextParticipants = [NSMutableArray array];
                 for (int i = 0; i < [match.participants count]; i++) {
                     participant = [match.participants objectAtIndex:(currentIndex + 1 + i) % match.participants.count];
                     if (participant.matchOutcome == GKTurnBasedMatchOutcomeNone) {
                         [nextParticipants addObject:participant];
                     }
                 }
                 
                 [match participantQuitInTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                                        nextParticipants:nextParticipants
                                             turnTimeout:600
                                               matchData:match.matchData
                                       completionHandler:^(NSError *error) {
                     NSLog(@"%@", error);
                     [match removeWithCompletionHandler:^(NSError *error) {
                         NSLog(@"%@", error);
                     }];
                 }];
             }
             else {
                 [match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeTied withCompletionHandler:^(NSError *error) {
                     NSLog(@"%@", error);
                     [match removeWithCompletionHandler:^(NSError *error) { NSLog(@"%@", error);
                     }];
                 }];
             }
         }
     }];
}

#pragma mark GKTurnBasedMatchmakerViewControllerDelegate
- (void)didFindMatch:(GKTurnBasedMatch *)match {
    NSLog(@"Did find match, %@", match);
    
    self.currentMatch = match;
    
    GKTurnBasedParticipant *firstParticipant = [match.participants objectAtIndex:0];
    if (firstParticipant.lastTurnDate == NULL) {
        NSLog(@"New match");
        
        [self.delegate enterNewGame:match];
    }
    else {
        NSLog(@"Existing match");
        if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
            // Local Player's turn
            [self.delegate takeTurn:match];
        }
        else {
            // Someone else's turn
            [self.delegate layoutMatch:match];
        }
    }
}

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFindMatch:(GKTurnBasedMatch *)match {
//    [_presentingViewController dismissViewControllerAnimated:YES completion:nil];
//    NSLog(@"Did find match, %@", match);
//    
//    self.currentMatch = match;
//    
//    GKTurnBasedParticipant *firstParticipant = [match.participants objectAtIndex:0];
//    if (firstParticipant.lastTurnDate == NULL) {
//        NSLog(@"New match");
//        
//        [self.delegate enterNewGame:match];
//    }
//    else {
//        NSLog(@"Existing match");
//        if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
//            // Local Player's turn
//            [self.delegate takeTurn:match];
//        }
//        else {
//            // Someone else's turn
//            [self.delegate layoutMatch:match];
//        }
//    }
    
    if (_presentingViewController.presentedViewController &&
        (UIViewController *)self.delegate == (UIViewController *)_presentingViewController)
    {
        // The presentedViewController is currently visible. We need to dismiss it before moving forward.
        [_presentingViewController dismissViewControllerAnimated:YES completion:^(void) {
            [self didFindMatch:match];
        }];
    }
    else {
        [self didFindMatch:match];
    }
    
//    [_presentingViewController dismissViewControllerAnimated:YES completion:^(void) {
//        NSLog(@"Did find match, %@", match);
//        
//        self.currentMatch = match;
//        
//        GKTurnBasedParticipant *firstParticipant = [match.participants objectAtIndex:0];
//        if (firstParticipant.lastTurnDate == NULL) {
//            NSLog(@"New match");
//            
//            [self.delegate enterNewGame:match];
//        }
//        else {
//            NSLog(@"Existing match");
//            if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
//                // Local Player's turn
//                [self.delegate takeTurn:match];
//            }
//            else {
//                // Someone else's turn
//                [self.delegate layoutMatch:match];
//            }
//        }
//    }];
}

-(void)turnBasedMatchmakerViewControllerWasCancelled:(GKTurnBasedMatchmakerViewController *)viewController {
    [_presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"Has cancelled");
}

-(void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    [_presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"Error finding match: %@", error.localizedDescription);
}

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController playerQuitForMatch:(GKTurnBasedMatch *)match {
    NSLog(@"Player quit for Match, %@, %@", match, match.currentParticipant);
    
    NSUInteger currentIndex = [match.participants indexOfObject:match.currentParticipant];
    GKTurnBasedParticipant *participant;
    
    NSMutableArray *nextParticipants = [NSMutableArray array];
    for (int i = 0; i < [match.participants count]; i++) {
        participant = [match.participants objectAtIndex:(currentIndex + 1 + i) % match.participants.count];
        if (participant.matchOutcome == GKTurnBasedMatchOutcomeNone) {
            [nextParticipants addObject:participant];
        }
    }
    
    [match participantQuitInTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                           nextParticipants:nextParticipants
                                turnTimeout:600
                                  matchData:match.matchData
                          completionHandler:nil];
}

#pragma mark - GKLocalPlayerListener Protocol
- (void)player:(GKPlayer *)player receivedTurnEventForMatch:(GKTurnBasedMatch *)match didBecomeActive:(BOOL)didBecomeActive {
    NSLog(@"Turn has happened");
    
    // Check to see if all players are still within the match
    NSMutableArray *stillPlaying = [NSMutableArray array];
    for (GKTurnBasedParticipant *p in match.participants) {
        if (p.matchOutcome == GKTurnBasedMatchOutcomeNone) {
            [stillPlaying addObject:p];
        }
    }
    if ([stillPlaying count] < 2 && [match.participants count] >= 2) {
        // There's only one player left
        for (GKTurnBasedParticipant *part in stillPlaying) {
            part.matchOutcome = GKTurnBasedMatchOutcomeTied;
        }
        [match endMatchInTurnWithMatchData:match.matchData completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Error Ending Match %@", error);
            }
            [self.delegate layoutMatch:match];
        }];
    }
    
    if ([match.matchID isEqualToString:self.currentMatch.matchID]) {
        if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
            // It's the current match and it's our turn now
            self.currentMatch = match;
            [self.delegate takeTurn:match];
        }
        else {
            // It's the current match, but it's someone else's turn
            self.currentMatch = match;
            [self.delegate layoutMatch:match];
        }
    } else {
        if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
            // It's not the current match and it's our turn now
            [self.delegate sendNotice:@"It's your turn for another match" forMatch:match];
        }
        else {
            // It's the not current match, and it's someone else's turn
        }
    }
}

- (void)player:(GKPlayer *)player didRequestMatchWithPlayers:(NSArray *)playerIDsToInvite {
    NSLog(@"New invite");
    
    [_presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    
    request.playersToInvite = playerIDsToInvite;
    request.maxPlayers = kTurnBasedGameMaxPlayers;
    request.minPlayers = kTurnBasedGameMinPlayers;
    
    GKTurnBasedMatchmakerViewController *viewController = [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:request];
    
    viewController.showExistingMatches = NO;
    viewController.turnBasedMatchmakerDelegate = self;
    [_presentingViewController presentViewController:viewController animated:YES completion:nil];
}

- (void)player:(GKPlayer *)player matchEnded:(GKTurnBasedMatch *)match {
    NSLog(@"Game has ended");
    
    if ([match.matchID isEqualToString:self.currentMatch.matchID]) {
        [self.delegate recieveEndGame:match];
    } else {
        [self.delegate sendNotice:@"Another Game Ended!" forMatch:match];
    }
}

#pragma mark - UIViewController Methods
- (UIViewController*)getRootViewController {
    return [UIApplication sharedApplication].keyWindow.rootViewController;
}

-(void)presentViewController:(UIViewController*)viewController {
    UIViewController* rootVC = [self getRootViewController];
    [rootVC presentViewController:viewController animated:YES completion:nil];
}

#pragma mark - Game Center Score Methods
- (void)reportScore:(int64_t)score forLeaderboardID:(NSString*)identifier
{
    // Check if Game Center features are enabled
    if (!_gameCenterFeaturesEnabled) {
        NSLog(@"Player not authenticated");
        return;
    }
    
    GKScore *scoreReporter = [[GKScore alloc] initWithLeaderboardIdentifier:identifier];
    scoreReporter.value = score;
    scoreReporter.context = 0;
    
    // Set the default leaderboard
    scoreReporter.shouldSetDefaultLeaderboard = YES;
    
    NSArray *scores = @[scoreReporter];
    [GKScore reportScores:scores withCompletionHandler:^(NSError *error) {
        [self setLastError:error];
    }];
}

#pragma mark - Game Center Achievement Methods
// Report a single achievement
- (void)reportAchievementIdentifier:(NSString*)identifier percentComplete:(float)percent
{
    GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
    if (achievement)
    {
        achievement.percentComplete = percent;
        achievement.showsCompletionBanner = YES;
        [GKAchievement reportAchievements:[NSArray arrayWithObject:achievement] withCompletionHandler:^(NSError *error)
         {
             if (error != nil)
             {
                 NSLog(@"Error in reporting achievement: %@", error);
             }
         }];
    }
}

// Report multiple achievements
- (void)reportAchievements:(NSArray*)achievements
{
    [GKAchievement reportAchievements:achievements withCompletionHandler:^(NSError *error)
     {
         if (error != nil)
         {
             NSLog(@"Error in reporting achievements: %@", error);
         }
     }];
}

@end
