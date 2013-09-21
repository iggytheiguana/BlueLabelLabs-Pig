//
//  PIGViewController.m
//  pig
//
//  Created by Jordan Gurrieri on 8/26/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioServices.h>
#import "PIGMotionEffect.h"
#import "UIColor+PIGCustomColors.h"
#import "PIGGCHelper.h"
#import "PIGGameConstants.h"
#import "Flurry+PIGFlurry.h"

#define kFASTGAME 1
#define kSLOWGAME 1.5

@interface PIGViewController () {
    UILabel *m_lbl_activePlayer;
    float _gameSpeedMultiplier;
    int _dice1;
    int _dice2;
    int _score1;
    int _score2;
    int _turnScore;
    int _doubleCount;
    int _turnThreshold;
    int _turnCountPlayer1;
    BOOL _canRollDice;
    BOOL _winner1;
    BOOL _winner2;
    BOOL _gameOver;
    BOOL _landedOn100;
    BOOL _perfectGamePlayer1;
    BOOL _vibrateOn;
    NSString *_namePlayer1;
    NSString *_namePlayer2;
    NSArray *_whiteDiceImages;
    NSMutableDictionary *_matchDataDict;
}

@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UISnapBehavior *player1SnapBehavior;
@property (nonatomic) UISnapBehavior *player2SnapBehavior;
@property (nonatomic) UIAttachmentBehavior *touchAttachmentBehavior;
@property (nonatomic) UIAttachmentBehavior *touchAttachmentBehavior2;

@end

@implementation PIGViewController

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Setup the Player Ready button
    [self.btn_playerReady.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.btn_playerReady.titleLabel setMinimumScaleFactor:0.5];
    [self.btn_playerReady.titleLabel setAdjustsFontSizeToFitWidth:YES];
    
    // Load the array of dice images
    NSArray *whiteDiceArray = [[NSArray alloc] initWithObjects:
                          [UIImage imageNamed:@"dice-white-1"],
                          [UIImage imageNamed:@"dice-white-2"],
                          [UIImage imageNamed:@"dice-white-3"],
                          [UIImage imageNamed:@"dice-white-4"],
                          [UIImage imageNamed:@"dice-white-5"],
                          [UIImage imageNamed:@"dice-white-6"],
                          nil];
    _whiteDiceImages = whiteDiceArray;
    
    // Get Player names
    if ([[PIGGCHelper sharedInstance] playerAuthenticated] == YES) {
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        _namePlayer1 = localPlayer.alias;
    }
    else {
        _namePlayer1 = @"Player 1";
    }
    [self.lbl_namePlayer1 setText:_namePlayer1];
    
    if (self.gameType == kONEPLAYERGAME) {
        _namePlayer2 = @"Computer";
    }
    else if (self.gameType == kTWOPLAYERGAMEGAMECENTER){
        _namePlayer2 = @"Opponent";
    }
    else {
        _namePlayer2 = @"Player 2";
    }
    [self.lbl_namePlayer2 setText:_namePlayer2];
    
    // Add dynamic animations to the player labels
    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    // First, move the player 1 label into position at the edge of the screen
    self.v_containerPlayer1.center = CGPointMake(self.v_containerPlayer1.center.x+101, self.v_containerPlayer1.center.y);
    
    // Add Snap Behaviors to the labels
    UISnapBehavior *player1Snap = [[UISnapBehavior alloc] initWithItem:self.v_containerPlayer1 snapToPoint:CGPointMake(self.v_containerPlayer1.center.x-101, self.v_containerPlayer1.center.y)];
    self.player1SnapBehavior = player1Snap;
    UISnapBehavior *player2Snap = [[UISnapBehavior alloc] initWithItem:self.v_containerPlayer2 snapToPoint:CGPointMake(self.v_containerPlayer2.center.x-101, self.v_containerPlayer2.center.y)];
    self.player2SnapBehavior = player2Snap;
    
    [animator addBehavior:self.player1SnapBehavior];
    [animator addBehavior:self.player2SnapBehavior];
    
    // Add Snap Behaviors to the dice
    UISnapBehavior *dice1Snap = [[UISnapBehavior alloc] initWithItem:self.btn_dice1 snapToPoint:CGPointMake(self.btn_dice1.center.x, self.btn_dice1.center.y)];
    UISnapBehavior *dice2Snap = [[UISnapBehavior alloc] initWithItem:self.btn_dice2 snapToPoint:CGPointMake(self.btn_dice2.center.x, self.btn_dice2.center.y)];
    
    [animator addBehavior:dice1Snap];
    [animator addBehavior:dice2Snap];
    
//    // Add Collision Behavior to the dice
//    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:[NSArray arrayWithObjects:self.btn_dice1, self.btn_dice2, nil]];
//    collisionBehavior.translatesReferenceBoundsIntoBoundary = NO;
//    [animator addBehavior:collisionBehavior];
    
    self.animator = animator;
    
    // We need to handle touch events on the dice buttons so that we can give them animations when touched
    [self.btn_dice1 addTarget:self action:@selector(dragBegan:withEvent:) forControlEvents: UIControlEventTouchDown];
    [self.btn_dice1 addTarget:self action:@selector(dragMoving:withEvent:) forControlEvents: UIControlEventTouchDragInside];
    [self.btn_dice1 addTarget:self action:@selector(dragEnded:withEvent:) forControlEvents: UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [self.btn_dice2 addTarget:self action:@selector(dragBegan:withEvent:) forControlEvents: UIControlEventTouchDown];
    [self.btn_dice2 addTarget:self action:@selector(dragMoving:withEvent:) forControlEvents: UIControlEventTouchDragInside];
    [self.btn_dice2 addTarget:self action:@selector(dragEnded:withEvent:) forControlEvents: UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    
    // Give the dice, roll label, and roll images a shadow that will add to the motion effect
    self.btn_dice1.layer.shadowColor = [UIColor blackColor].CGColor;
    self.btn_dice1.layer.shadowOpacity = 0.2f;
    self.btn_dice1.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.btn_dice1.layer.shadowRadius = 0.0f;
    
    self.btn_dice2.layer.shadowColor = [UIColor blackColor].CGColor;
    self.btn_dice2.layer.shadowOpacity = 0.2f;
    self.btn_dice2.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.btn_dice2.layer.shadowRadius = 0.0f;
    
//    self.lbl_rollValue.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.lbl_rollValue.layer.shadowOpacity = 0.3f;
//    self.lbl_rollValue.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
//    self.lbl_rollValue.layer.shadowRadius = 0.0f;
//    
//    self.iv_rollImage.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.iv_rollImage.layer.shadowOpacity = 0.3f;
//    self.iv_rollImage.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
//    self.iv_rollImage.layer.shadowRadius = 0.0f;
//    
//    self.iv_winImage.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.iv_winImage.layer.shadowOpacity = 0.3f;
//    self.iv_winImage.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
//    self.iv_winImage.layer.shadowRadius = 0.0f;
    
//    self.v_containerPlayer1.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.v_containerPlayer1.layer.shadowOpacity = 0.3f;
//    self.v_containerPlayer1.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
//    self.v_containerPlayer1.layer.shadowRadius = 0.0f;
    
    // Add motion effects to dice
    PIGMotionEffect *motionEffect = [[PIGMotionEffect alloc] init];
    [self.btn_dice1 addMotionEffect:motionEffect];
    [self.btn_dice2 addMotionEffect:motionEffect];
//    [self.lbl_rollValue addMotionEffect:motionEffect];
//    [self.iv_rollImage addMotionEffect:motionEffect];
//    [self.iv_winImage addMotionEffect:motionEffect];
//    [self.v_containerPlayer1 addMotionEffect:motionEffect];
    
    // Setup game speed from user's last setting
    _gameSpeedMultiplier = [[NSUserDefaults standardUserDefaults] floatForKey:kSettingsGameSpeed];
    if (_gameSpeedMultiplier == 0) {
        // Default to slow game speed
        _gameSpeedMultiplier = kSLOWGAME;
        
        // Save setting to user defaults
        [[NSUserDefaults standardUserDefaults] setFloat:_gameSpeedMultiplier forKey:kSettingsGameSpeed];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (_gameSpeedMultiplier == kSLOWGAME) {
        [self.sgmt_gameSpeed setSelectedSegmentIndex:0];
    }
    else {
        [self.sgmt_gameSpeed setSelectedSegmentIndex:1];
    }
    
    // Setup vibrate setting from user defaults
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kSettingsVibrate]) {
        _vibrateOn = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsVibrate];
    }
    else {
        // Default to ON
        _vibrateOn = YES;
        
        // Save setting to user defaults
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSettingsVibrate];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (self.gameType == kTWOPLAYERGAMEGAMECENTER) {
//        [[PIGGCHelper sharedInstance] findMatchWithMinPlayers:kTurnBasedGameMinPlayers maxPlayers:kTurnBasedGameMaxPlayers viewController:self showExistingMatches:YES];
//        [PIGGCHelper sharedInstance].delegate = self;
        
        _matchDataDict = [[NSMutableDictionary alloc] init];
        
//        [self enterNewGame:nil];
    }
    
    // Hide the roll tutorial if the user has already seen it
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kRollTutorialCompleted]) {
        [self.btn_rollTutorial removeFromSuperview];
    }
    else {
        [self.view bringSubviewToFront:self.btn_rollTutorial];
    }
    
    // Setup the start of the game
    [self reset];
    
    // Used for testing
//    _score1 = 99;
//    _score2 = 99;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [Flurry logEvent:@"GAMEPLAY_SCREEN_VIEWING" withParameters:[Flurry flurryUserParams] timed:YES];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [Flurry endTimedEvent:@"GAMEPLAY_SCREEN_VIEWING" withParameters:[Flurry flurryUserParams]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - Storyboard Methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"GamePlay_to_Rules"])
	{
		PIGRulesViewController *rulesViewController = segue.destinationViewController;
        rulesViewController.delegate = self;
	}
}

#pragma mark - PIGRulesViewController Delegate
- (void)pigRulesViewControllerDidClose {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Instance Methods
- (void)dragBegan:(UIControl *)control withEvent:event {
    UIButton *diceButton = (UIButton *)control;
    
    UIAttachmentBehavior *touchAttachmentBehavior;
    UIAttachmentBehavior *touchAttachmentBehavior2;
    
    if (diceButton == self.btn_dice1) {
        touchAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.btn_dice1
                                                            attachedToAnchor:self.btn_dice1.center];
        touchAttachmentBehavior2 = [[UIAttachmentBehavior alloc] initWithItem:self.btn_dice2
                                                             attachedToAnchor:self.btn_dice1.center];
    }
    else {
        // Dice 2 button pressed
        touchAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.btn_dice2
                                                            attachedToAnchor:self.btn_dice2.center];
        touchAttachmentBehavior2 = [[UIAttachmentBehavior alloc] initWithItem:self.btn_dice1
                                                             attachedToAnchor:self.btn_dice2.center];
    }
    
    [self.animator addBehavior:touchAttachmentBehavior];
    [touchAttachmentBehavior setFrequency:5.0];
    [touchAttachmentBehavior setDamping:0.1];
    
    [touchAttachmentBehavior setFrequency:5.0];
    [touchAttachmentBehavior2 setDamping:0.1];
    [self.animator addBehavior:touchAttachmentBehavior2];
    
    self.touchAttachmentBehavior = touchAttachmentBehavior;
    self.touchAttachmentBehavior2 = touchAttachmentBehavior2;
}

- (void)dragMoving:(UIControl *)control withEvent:event {
    UITouch *touch = [[event allTouches] anyObject];
    self.touchAttachmentBehavior.anchorPoint = [touch locationInView:self.view];
    self.touchAttachmentBehavior2.anchorPoint = [touch locationInView:self.view];
}

- (void)dragEnded:(UIControl *)control withEvent:event {
    [Flurry logEvent:@"GAMEPLAY_SCREEN_DRAG" withParameters:[Flurry flurryUserParams]];
    
    [self.animator removeBehavior:self.touchAttachmentBehavior];
    [self.animator removeBehavior:self.touchAttachmentBehavior2];
}

- (void)diceShadows:(BOOL)showShadow {
    if (showShadow == YES) {
        // Give the dice, roll label, and roll images a shadow that will add to the motion effect
        self.btn_dice1.layer.shadowColor = [UIColor blackColor].CGColor;
        self.btn_dice1.layer.shadowOpacity = 0.3f;
        self.btn_dice1.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.btn_dice1.layer.shadowRadius = 0.0f;
        
        self.btn_dice2.layer.shadowColor = [UIColor blackColor].CGColor;
        self.btn_dice2.layer.shadowOpacity = 0.3f;
        self.btn_dice2.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.btn_dice2.layer.shadowRadius = 0.0f;
    }
    else {
        // Give the dice, roll label, and roll images a shadow that will add to the motion effect
        self.btn_dice1.layer.shadowColor = [UIColor clearColor].CGColor;
        self.btn_dice1.layer.shadowOpacity = 0.0f;
        self.btn_dice1.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.btn_dice1.layer.shadowRadius = 0.0f;
        
        self.btn_dice2.layer.shadowColor = [UIColor clearColor].CGColor;
        self.btn_dice2.layer.shadowOpacity = 0.0f;
        self.btn_dice2.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.btn_dice2.layer.shadowRadius = 0.0f;
    }
}

- (void)vibrate {
    if (_vibrateOn == YES) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

- (void)reset {
    // Reset gameplay instance variables
    _score1 = 0;
    _score2 = 0;
    _turnScore = 0;
    _doubleCount = 0;
    _turnCountPlayer1 = 0;
    _winner1 = NO;
    _winner2 = NO;
    _gameOver = NO;
    _landedOn100 = NO;
    _perfectGamePlayer1 = YES;
    
    // Setup Player 1 to start the game
    [self playerOneActive];
    
//    [self.btn_playerReady setBackgroundImage:[UIImage imageNamed:@"button-bg-large-pink.png"] forState:UIControlStateNormal];
//    [self.btn_playerReady setTitle:[NSString stringWithFormat:@"Player 1 Ready"] forState:UIControlStateNormal];
    
    [self.lbl_player1 setText:[NSString stringWithFormat:@"%d", _score1]];
    [self.lbl_player2 setText:[NSString stringWithFormat:@"%d", _score2]];
    
    // Setup Button and Label states
    [self.lbl_rollValue setHidden:YES];
    [self.iv_rollImage setHidden:YES];
    [self.iv_winImage setHidden:YES];
    [self.btn_dice1 setHidden:YES];
    [self.btn_dice2 setHidden:YES];
    [self.btn_playerReady setEnabled:YES];
    [self.btn_pass setHidden:YES];
    [self.btn_newGame setHidden:YES];
    [self.lbl_winnerPlayer1 setHidden:YES];
    [self.lbl_winnerPlayer2 setHidden:YES];
    
    [self.btn_playerReady setHidden:NO];
    
    [self.btn_dice1 setImage:[_whiteDiceImages objectAtIndex:0] forState:UIControlStateNormal];
    [self.btn_dice2 setImage:[_whiteDiceImages objectAtIndex:0] forState:UIControlStateNormal];
}

- (int)getRollValue {
    _dice1 = arc4random_uniform(6) + 1;
    _dice2 = arc4random_uniform(6) + 1;
    
    if (_dice1 == 1 && _dice2 == 1) {
        // Snake eyes rolled
        [self.btn_dice1 setAdjustsImageWhenDisabled:NO];
        [self.btn_dice2 setAdjustsImageWhenDisabled:NO];
        [self.btn_dice1 setImage:[UIImage imageNamed:@"dice-red-1.png"] forState:UIControlStateNormal];
        [self.btn_dice2 setImage:[UIImage imageNamed:@"dice-red-1.png"] forState:UIControlStateNormal];
    }
    else {
        [self.btn_dice1 setAdjustsImageWhenDisabled:YES];
        [self.btn_dice2 setAdjustsImageWhenDisabled:YES];
        [self.btn_dice1 setImage:[_whiteDiceImages objectAtIndex:_dice1-1] forState:UIControlStateNormal];
        [self.btn_dice2 setImage:[_whiteDiceImages objectAtIndex:_dice2-1] forState:UIControlStateNormal];
    }
    
    int rollValue = _dice1 + _dice2;
    
    if (rollValue == 2) {
        // Snake eyes!
        _doubleCount = 0;
    }
    else if (_dice1 == _dice2) {
        // Doubles rolled
        _doubleCount++;
        rollValue = 2*rollValue;
    }
    else {
        // Normal roll (including 7)
        _doubleCount = 0;
    }
    
    return rollValue;
}

- (void)rollDice {
    // Disable the dice until the roll is complete
    _canRollDice = NO;
    
    [self.btn_dice1 setEnabled:NO];
    [self.btn_dice2 setEnabled:NO];
    
    // Get the new roll value
    int rollValue = [self getRollValue];
    
    // Determine which player score to update based on which player is active
    int currentPlayerScore = 0;
    if (m_lbl_activePlayer == self.lbl_player1) {
        currentPlayerScore = _score1;
    }
    else {
        currentPlayerScore = _score2;
    }
    
    // Prepare the result of the roll to present to the user
    BOOL turnEnded = NO;
    [self.btn_pass setEnabled:NO];
    [self.btn_pass setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    
    if (rollValue == 2) {
        // Snake eyes!
        // Player score goes back to 0 and turn is over
        turnEnded = YES;
        currentPlayerScore = 0;
        
        [self.lbl_rollValue setTextColor:[UIColor pigRedColor]];
        [self.lbl_rollValue setText:[NSString stringWithFormat:@"1-1"]];
        
        [self.btn_pass setTitleColor:[UIColor pigRedColor] forState:UIControlStateNormal];
        [self.btn_pass setTitle:[NSString stringWithFormat:@"Double 1's rolled!"] forState:UIControlStateNormal];
    }
    else if (_doubleCount >= 3) {
        // 3 doubles rolled in a row, PIG
        // Player score goes back to 0 and turn is over
        turnEnded = YES;
        currentPlayerScore = 0;
        
        [self.lbl_rollValue setTextColor:[UIColor pigRedColor]];
        [self.lbl_rollValue setText:[NSString stringWithFormat:@"%d-%d", _dice1, _dice2]];
        
        [self.btn_pass setTitleColor:[UIColor pigRedColor] forState:UIControlStateNormal];
        [self.btn_pass setTitle:[NSString stringWithFormat:@"%d Doubles!!!", _doubleCount] forState:UIControlStateNormal];
    }
    else if (rollValue == 7) {
        // 7 rolled, PIG
        // Player loses all points from that turn and turn is over
        turnEnded = YES;
        currentPlayerScore = currentPlayerScore - _turnScore;
        
        [self.lbl_rollValue setTextColor:[UIColor pigRedColor]];
        [self.lbl_rollValue setText:[NSString stringWithFormat:@"7"]];
        
        [self.btn_pass setTitleColor:[UIColor pigRedColor] forState:UIControlStateNormal];
        [self.btn_pass setTitle:[NSString stringWithFormat:@"7 rolled!"] forState:UIControlStateNormal];
    }
    else {
        // Safe roll
        // Player's score is incremented
        _turnScore = _turnScore + rollValue;
        currentPlayerScore = currentPlayerScore + rollValue;
        
        if (currentPlayerScore == 100) {
            // Player landed on exactly 100!
            // Player score goes back to 0 and turn is over
            _landedOn100 = YES;
            turnEnded = YES;
            currentPlayerScore = 0;
            
            [self.lbl_rollValue setTextColor:[UIColor pigRedColor]];
            [self.lbl_rollValue setText:[NSString stringWithFormat:@"+%d", rollValue]];
            
            [self.btn_pass setTitleColor:[UIColor pigRedColor] forState:UIControlStateNormal];
            [self.btn_pass setTitle:[NSString stringWithFormat:@"Landed on 100!"] forState:UIControlStateNormal];
        }
        else {
            // Everything is OK. Player can roll again
            
            [self.btn_pass setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            
            if (m_lbl_activePlayer == self.lbl_player1) {
                // Player 1's turn
                [self.lbl_rollValue setTextColor:[UIColor pigLightPinkColor]];
            }
            else {
                // Player 2 or computer's turn
                [self.lbl_rollValue setTextColor:[UIColor pigLightBlueColor]];
            }
            [self.lbl_rollValue setText:[NSString stringWithFormat:@"+%d", rollValue]];
            
            if (_doubleCount == 2) {
                [self.btn_pass setTitle:[NSString stringWithFormat:@"%d Doubles!! (roll again)", _doubleCount] forState:UIControlStateNormal];
            }
            else if (_doubleCount == 1) {
                [self.btn_pass setTitle:[NSString stringWithFormat:@"%d Double! (roll again)", _doubleCount] forState:UIControlStateNormal];
            }
            else {
                [self.btn_pass setTitle:[NSString stringWithFormat:@"Roll again or HOLD"] forState:UIControlStateNormal];
            }
        }
    }
    
    // If the roll was turn ending, we vibrate the phone.
    if (turnEnded == YES) {
        [self vibrate];
        
        // If the turn ended and this was player 1's turn, they cannot earn the perfect game achievement
        if (m_lbl_activePlayer == self.lbl_player1) {
            _perfectGamePlayer1 = NO;
        }
    }
    
    // Now, update the active player's global score variable
    if (m_lbl_activePlayer == self.lbl_player1) {
        _score1 = currentPlayerScore;
        
        // Check if any achievements were earned on this roll
        [self checkAchievements];
    }
    else {
        _score2 = currentPlayerScore;
    }
    
    // Animate the showing of the make word container views
    UIView *rollView;
    if (turnEnded == YES && rollValue == 2) {
        // Snake eyes!
        [self.iv_rollImage setImage:[UIImage imageNamed:@"snake.png"]];
        rollView = self.iv_rollImage;
    }
    else if (turnEnded == YES) {
        [self.iv_rollImage setImage:[UIImage imageNamed:@"pig.png"]];
        rollView = self.iv_rollImage;
    }
    else {
        rollView = self.lbl_rollValue;
    }
    
    [self diceShadows:NO];
    
    [rollView setAlpha:0.0];
    [rollView setHidden:NO];
    rollView.transform = CGAffineTransformMakeScale(0.3, 0.3);
    
    [UIView animateWithDuration:0.75*_gameSpeedMultiplier
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         rollView.transform = CGAffineTransformRotate(rollView.transform, -M_PI / 2.0);
                         rollView.transform = CGAffineTransformMakeScale(1.05, 1.05);
                         rollView.alpha = 0.8;
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.25*_gameSpeedMultiplier
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              rollView.transform = CGAffineTransformMakeScale(0.9, 0.9);
                                              rollView.alpha = 0.9;
                                          }
                                          completion:^(BOOL finished){
                                              [UIView animateWithDuration:0.25*_gameSpeedMultiplier
                                                                    delay:0.0
                                                                  options:UIViewAnimationOptionCurveEaseInOut
                                                               animations:^{
                                                                   rollView.transform = CGAffineTransformIdentity;
                                                                   rollView.alpha = 1.0;
                                                               }
                                                               completion:^(BOOL finished){
                                                                   [UIView animateWithDuration:0.35*_gameSpeedMultiplier
                                                                                         delay:0.0
                                                                                       options:UIViewAnimationOptionCurveEaseInOut
                                                                                    animations:^{
                                                                                        rollView.transform = CGAffineTransformRotate(rollView.transform, M_PI);
                                                                                        rollView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                                                                                        rollView.alpha = 0.0;
                                                                                    }
                                                                                    completion:^(BOOL finished){
                                                                                        [rollView setAlpha:0.0];
                                                                                        [rollView setHidden:YES];
                                                                                        rollView.transform = CGAffineTransformIdentity;
                                                                                        
                                                                                        [self diceShadows:YES];
                                                                                        
                                                                                        [m_lbl_activePlayer setText:[NSString stringWithFormat:@"%d", currentPlayerScore]];
                                                                                        
                                                                                        [self.btn_dice1 setEnabled:YES];
                                                                                        [self.btn_dice2 setEnabled:YES];
                                                                                        
                                                                                        // Determine if the current player can roll again or not
                                                                                        if (turnEnded == YES) {
                                                                                            // Turn is over, toggle the active player
                                                                                            [self onPassButtonPressed:nil];
                                                                                        }
                                                                                        else if (self.gameType == kONEPLAYERGAME && m_lbl_activePlayer == self.lbl_player2) {
                                                                                            // Computer's turn
                                                                                            if (currentPlayerScore >= _turnThreshold && _doubleCount == 0) {
                                                                                                // Computer has passed turn threshold and not in a state of rolling doubles, toggle the active player
                                                                                                [self onPassButtonPressed:nil];
                                                                                            }
                                                                                            else {
                                                                                                [self computerTurn];
                                                                                            }
                                                                                        }
                                                                                        else if (_doubleCount == 0) {
                                                                                            // Player can roll again or Pass
                                                                                            [self.btn_pass setEnabled:YES];
                                                                                            [self.btn_pass setTitleColor:[UIColor pigBlueColor] forState:UIControlStateNormal];
                                                                                            [self.btn_pass setTitle:[NSString stringWithFormat:@"HOLD"] forState:UIControlStateNormal];
                                                                                        }
                                                                                        
                                                                                        // Reset state properties
                                                                                        _canRollDice = YES;
                                                                                    }
                                                                    ];
                                                               }
                                               ];
                                          }
                          ];
                     }
     ];
}

- (int)computerTurnScoreThreshold {
    NSInteger thresholds[3];    // We'll store 3 risk threshold values conservative-moderate-aggresive
    int thresholdMax = 0;
    
    if (_score1 >= 101 && _score2 >= 101) {
        // Both player and computer above 101
        if (_score1 >= _score2) {
            // Player one has chance of winning
            thresholds[0] = _score1 + 1;
            thresholds[1] = _score1 + 10;
            thresholds[2] = _score1 + 25;
        }
        else {
            // Computer has chance of winning.
            thresholds[0] = 101;
            thresholds[1] = 101;
            thresholds[2] = _score1 + 25;
        }
    }
    else if (_score1 >= 101 && _score2 < 101) {
        // Player one has chance of winning
        thresholds[0] = _score1 + 1;
        thresholds[1] = _score1 + 10;
        thresholds[2] = _score1 + 25;
    }
    else if (_score2 >= 101 && _score1 < 101) {
        // Computer has chance of winning.
        thresholds[0] = 101;
        thresholds[1] = 101;
        thresholds[2] = _score2 + 25;
    }
    else if (_score1 > _score2) {
        // Player one is ahead of computer
        int difference = _score1 - _score2;
        int pointsToWin = 101 - _score2;
        
        if (difference >= 50) {
            thresholds[0] = _score2 + difference - 20;
            thresholds[1] = _score2 + difference + 2;
            thresholds[2] = _score2 + difference + 30;
        }
        else {
            thresholds[0] = _score2 + 10;
            thresholds[1] = _score2 + difference + 2;
            thresholds[2] = _score2 + pointsToWin + 5;
        }
    }
    else if (_score2 >= _score1) {
        // Computer is ahead or tied with player one
        int pointsToWin = 101 - _score2;
        
        if (pointsToWin >= 50) {
            thresholds[0] = _score2 + 25;
            thresholds[1] = _score2 + 50;
            thresholds[2] = _score2 + pointsToWin + 10;
        }
        else {
            thresholds[0] = 101;
            thresholds[1] = 101;
            thresholds[2] = 121;
        }
    }
    
    thresholdMax = thresholds[arc4random_uniform(3)];   // randomly choose risk threshold
    
    int lowerBound = _score2;
    int upperBound = thresholdMax;
    int retValue = (lowerBound + arc4random() % (upperBound - lowerBound)) + 1;
    
    return retValue;
}

- (void)computerTurn {
    _canRollDice = NO;
    
    // Disable the Pass button until the roll is complete
    [self.btn_pass setHidden:NO];
    [self.btn_pass setEnabled:NO];
    [self.btn_pass setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.btn_pass setTitle:@"HOLD" forState:UIControlStateNormal];
    
    [self rollDice];
}

- (void)playerOneActive {
    if (m_lbl_activePlayer == self.lbl_player2) {
        [self.animator removeBehavior:self.player1SnapBehavior];
        [self.animator removeBehavior:self.player2SnapBehavior];
        
        UISnapBehavior *player1Snap = [[UISnapBehavior alloc] initWithItem:self.v_containerPlayer1 snapToPoint:CGPointMake(self.v_containerPlayer1.center.x-101, self.v_containerPlayer1.center.y)];
        self.player1SnapBehavior = player1Snap;
        UISnapBehavior *player2Snap = [[UISnapBehavior alloc] initWithItem:self.v_containerPlayer2 snapToPoint:CGPointMake(self.v_containerPlayer2.center.x-101, self.v_containerPlayer2.center.y)];
        self.player2SnapBehavior = player2Snap;
        
        [self.animator addBehavior:self.player1SnapBehavior];
        [self.animator addBehavior:self.player2SnapBehavior];
    }
    
    [self.iv_circlePlayer1 setHidden:NO];
    [self.iv_circlePlayer2 setHidden:YES];
    [self.lbl_player1 setTextColor:[UIColor pigBlueColor]];
    [self.lbl_player2 setTextColor:[UIColor whiteColor]];
    
    // Setup the Player Ready button
    [self.btn_playerReady setBackgroundImage:[UIImage imageNamed:@"button-bg-large-pink.png"] forState:UIControlStateNormal];
    if (_score2 >= 101 && _score2 > _score1) {
        [self.btn_playerReady setTitle:[NSString stringWithFormat:@"%@\nLast Chance!", _namePlayer1] forState:UIControlStateNormal];
    }
    else {
        [self.btn_playerReady setTitle:[NSString stringWithFormat:@"%@\nReady?", _namePlayer1] forState:UIControlStateNormal];
    }
    
    m_lbl_activePlayer = self.lbl_player1;
}

- (void)playerTwoActive {
    if (m_lbl_activePlayer == self.lbl_player1) {
        [self.animator removeBehavior:self.player1SnapBehavior];
        [self.animator removeBehavior:self.player2SnapBehavior];
        
        UISnapBehavior *player1Snap = [[UISnapBehavior alloc] initWithItem:self.v_containerPlayer1 snapToPoint:CGPointMake(self.v_containerPlayer1.center.x+101, self.v_containerPlayer1.center.y)];
        self.player1SnapBehavior = player1Snap;
        UISnapBehavior *player2Snap = [[UISnapBehavior alloc] initWithItem:self.v_containerPlayer2 snapToPoint:CGPointMake(self.v_containerPlayer2.center.x+101, self.v_containerPlayer2.center.y)];
        self.player2SnapBehavior = player2Snap;
        
        [self.animator addBehavior:self.player1SnapBehavior];
        [self.animator addBehavior:self.player2SnapBehavior];
    }
    
    [self.iv_circlePlayer1 setHidden:YES];
    [self.iv_circlePlayer2 setHidden:NO];
    [self.lbl_player1 setTextColor:[UIColor whiteColor]];
    [self.lbl_player2 setTextColor:[UIColor pigBlueColor]];
    
    // Setup the Player Ready button
    [self.btn_playerReady setBackgroundImage:[UIImage imageNamed:@"button-bg-large-blue.png"] forState:UIControlStateNormal];
    if (_score1 >= 101 && _score1 > _score2) {
        [self.btn_playerReady setTitle:[NSString stringWithFormat:@"%@\nLast Chance!", _namePlayer2] forState:UIControlStateNormal];
    }
    else {
        [self.btn_playerReady setTitle:[NSString stringWithFormat:@"%@\nReady?", _namePlayer2] forState:UIControlStateNormal];
    }
    
    m_lbl_activePlayer = self.lbl_player2;
}

#pragma mark - Phone Shake Handler
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.subtype == UIEventSubtypeMotionShake )
    {
        // User shook the device, we roll only if player is active and state is ready.
        [Flurry logEvent:@"GAMEPLAY_SCREEN_SHAKE" withParameters:[Flurry flurryUserParams]];
        
        if (self.gameType == kONEPLAYERGAME && m_lbl_activePlayer == self.lbl_player2) {
            // Do nothing, it is the computer's turn
            
        }
        else if (_canRollDice == YES) {
            [self onDiceButtonPressed:nil];
        }
    }
    
    if ([super respondsToSelector:@selector(motionEnded:withEvent:)]) {
        [super motionEnded:motion withEvent:event];
    }
}

#pragma mark - Game Center Methods
- (void)checkAchievements {
    // Achievements are not supported for Multiplayer games
    if (self.gameType == kTWOPLAYERGAMEGAMECENTER)
        return;
    
    NSMutableArray* achievements = [[NSMutableArray alloc] init];
    
    // Land on 100 - Land on a score of exactly 100
    if (_landedOn100 == YES) {
        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:kAchievementIdentifierLandOn100];
        achievement.percentComplete = 100.0;
        achievement.showsCompletionBanner = YES;
        
        [achievements addObject:achievement];
    }
    
    // High Score - Earn 150 or more points in a single game
    if (_gameOver == YES && _score1 >= 150 && _winner1 == YES) {
        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:kAchievementIdentifierHighScore];
        achievement.percentComplete = 100.0;
        achievement.showsCompletionBanner = YES;
        
        [achievements addObject:achievement];
    }
    
    // Massive Score - Earn 250 or more points in a single game
    if (_gameOver == YES && _score1 >= 250 && _winner1 == YES) {
        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:kAchievementIdentifierMassiveScore];
        achievement.percentComplete = 100.0;
        achievement.showsCompletionBanner = YES;
        
        [achievements addObject:achievement];
    }
    
    // Streak 50 - Earn 50 or more points in one turn
    if (_turnScore >= 50) {
        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:kAchievementIdentifierStreak50];
        achievement.percentComplete = 100.0;
        achievement.showsCompletionBanner = YES;
        
        [achievements addObject:achievement];
    }
    
    // Streak 75 - Earn 75 or more points in one turn
    if (_turnScore >= 75) {
        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:kAchievementIdentifierStreak75];
        achievement.percentComplete = 100.0;
        achievement.showsCompletionBanner = YES;
        
        [achievements addObject:achievement];
    }
    
    // Perfect Roll - Win a game in just one turn
    if (_gameOver == YES && _turnCountPlayer1 == 1 && _perfectGamePlayer1 == YES) {
        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:kAchievementIdentifierPerfectRoll];
        achievement.percentComplete = 100.0;
        achievement.showsCompletionBanner = YES;
        
        [achievements addObject:achievement];
    }
    
    // Perfect Game - Win a game without losing any points
    if (_gameOver == YES && _perfectGamePlayer1 == YES) {
        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:kAchievementIdentifierPerfectGame];
        achievement.percentComplete = 100.0;
        achievement.showsCompletionBanner = YES;
        
        [achievements addObject:achievement];
    }
    
    if([achievements count] > 0) {
        [[PIGGCHelper sharedInstance] reportAchievements:achievements];
    }
}

- (void)showLeaderboard:(NSString*)leaderboardID {
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.viewState = GKGameCenterViewControllerStateLeaderboards;
        gameCenterController.leaderboardIdentifier = leaderboardID;
        
        [self presentViewController:gameCenterController animated:YES completion:nil];
    }
}

- (void)reportPlayerScore:(int)playerScore {
    // Report the scores to Game Center and save in User Deafults
    int64_t totalScore = [[NSUserDefaults standardUserDefaults] integerForKey:kTotalScorePlayer];
    totalScore = totalScore + playerScore;
    
    int64_t highestGameScore = [[NSUserDefaults standardUserDefaults] integerForKey:kHighestGameScorePlayer];
    
    if ((int64_t)_score1 > highestGameScore) {
        [[PIGGCHelper sharedInstance] reportScore:(int64_t)playerScore forLeaderboardID:kLeaderboardIdentifierHighestGameScore];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New High Score!"
                                                        message:@"You beat your highest single game score. View your rank in the Leaderboard?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Leaderboard", nil];
        [alert show];
    }
    [[PIGGCHelper sharedInstance] reportScore:totalScore forLeaderboardID:kLeaderboardIdentifierTotalScore];
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)quitMatch:(GKTurnBasedMatch *)match {
    if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
        [PIGGCHelper sharedInstance].delegate = self;
        [[PIGGCHelper sharedInstance] turnBasedMatchmakerViewController:nil playerQuitForMatch:match];
    }
    else {
        [PIGGCHelper sharedInstance].delegate = self;
        [match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeQuit withCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    }
    
    [match removeWithCompletionHandler:^(NSError *error) {
        
    }];
    
    // We need to remove the pointer of the singleton to the current match
    [PIGGCHelper sharedInstance].currentMatch = nil;
    
    [self.delegate pigViewControllerDidClose];
}

- (void)tieGame {
    // Determine which player the current user is
    NSString *player1ID = [_matchDataDict objectForKey:@"player1ID"];
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    NSString *statusString;
    if ([localPlayer.playerID isEqualToString:player1ID]) {
        // The current user is player 1
        statusString = [NSString stringWithFormat:@"Game Over\n%@ Forfeited", _namePlayer2];
    }
    else {
        // The current user is player 2
        statusString = [NSString stringWithFormat:@"Game Over\n%@ Forfeited", _namePlayer1];
    }
    
    [self.btn_playerReady setBackgroundImage:[UIImage imageNamed:@"button-bg-large-grey.png"] forState:UIControlStateNormal];
    [self.btn_playerReady setTitle:statusString forState:UIControlStateNormal];
    
    // Update the game state
    _gameOver = YES;
    [_matchDataDict setObject:[NSNumber numberWithBool:_gameOver] forKey:@"gameOver"];
}

- (IBAction)sendTurn:(id)sender {
    GKTurnBasedMatch *currentMatch = [[PIGGCHelper sharedInstance] currentMatch];
    
    NSData *data = [self packupMatchState:currentMatch];
    
    NSUInteger currentIndex = [currentMatch.participants indexOfObject:currentMatch.currentParticipant];
    
    NSMutableArray *nextParticipants = [NSMutableArray array];
    for (int i = 0; i < [currentMatch.participants count]; i++)
    {
        int index = (i + currentIndex + 1) % [currentMatch.participants count];
        GKTurnBasedParticipant *participant = [currentMatch.participants objectAtIndex:index];
        
        if (participant.matchOutcome == GKTurnBasedMatchOutcomeNone) {
            [nextParticipants addObject:participant];
        }
    }
    
    if (_gameOver == YES) {
        for (GKTurnBasedParticipant *participant in currentMatch.participants) {
            participant.matchOutcome = GKTurnBasedMatchOutcomeWon;
        }
        [currentMatch endMatchInTurnWithMatchData:data completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            }
        }];
        NSLog(@"Game has ended.");
    } else {
        [currentMatch endTurnWithNextParticipants:nextParticipants turnTimeout:36000 matchData:data completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"%@", error);
                
                NSString *statusString = [NSString stringWithFormat:@"Turn upload\nfailed"];
                [self.btn_playerReady setTitle:statusString forState:UIControlStateNormal];
            } else {
                NSLog(@"Player's turn is over.");
                
                // Determine which player the current user is
                NSString *player1ID = [_matchDataDict objectForKey:@"player1ID"];
                GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
                
                NSString *statusString;
                if ([localPlayer.playerID isEqualToString:player1ID]) {
                    // The current user is player 1
                    statusString = [NSString stringWithFormat:@"Waiting for\n%@", _namePlayer2];
                }
                else {
                    // The current user is player 2
                    statusString = [NSString stringWithFormat:@"Waiting for\n%@", _namePlayer1];
                }
                
                [self.btn_playerReady setBackgroundImage:[UIImage imageNamed:@"button-bg-large-grey.png"] forState:UIControlStateNormal];
                [self.btn_playerReady setTitle:statusString forState:UIControlStateNormal];
            }
        }];
        
        [self.btn_playerReady setEnabled:NO];
    }
    
    NSLog(@"Send Turn, %@, %@", data, nextParticipants);
}

- (NSData *)packupMatchState:(GKTurnBasedMatch *)match {
    // Update scores and game state in match data
    [_matchDataDict setObject:[NSNumber numberWithInt:_score1] forKey:@"score1"];
    [_matchDataDict setObject:[NSNumber numberWithInt:_score2] forKey:@"score2"];
    [_matchDataDict setObject:[NSNumber numberWithBool:_winner1] forKey:@"winner1"];
    [_matchDataDict setObject:[NSNumber numberWithBool:_winner2] forKey:@"winner2"];
    [_matchDataDict setObject:[NSNumber numberWithBool:_gameOver] forKey:@"gameOver"];
    [_matchDataDict setObject:_namePlayer1 forKey:@"player1Name"];
    [_matchDataDict setObject:_namePlayer2 forKey:@"player2Name"];
    
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:_matchDataDict format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    
    return data;
}

- (void)unpackMatchState:(GKTurnBasedMatch *)match {
    NSDictionary *gameDict = [NSPropertyListSerialization propertyListFromData:match.matchData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
    _matchDataDict = [NSMutableDictionary dictionaryWithDictionary:gameDict];
    
    // Update the game state
    _winner1 = [[_matchDataDict objectForKey:@"winner1"] boolValue];
    _winner2 = [[_matchDataDict objectForKey:@"winner2"] boolValue];
    _gameOver = [[_matchDataDict objectForKey:@"gameOver"] boolValue];
    
    // Update the player scores
    _score1 = [[_matchDataDict objectForKey:@"score1"] intValue];
    _score2 = [[_matchDataDict objectForKey:@"score2"] intValue];
    
    // Update the player names
    _namePlayer1 = [_matchDataDict objectForKey:@"player1Name"];
    _namePlayer2 = [_matchDataDict objectForKey:@"player2Name"];
    
    // Update the player score labels
    [self.lbl_player1 setText:[NSString stringWithFormat:@"%d", _score1]];
    [self.lbl_player2 setText:[NSString stringWithFormat:@"%d", _score2]];
}

#pragma mark - GCHelperDelegate Multiplayer Methods
-(void)enterNewGame:(GKTurnBasedMatch *)match {
    NSLog(@"Entering new game...");
    
    // Setup the match data dictionary
    NSDictionary *gameDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:0], @"score1",
                              [NSNumber numberWithInt:0], @"score2",
                              [GKLocalPlayer localPlayer].playerID, @"player1ID",
                              nil, @"player2ID",
                              _namePlayer1, @"player1Name",
                              _namePlayer2, @"player2Name",
                              [NSNumber numberWithBool:_winner1], @"winner1",
                              [NSNumber numberWithBool:_winner2], @"winner2",
                              [NSNumber numberWithBool:_gameOver], @"gameOver",
                      nil];
    _matchDataDict = [NSMutableDictionary dictionaryWithDictionary:gameDict];
}

-(void)takeTurn:(GKTurnBasedMatch *)match {
    NSLog(@"Taking turn for existing game...");
    
    if ([match.matchData bytes]) {
        // Update scores and game state from match data
        [self unpackMatchState:match];
        
        [self vibrate];
        
        // Determine which player the current user is
        NSString *player1ID = [_matchDataDict objectForKey:@"player1ID"];
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        
        if ([localPlayer.playerID isEqualToString:player1ID]) {
            // The current user is player 1
            _namePlayer1 = localPlayer.alias;
            _namePlayer2 = [_matchDataDict objectForKey:@"player2Name"];
            
            [self playerOneActive];
        }
        else {
            // The current user is player 2
            _namePlayer1 = [_matchDataDict objectForKey:@"player1Name"];
            _namePlayer2 = localPlayer.alias;
            
            // Now that we know who Player 2 is we can update the ID in the match data
            [_matchDataDict setObject:localPlayer.playerID forKey:@"player2ID"];
            [_matchDataDict setObject:localPlayer.alias forKey:@"player2Name"];
            
            [self playerTwoActive];
        }
        
        [self.lbl_namePlayer1 setText:_namePlayer1];
        [self.lbl_namePlayer2 setText:_namePlayer2];
        
        [self.btn_playerReady setEnabled:YES];
    }
}

-(void)layoutMatch:(GKTurnBasedMatch *)match {
    NSLog(@"Viewing match where it is not Player's turn...");
    
    [self.btn_playerReady setEnabled:NO];
    
    // Update scores and game state from match data
    [self unpackMatchState:match];
    
    if (match.status == GKTurnBasedMatchStatusEnded) {
        [self.btn_playerReady setTitle:[NSString stringWithFormat:@"Match Ended"] forState:UIControlStateNormal];
        
        if (_gameOver == YES) {
            // Game has ended, andvance play to show end state animations
            [self onPassButtonPressed:nil];
        }
        else {
            // Game ended because a player forfeited
            [self tieGame];
        }
    }
    else if (match.status == GKTurnBasedMatchOutcomeTied) {
        [self tieGame];
    }
    else {
        // Determine which player the current user is
        NSString *player1ID = [_matchDataDict objectForKey:@"player1ID"];
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        
        NSString *statusString;
        if ([localPlayer.playerID isEqualToString:player1ID]) {
            // The current user is player 1
            statusString = [NSString stringWithFormat:@"Waiting for\n%@", _namePlayer2];
        }
        else {
            // The current user is player 2
            statusString = [NSString stringWithFormat:@"Waiting for\n%@", _namePlayer1];
        }
        
        [self.btn_playerReady setBackgroundImage:[UIImage imageNamed:@"button-bg-large-grey.png"] forState:UIControlStateNormal];
        [self.btn_playerReady setTitle:statusString forState:UIControlStateNormal];
    }
}

- (void)sendNotice:(NSString *)notice forMatch:(GKTurnBasedMatch *)match {
    
}

-(void)recieveEndGame:(GKTurnBasedMatch *)match {
    [self layoutMatch:match];
}

#pragma mark - UIAlert Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex > 0 && buttonIndex < alertView.numberOfButtons) {
        [self showLeaderboard:kLeaderboardIdentifierHighestGameScore];
    }
}

#pragma mark - UIAction Methods
- (IBAction)onQuitButtonPressed:(id)sender {
//    // Move the player 2 label into the center
//    CGRect frame = self.v_containerPlayer2.frame;
//    frame.origin.x = 0.0f;
//    self.v_containerPlayer2.frame = frame;
    
    int matchDataLength = [[PIGGCHelper sharedInstance].currentMatch.matchData length];
    if (self.gameType == kTWOPLAYERGAMEGAMECENTER && matchDataLength == 0) {
        // There is no match data, we cannot save this match
        GKTurnBasedMatch *match = [PIGGCHelper sharedInstance].currentMatch;
        [self quitMatch:match];
    }
    else {
        // We need to remove the pointer of the singlton to the current match
        [PIGGCHelper sharedInstance].currentMatch = nil;
        
        [self.delegate pigViewControllerDidClose];
    }
}

- (IBAction)onPassButtonPressed:(id)sender {
    _canRollDice = NO;
    
    // Reset the turn score
    _turnScore = 0;
    _landedOn100 = NO;
    
    // Reset the dice
    [self.btn_dice1 setAdjustsImageWhenDisabled:YES];
    [self.btn_dice2 setAdjustsImageWhenDisabled:YES];
    [self.btn_dice1 setImage:[_whiteDiceImages objectAtIndex:_dice1-1] forState:UIControlStateNormal];
    [self.btn_dice2 setImage:[_whiteDiceImages objectAtIndex:_dice2-1] forState:UIControlStateNormal];
    
    // Determine if there is a winner
    if (_score1 >= 101 && _score1 > _score2) {
        _winner2 = NO;
    }
    else if (_score2 >= 101 && _score2 > _score1) {
        _winner1 = NO;
    }
    
    if (m_lbl_activePlayer == self.lbl_player1) {
        // Player 2's turn coming up
        [self.btn_playerReady setBackgroundImage:[UIImage imageNamed:@"button-bg-large-blue.png"] forState:UIControlStateNormal];
        
        if (_winner2 == YES) {
            _gameOver = YES;
            
            [self vibrate];
            
            [self playerTwoActive];
            
            [self.btn_playerReady setEnabled:NO];
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"Winner!\n%@", _namePlayer2] forState:UIControlStateNormal];
            
            if (self.gameType == kTWOPLAYERGAMEGAMECENTER) {
                // Determine which player the current user is
                NSString *player2ID = [_matchDataDict objectForKey:@"player2ID"];
                GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
                
                if ([localPlayer.playerID isEqualToString:player2ID]) {
                    // Report the scores to Game Center and save in User Deafults
                    [self reportPlayerScore:_score2];
                }
            }
        }
        else if (_score1 >= 101 && _score1 > _score2) {
            _winner1 = YES;
            
            [self playerTwoActive];
            
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"%@\nLast Chance!", _namePlayer2] forState:UIControlStateNormal];
        }
        else {
            [self playerTwoActive];
            
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"%@\nReady?", _namePlayer2] forState:UIControlStateNormal];
        }
    }
    else {
        // Player 1's turn coming up
        [self.btn_playerReady setBackgroundImage:[UIImage imageNamed:@"button-bg-large-pink.png"] forState:UIControlStateNormal];
        
        if (_winner1 == YES) {
            _gameOver = YES;
            
            [self vibrate];
            
            [self playerOneActive];
            
            [self.btn_playerReady setEnabled:NO];
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"Winner!\n%@", _namePlayer1] forState:UIControlStateNormal];
            
            // Determine which player the current user is
            NSString *player1ID = [_matchDataDict objectForKey:@"player1ID"];
            GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
            
            if ([localPlayer.playerID isEqualToString:player1ID]) {
                // Report the scores to Game Center and save in User Deafults
                [self reportPlayerScore:_score1];
            }
            
//            int64_t totalScore = [[NSUserDefaults standardUserDefaults] integerForKey:kTotalScorePlayer];
//            totalScore = totalScore + _score1;
//            
//            int64_t highestGameScore = [[NSUserDefaults standardUserDefaults] integerForKey:kHighestGameScorePlayer];
//            
//            if ((int64_t)_score1 > highestGameScore) {
//                [[PIGGCHelper sharedInstance] reportScore:(int64_t)_score1 forLeaderboardID:kLeaderboardIdentifierHighestGameScore];
//                
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New High Score!"
//                                                                message:@"You beat your highest single game score. View your rank in the Leaderboard?"
//                                                               delegate:self
//                                                      cancelButtonTitle:@"Cancel"
//                                                      otherButtonTitles:@"Leaderboard", nil];
//                [alert show];
//            }
//            [[PIGGCHelper sharedInstance] reportScore:totalScore forLeaderboardID:kLeaderboardIdentifierTotalScore];
        }
        else if (_score2 >= 101 && _score2 > _score1) {
            _winner2 = YES;
            
            [self playerOneActive];
            
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"%@\nLast Chance!", _namePlayer1] forState:UIControlStateNormal];
        }
        else {
            [self playerOneActive];
            
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"%@\nReady?", _namePlayer1] forState:UIControlStateNormal];
        }
    }
    
    if (self.gameType == kONEPLAYERGAME &&
        m_lbl_activePlayer == self.lbl_player2 &&
        _gameOver == NO)
    {
        // Computer's turn
        [self.btn_playerReady setHidden:YES];
        [self.btn_dice1 setHidden:NO];
        [self.btn_dice2 setHidden:NO];
        _turnThreshold =[self computerTurnScoreThreshold];
        [self computerTurn];
    }
    else {
        [self.btn_dice1 setHidden:YES];
        [self.btn_dice2 setHidden:YES];
        [self.btn_pass setEnabled:YES];
        [self.btn_pass setHidden:YES];
        
        if (_gameOver == YES) {
            [self.btn_playerReady setHidden:YES];
            _canRollDice = NO;
            
            UILabel *winnerLabel;
            if (_winner1 == YES) {
                winnerLabel = self.lbl_winnerPlayer1;
            }
            else {
                winnerLabel = self.lbl_winnerPlayer2;
            }
            
            [winnerLabel setAlpha:0.0];
            [winnerLabel setHidden:NO];
            [self.iv_winImage setAlpha:0.0];
            [self.iv_winImage setHidden:NO];
            self.iv_winImage.transform = CGAffineTransformMakeScale(0.3, 0.3);
            
            [UIView animateWithDuration:0.75*_gameSpeedMultiplier
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.iv_winImage.transform = CGAffineTransformRotate(self.iv_winImage.transform, -M_PI / 2.0);
                                 self.iv_winImage.transform = CGAffineTransformMakeScale(1.05, 1.05);
                                 self.iv_winImage.alpha = 0.8;
                                 winnerLabel.alpha = 1.0;
                             }
                             completion:^(BOOL finished){
                                 [UIView animateWithDuration:0.25*_gameSpeedMultiplier
                                                       delay:0.0
                                                     options:UIViewAnimationOptionCurveEaseInOut
                                                  animations:^{
                                                      self.iv_winImage.transform = CGAffineTransformMakeScale(0.9, 0.9);
                                                      self.iv_winImage.alpha = 0.9;
                                                  }
                                                  completion:^(BOOL finished){
                                                      [UIView animateWithDuration:0.25*_gameSpeedMultiplier
                                                                            delay:0.0
                                                                          options:UIViewAnimationOptionCurveEaseInOut
                                                                       animations:^{
                                                                           self.iv_winImage.transform = CGAffineTransformIdentity;
                                                                           self.iv_winImage.alpha = 1.0;
                                                                       }
                                                                       completion:^(BOOL finished){
                                                                           
                                                                       }
                                                       ];
                                                  }
                                  ];
                             }
             ];
            
            if (self.gameType != kTWOPLAYERGAMEGAMECENTER) {
                [self.btn_newGame setHidden:NO];
            }
        }
        else {
            [self.btn_playerReady setHidden:NO];
            _canRollDice = YES;
        }
    }
    
    // Check if any achievements were earned on this turn
    [self checkAchievements];
    
    // If a multiplayer game then submit the turn
    if (self.gameType == kTWOPLAYERGAMEGAMECENTER) {
        [self sendTurn:nil];
    }
}

- (IBAction)onDiceButtonPressed:(id)sender {
    _canRollDice = NO;
    
    // Disable the Pass button until the roll is complete
    [self.btn_pass setHidden:NO];
    [self.btn_pass setEnabled:NO];
    [self.btn_pass setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.btn_pass setTitle:@"HOLD" forState:UIControlStateNormal];
    
    [self rollDice];
}

- (IBAction)onPlayerReadyButtonPressed:(id)sender {
    if (m_lbl_activePlayer == self.lbl_player1) {
        // Increment Player 1's turn counter
        _turnCountPlayer1 = _turnCountPlayer1 + 1;
    }
    
    [self.btn_playerReady setHidden:YES];
    [self.btn_dice1 setEnabled:YES];
    [self.btn_dice2 setEnabled:YES];
    [self.btn_dice1 setHidden:NO];
    [self.btn_dice2 setHidden:NO];
    
    [self.btn_pass setTitleColor:[UIColor pigBlueColor] forState:UIControlStateNormal];
    [self.btn_pass setTitle:[NSString stringWithFormat:@"HOLD"] forState:UIControlStateNormal];
    [self.btn_pass setEnabled:YES];
    [self.btn_pass setHidden:NO];
    
    _canRollDice = YES;
}

- (IBAction)onNewGameButtonPressed:(id)sender {
//    if (self.gameType == kTWOPLAYERGAMEGAMECENTER) {
////        GKTurnBasedMatch *match = [PIGGCHelper sharedInstance].currentMatch;
////        [match rematchWithCompletionHandler:^(GKTurnBasedMatch *match, NSError *error) {
////            if (error) {
////                NSLog(@"%@", error);
////            }
////            else {
////                // Start a new match
////                [self reset];
////                
////                [PIGGCHelper sharedInstance].currentMatch = match;
////                [PIGGCHelper sharedInstance].delegate = self;
////                [[PIGGCHelper sharedInstance] turnBasedMatchmakerViewController:nil didFindMatch:match];
////            }
////        }];
//        
//        // Start a new match
//        [self reset];
//        
//        // Get an array of the participants of this game. Do not include the local player
//        GKTurnBasedMatch *match = [PIGGCHelper sharedInstance].currentMatch;
//        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
//        
//        NSMutableArray *opponents = [NSMutableArray array];
//        GKTurnBasedParticipant *participant;
//        
//        for (int i = 0; i < [match.participants count]; i++) {
//            participant = [match.participants objectAtIndex:i];
//            if ([participant.playerID isEqualToString:localPlayer.playerID] == NO) {
//                [opponents addObject:participant];
//            }
//        }
//        
//        [PIGGCHelper sharedInstance].delegate = self;
//        [[PIGGCHelper sharedInstance] player:localPlayer didRequestMatchWithPlayers:opponents];
//    }
//    else {
//        [self reset];
//    }
    
    [self reset];
}

- (IBAction)onGameSpeedValueChanged:(id)sender {
    // Change the game speed
    if (self.sgmt_gameSpeed.selectedSegmentIndex == 0) {
        [Flurry logEvent:@"GAMEPLAY_SCREEN_SPEEDSLOW" withParameters:[Flurry flurryUserParams]];
        
        _gameSpeedMultiplier = kSLOWGAME;
    }
    else {
        [Flurry logEvent:@"GAMEPLAY_SCREEN_SPEEDFAST" withParameters:[Flurry flurryUserParams]];
        
        _gameSpeedMultiplier = kFASTGAME;
    }

    // Save setting to user defaults
    [[NSUserDefaults standardUserDefaults] setFloat:_gameSpeedMultiplier forKey:kSettingsGameSpeed];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)onRollTutorialButtonPressed:(id)sender {
    [self.btn_rollTutorial removeFromSuperview];
    
    // Save setting to user defaults so this tutorial view does not show again
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kRollTutorialCompleted];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
