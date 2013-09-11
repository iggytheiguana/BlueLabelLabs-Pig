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

- (void)authenticationChanged {
    [super authenticationChanged];
    
    if ([GKLocalPlayer localPlayer].isAuthenticated && _playerAuthenticated) {
        [self getHighestGameScore];
        [self getTotalScore];
    }
    else if (![GKLocalPlayer localPlayer].isAuthenticated && !_playerAuthenticated) {
        
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


@end
