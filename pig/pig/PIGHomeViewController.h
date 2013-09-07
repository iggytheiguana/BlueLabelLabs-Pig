//
//  PIGHomeViewController.h
//  pig
//
//  Created by Jordan Gurrieri on 8/27/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface PIGHomeViewController : UIViewController < GKGameCenterControllerDelegate >

@property (weak, nonatomic) IBOutlet UIButton *btn_onePlayer;
@property (weak, nonatomic) IBOutlet UIButton *btn_twoPlayer;
@property (weak, nonatomic) IBOutlet UIButton *btn_buyTwoPlayer;
@property (weak, nonatomic) IBOutlet UILabel *lbl_buyText;
@property (weak, nonatomic) IBOutlet UIView *v_containerPlayerOne;
@property (weak, nonatomic) IBOutlet UIView *v_containerPlayerTwo;
@property (weak, nonatomic) IBOutlet UIButton *btn_leaderboard;

- (IBAction)onOnePlayerButtonPressed:(id)sender;
- (IBAction)onTwoPlayerButtonPressed:(id)sender;
- (IBAction)onBuyTwoPlayerButtonPressed:(id)sender;
- (IBAction)onRestoreIAPButtonPressed:(id)sender;
- (IBAction)onLeaderboardButtonPressed:(id)sender;

@end
