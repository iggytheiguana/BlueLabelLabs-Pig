//
//  PIGViewController.h
//  pig
//
//  Created by Jordan Gurrieri on 8/26/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PIGGCHelper.h"
#import "PIGRulesViewController.h"

@protocol PIGViewControllerDelegate <NSObject>
- (void)pigViewControllerDidClose;
@end

@interface PIGViewController : UIViewController < UIDynamicAnimatorDelegate, UIAlertViewDelegate, GKGameCenterControllerDelegate, PIGRulesViewControllerDelegate, GCHelperDelegate >

@property (weak, nonatomic) id <PIGViewControllerDelegate> delegate;

@property (nonatomic, assign) int gameType;

@property (strong, nonatomic) GKTurnBasedMatch *currentMatch;

@property (weak, nonatomic) IBOutlet UIButton *btn_dice1;
@property (weak, nonatomic) IBOutlet UIButton *btn_dice2;
@property (weak, nonatomic) IBOutlet UIButton *btn_pass;
@property (weak, nonatomic) IBOutlet UIButton *btn_playerReady;
@property (weak, nonatomic) IBOutlet UILabel *lbl_namePlayer1;
@property (weak, nonatomic) IBOutlet UILabel *lbl_namePlayer2;
@property (weak, nonatomic) IBOutlet UILabel *lbl_namePlayer1Small;
@property (weak, nonatomic) IBOutlet UILabel *lbl_namePlayer2Small;
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
@property (weak, nonatomic) IBOutlet UIButton *btn_rollTutorial;
@property (weak, nonatomic) IBOutlet UIButton *btn_quit;
@property (weak, nonatomic) IBOutlet UIButton *btn_rules;
@property (weak, nonatomic) IBOutlet UIView *v_progressView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *ai_progress;
@property (weak, nonatomic) IBOutlet UILabel *lbl_gameSpeed;

- (IBAction)onQuitButtonPressed:(id)sender;
- (IBAction)onPassButtonPressed:(id)sender;
- (IBAction)onDiceButtonPressed:(id)sender;
- (IBAction)onPlayerReadyButtonPressed:(id)sender;
- (IBAction)onNewGameButtonPressed:(id)sender;
- (IBAction)onGameSpeedValueChanged:(id)sender;
- (IBAction)onRollTutorialButtonPressed:(id)sender;

@end
