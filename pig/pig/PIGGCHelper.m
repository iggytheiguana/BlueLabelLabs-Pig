//
//  PIGGCHelper.m
//  pig
//
//  Created by Jordan Gurrieri on 9/6/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGGCHelper.h"
#import "PIGGameConstants.h"

@implementation PIGGCHelper

static PIGGCHelper *sharedHelper = nil;

+ (PIGGCHelper *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelper = [[PIGGCHelper alloc] init];
    });
    return sharedHelper;
}

- (id)init {
    if ((self = [super init])) {
        _gameCenterAvailable = [self isGameCenterAvailable];
        if (_gameCenterAvailable) {
            NSNotificationCenter *nc =
            [NSNotificationCenter defaultCenter];
            [nc addObserver:self
                   selector:@selector(authenticationChanged)
                       name:GKPlayerAuthenticationDidChangeNotificationName
                     object:nil];
        }
    }
    return self;
}

#pragma mark - Instance Methods
//- (void)forceDeleteAllGames {
//    // We need to force a reset of all Game Center two player games if launching for the first time into v1.0.2
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    
//    // Get the app version from the User Defaults, and compare it to this version.
//    NSString* appVersionUser = [userDefaults objectForKey:kAppVersion];
//    
//    // Check if we have already performed this delete
//    BOOL deleteCompleted = [userDefaults boolForKey:kUpdatedToVersion1_0_2];
//    
//    if (deleteCompleted == NO &&
//        (appVersionUser == nil || ([@"1.0.2" caseInsensitiveCompare:appVersionUser] == NSOrderedDescending))) {
//        // This is the first run of the app since the update to v1.0.2.
//        // We need to delete all active Game Center matches
//        
//        [self deleteAllMatches];
//        
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUpdatedToVersion1_0_2];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    }
//}

- (void)authenticationChanged {
    [super authenticationChanged];
    
    if ([GKLocalPlayer localPlayer].isAuthenticated && _playerAuthenticated) {
//        // Due to change of MatchData format in v1.0.2 we need to delete all matches this user is a part of
//        [self forceDeleteAllGames];
        
        // Player authenticated
        [self getHighestGameScore];
        [self getTotalScore];
    }
    else if (![GKLocalPlayer localPlayer].isAuthenticated && !_playerAuthenticated) {
        // Player NOT authenticated
    }
}


#pragma mark - Game Center Score Methods
- (void)getHighestGameScore {
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] initWithPlayerIDs:[NSArray arrayWithObject:localPlayer.playerID]];
    leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime;
    leaderboardRequest.identifier = kLeaderboardIdentifierHighestGameScore;
    leaderboardRequest.range = NSMakeRange(1,1);
    if (leaderboardRequest != nil)
    {
        [leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
            if (error != nil)
            {
                // Handle the error
                
            }
            if (scores != nil)
            {
                // Save the score to the user defaults
                [[NSUserDefaults standardUserDefaults] setInteger:((GKScore*)[scores objectAtIndex:0]).value forKey:kHighestGameScorePlayer];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }];
    }
}

- (void)getTotalScore {
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] initWithPlayerIDs:[NSArray arrayWithObject:localPlayer.playerID]];
    leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime;
    leaderboardRequest.identifier = kLeaderboardIdentifierTotalScore;
    leaderboardRequest.range = NSMakeRange(1,1);
    if (leaderboardRequest != nil)
    {
        [leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
            if (error != nil)
            {
                // Handle the error
                
            }
            if (scores != nil)
            {
                // Save the score to the user defaults
                [[NSUserDefaults standardUserDefaults] setInteger:((GKScore*)[scores objectAtIndex:0]).value forKey:kTotalScorePlayer];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }];
    }
}

- (void)reportScore:(int64_t)score forLeaderboardID:(NSString*)identifier {
    [super reportScore:score forLeaderboardID:identifier];
    
    // Do anything else
    
    if ([identifier isEqualToString:kLeaderboardIdentifierHighestGameScore]) {
        // Save the new highest game score to the user defaults
        [[NSUserDefaults standardUserDefaults] setInteger:score forKey:kHighestGameScorePlayer];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if ([identifier isEqualToString:kLeaderboardIdentifierTotalScore]) {
        // Save the new total score to the user defaults
        [[NSUserDefaults standardUserDefaults] setInteger:score forKey:kTotalScorePlayer];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - Game Center Achievement Methods
// Report a single achievement
- (void)reportAchievementIdentifier:(NSString*)identifier percentComplete:(float)percent
{
    [super reportAchievementIdentifier:identifier percentComplete:percent];
    
    // Do anything else
    
}

// Report multiple achievements
- (void)reportAchievements:(NSArray*)achievements
{
    [super reportAchievements:achievements];
    
    // Do anything else
    
}

#pragma mark GKTurnBasedMatch Methods
- (void)playerQuitOutOfTurnForMatch:(GKTurnBasedMatch *)match {
    [match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeQuit withCompletionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            // delete the match from Game Center
            [match removeWithCompletionHandler:^(NSError *error) {
                if (error) {
                    NSLog(@"Error Removing Match %@", error.localizedDescription);
                }
                
                [self.delegate sendNotice:@"Match removed" forMatch:match];
            }];
        }
    }];
}

#pragma mark GKTurnBasedMatchmakerViewControllerDelegate
- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController playerQuitForMatch:(GKTurnBasedMatch *)match {
    NSLog(@"Player quit for Match, %@, %@", match, match.currentParticipant);
    
    NSUInteger currentIndex = [match.participants indexOfObject:match.currentParticipant];
    GKTurnBasedParticipant *participant;
    
    NSMutableArray *nextParticipants = [NSMutableArray array];
    for (int i = 0; i < [match.participants count]; i++) {
        participant = [match.participants objectAtIndex:(currentIndex + 1 + i) % match.participants.count];
        if (participant.matchOutcome == GKTurnBasedMatchOutcomeNone) {
            participant.matchOutcome = GKTurnBasedMatchOutcomeTied;
            [nextParticipants addObject:participant];
        }
    }
    
    if ([nextParticipants count] > 0) {
        // Quit the player out of the game, then delete the match
        [match participantQuitInTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                               nextParticipants:nextParticipants
                                    turnTimeout:600
                                      matchData:match.matchData
                              completionHandler:^(NSError *error) {
                                  if (error) {
                                      NSLog(@"Error Quiting Match %@", error);
                                  }
                                  else {
                                      // delete the match from Game Center
                                      [match removeWithCompletionHandler:^(NSError *error) {
                                          if (error) {
                                              NSLog(@"Error Removing Match %@", error.localizedDescription);
                                          }
                                          
                                          [self.delegate sendNotice:@"Match removed" forMatch:match];
                                      }];
                                  }
                              }];
    }
    else {
        // No other participants, delete the match from Game Center
        [match removeWithCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Error Removing Match %@", error.localizedDescription);
            }
            
            [self.delegate sendNotice:@"Match removed" forMatch:match];
        }];
    }
}


@end
