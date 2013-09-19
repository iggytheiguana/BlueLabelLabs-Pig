//
//  Flurry+PIGFlurry.m
//  pig
//
//  Created by Jordan Gurrieri on 9/19/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "Flurry+PIGFlurry.h"
#import "PIGIAPHelper.h"
#import "PIGGCHelper.h"

@implementation Flurry (PIGFlurry)

+ (NSMutableDictionary *)flurryUserParams {
    // Setup Dictionary for Flurry user segmentation using Game Center IDs
    NSArray *powerUsers = [NSArray arrayWithObjects:
                           @"G:282278709",   //Jordan
                           nil];
    
    NSString *userType = @"Consumer";
    NSString *gameCenterStatus = @"Disabled";
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    if (localPlayer) {
        gameCenterStatus = @"Enabled";
        
        // Determine if this user is a power user
        if ([powerUsers indexOfObject:localPlayer.playerID] != NSNotFound) {
            userType = @"PowerUser";
        }
    }
    
    // In App Purchases
    BOOL twoPlayerProductPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:IAPUnlockTwoPlayerGameProductIdentifier];
    NSString *twoPlayerProductPurchasedString = @"NO";
    if (twoPlayerProductPurchased == YES)
        twoPlayerProductPurchasedString = @"YES";
    
    // App Version
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    
    // App State
#ifdef DEBUG
    NSString *appState = @"DEBUG";
#else
    NSString *appState = @"RELEASE";
#endif
    
    NSMutableDictionary *userParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       userType, @"User_Type", // Capture user type
                                       gameCenterStatus, @"GameCenter_Status", // Capture user's Game Center status
                                       twoPlayerProductPurchasedString, @"IAP_twoPlayer", // Capture paid vs free version
                                       appVersion, @"App_Version", // Capture app version number
                                       appState, @"App_State", // Capture app version number
                                       nil];
    
    return userParams;
}

@end
