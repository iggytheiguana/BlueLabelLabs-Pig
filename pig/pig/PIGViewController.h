//
//  PIGViewController.h
//  pig
//
//  Created by Jordan Gurrieri on 8/26/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PIGGCHelper.h"

@interface PIGViewController : UIViewController < UIDynamicAnimatorDelegate, UIAlertViewDelegate, GKGameCenterControllerDelegate >

@property (nonatomic, assign) BOOL onePlayerGame;

@property (weak, nonatomic) IBOutlet UIButton *btn_dice1;
@property (weak, nonatomic) IBOutlet UIButton *btn_dice2;
@property (weak, nonatomic) IBOutlet UIButton *btn_pass;
@property (weak, nonatomic) IBOutlet UIButton *btn_playerReady;
@property (weak, nonatomic) IBOutlet UILabel *lbl_namePlayer1;
@property (weak, nonatomic) IBOutlet UILabel *lbl_namePlayer2;
@property (weak, nonatomic) IBOutlet UILabel *lbl_player1;
@property (weak, nonatomic) IBOutlet UILabel *lbl_player2;
@property (weak, nonatomic) IBOutlet UILabel *lbl_rollValue;
@property (weak, nonatomic) IBOutlet UIImageView *iv_rollImage;
@property (weak, nonatomic) IBOutlet UIView *v_containerPlayer1;
@property (weak, nonatomic) IBOutlet UIView *v_containerPlayer2;
@property (weak, nonatomic) IBOutlet UIImageView *iv_circlePlayer1;
@property (weak, nonatomic) IBOutlet UIImageView *iv_circlePlayer2;
@property (weak, nonatomic) IBOutlet UIView *v_containerRollValue;
@property (weak, nonatomic) IBOutlet UIButton *btn_newGame;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sgmt_gameSpeed;
@property (weak, nonatomic) IBOutlet UIImageView *iv_winImage;
@property (weak, nonatomic) IBOutlet UILabel *lbl_winnerPlayer1;
@property (weak, nonatomic) IBOutlet UILabel *lbl_winnerPlayer2;

- (IBAction)onHomeButtonPressed:(id)sender;
- (IBAction)onPassButtonPressed:(id)sender;
- (IBAction)onDiceButtonPressed:(id)sender;
- (IBAction)onPlayerReadyButtonPressed:(id)sender;
- (IBAction)onNewGameButtonPressed:(id)sender;
- (IBAction)onGameSpeedValueChanged:(id)sender;

@end
