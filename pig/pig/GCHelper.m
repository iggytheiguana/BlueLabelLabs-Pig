//
//  GCHelper.m
//  pig
//
//  Created by Jordan Gurrieri on 9/6/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "GCHelper.h"

//@interface GCHelper () < GKGameCenterControllerDelegate >
//{
//    BOOL _gameCenterFeaturesEnabled;
//}
//@end

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
    
    // check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
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
        _playerAuthenticated = TRUE;
        _gameCenterFeaturesEnabled = YES;
    }
    else if (![GKLocalPlayer localPlayer].isAuthenticated && _playerAuthenticated) {
        NSLog(@"Authentication changed: player not authenticated");
        _playerAuthenticated = FALSE;
        _gameCenterFeaturesEnabled = NO;
    }
}

#pragma mark - User functions
- (void)authenticateLocalPlayer {
    if (!_gameCenterAvailable) return;
    
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        [self setLastError:error];
        
        if ([GKLocalPlayer localPlayer].authenticated) {
            _gameCenterFeaturesEnabled = YES;
        }
        else if (viewController) {
            [self presentViewController:viewController];
        }
        else {
            _gameCenterFeaturesEnabled = NO;
        }
    };
    
//    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
//    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
//        [self setLastError:error];
//        
//        if (viewController != nil)
//        {
//            [self showAuthenticationDialogWhenReasonable:viewController]
//        }
//        else if (localPlayer.isAuthenticated)
//        {
//            [self authenticatedPlayer: localPlayer];
//        }
//        else
//        {
//            [self disableGameCenter];
//        }
//    }];
    
//    NSLog(@"Authenticating local user...");
//    if ([GKLocalPlayer localPlayer].authenticated == NO) {
//        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:nil];
//    } else {
//        NSLog(@"Already authenticated!");
//    }
}

#pragma mark - Property Setters

- (void)setLastError:(NSError*)error {
    _lastError = [error copy];
    if (_lastError) {
        NSLog(@"GCHelper ERROR: %@", [[_lastError userInfo]
                                           description]);
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

@end
