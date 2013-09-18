//
//  PIGGameConstants.h
//  pig
//
//  Created by Jordan Gurrieri on 9/6/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#ifndef pig_PIGGameConstants_h
#define pig_PIGGameConstants_h

// User Default Settings
#define kSettingsGameSpeed @"GameSpeedSetting"
#define kSettingsVibrate @"settingsvibrate"
#define kRollTutorialCompleted @"rolltutorialcompleted"

// Game Setup
#define kTurnBasedGameMaxPlayers 2
#define kTurnBasedGameMinPlayers 2

// User Scores
#define kTotalScorePlayer @"totalscoreplayer"
#define kHighestGameScorePlayer @"highestgamescoreplayer"

// Leaderboard Category IDs
#define kLeaderboardIdentifierTotalScore @"com.bluelabellabs.pig.totalscore"
#define kLeaderboardIdentifierHighestGameScore @"com.bluelabellabs.pig.highestgamescore"

// Achievement IDs
#define kAchievementIdentifierLandOn100 @"com.bluelabellabs.pig.achievement_landon100"
#define kAchievementIdentifierHighScore @"com.bluelabellabs.pig.achievement_highscore"
#define kAchievementIdentifierMassiveScore @"com.bluelabellabs.pig.achievement_massivescore"
#define kAchievementIdentifierStreak50 @"com.bluelabellabs.pig.achievement_streak50"
#define kAchievementIdentifierStreak75 @"com.bluelabellabs.pig.achievement_streak75"
#define kAchievementIdentifierPerfectRoll @"com.bluelabellabs.pig.achievement_perfectroll"
#define kAchievementIdentifierPerfectGame @"com.bluelabellabs.pig.achievement_perfectgame"

// Game Types
typedef enum {
    kONEPLAYERGAME,
    kTWOPLAYERGAMELOCAL,
    kTWOPLAYERGAMEGAMECENTER
} GameType;

#endif
