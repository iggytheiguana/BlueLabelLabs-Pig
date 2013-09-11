//
//  GCHelper.h
//  pig
//
//  Created by Jordan Gurrieri on 9/6/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface GCHelper : NSObject {
    BOOL _gameCenterAvailable;
    BOOL _gameCenterFeaturesEnabled;
    BOOL _playerAuthenticated;
}

@property (assign, readonly) BOOL gameCenterAvailable;
@property (assign, readonly) BOOL playerAuthenticated;

// This property holds the last known error
// that occured while using the Game Center API's
@property (nonatomic, readonly) NSError* lastError;

+ (GCHelper *)sharedInstance;
- (BOOL)isGameCenterAvailable;
- (void)authenticationChanged;
- (void)authenticateLocalPlayer;
- (void)reportScore:(int64_t)score forLeaderboardID:(NSString*)identifier;
// Report a single achievement
- (void)reportAchievementIdentifier:(NSString*)identifier percentComplete:(float)percent;
// Report multiple achievements
- (void)reportAchievements:(NSArray*)achievements;

@end
