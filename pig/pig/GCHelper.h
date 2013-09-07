//
//  GCHelper.h
//  pig
//
//  Created by Jordan Gurrieri on 9/6/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

//   Protocol to notify external
//   objects when Game Center events occur or
//   when Game Center async tasks are completed
@protocol GCHelperDelegate < NSObject >

-(void) onScoresSubmitted:(bool)success;

@end

@interface GCHelper : NSObject {
    BOOL _gameCenterAvailable;
    BOOL _playerAuthenticated;
}

@property (nonatomic, assign) id<GCHelperDelegate> delegate;
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

@end
