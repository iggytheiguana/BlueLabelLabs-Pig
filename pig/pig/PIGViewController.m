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

#define kGAMESPEEDSETTING @"GameSpeedSetting"
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
    BOOL _canRollDice;
    BOOL _winner1;
    BOOL _winner2;
    BOOL _gameOver;
    NSString *_namePlayer2;
    NSArray *_whiteDiceImages;
}

@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UISnapBehavior *player1SnapBehavior;
@property (nonatomic) UISnapBehavior *player2SnapBehavior;
@property (nonatomic) UIAttachmentBehavior *touchAttachmentBehavior;
@property (nonatomic) UIAttachmentBehavior *touchAttachmentBehavior2;

@end

@implementation PIGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
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
    
    if (self.onePlayerGame == YES) {
        _namePlayer2 = @"Computer";
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
    
    // Add motion effects to dice
//    UIMotionEffect *motionEffect = [[UIMotionEffect alloc] init];
//    [motionEffect keyPathsAndRelativeValuesForViewerOffset:UIOffsetMake(1.0, 1.0)];
    PIGMotionEffect *motionEffect = [[PIGMotionEffect alloc] init];
    [self.btn_dice2 addMotionEffect:motionEffect];
    
    // Setup game speed from user's last setting
    _gameSpeedMultiplier = [[NSUserDefaults standardUserDefaults] floatForKey:kGAMESPEEDSETTING];
    if (_gameSpeedMultiplier == 0) {
        // Default to slow game speed
        _gameSpeedMultiplier = kSLOWGAME;
        
        // Save setting to user defaults
        [[NSUserDefaults standardUserDefaults] setFloat:_gameSpeedMultiplier forKey:kGAMESPEEDSETTING];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (_gameSpeedMultiplier == kSLOWGAME) {
        [self.sgmt_gameSpeed setSelectedSegmentIndex:0];
    }
    else {
        [self.sgmt_gameSpeed setSelectedSegmentIndex:1];
    }
    
    [self reset];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Move the player 2 label into the center
    CGRect frame = self.v_containerPlayer2.frame;
    frame.origin.x = 0.0f;
    self.v_containerPlayer2.frame = frame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [self.animator removeBehavior:self.touchAttachmentBehavior];
    [self.animator removeBehavior:self.touchAttachmentBehavior2];
}

- (void)reset {
    // Reset gameplay instance variables
    _score1 = 0;
    _score2 = 0;
    _turnScore = 0;
    _doubleCount = 0;
    _winner1 = NO;
    _winner2 = NO;
    _gameOver = NO;
    
    // Setup Player 1 to start the game
    [self playerOneActive];
    
    [self.btn_playerReady setTitle:[NSString stringWithFormat:@"Player 1 Ready"] forState:UIControlStateNormal];
    
    [self.lbl_player1 setText:[NSString stringWithFormat:@"%d", _score1]];
    [self.lbl_player2 setText:[NSString stringWithFormat:@"%d", _score2]];
    
    // Setup Button and Label states
    [self.lbl_rollValue setHidden:YES];
    [self.iv_rollImage setHidden:YES];
    [self.btn_dice1 setHidden:YES];
    [self.btn_dice2 setHidden:YES];
    [self.btn_playerReady setEnabled:YES];
    [self.btn_pass setHidden:YES];
    [self.btn_newGame setHidden:YES];
    
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
                [self.btn_pass setTitle:[NSString stringWithFormat:@"Roll again or pass"] forState:UIControlStateNormal];
            }
        }
    }
    
    // If the roll was turn ending, we vibrate the phone.
    if (turnEnded == YES) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    
    // Now, update the active player's global score variable
    if (m_lbl_activePlayer == self.lbl_player1) {
        _score1 = currentPlayerScore;
    }
    else {
        _score2 = currentPlayerScore;
    }
    
//    // Now we display the roll value label and update the player's score label
//    [self.lbl_rollValue setAlpha:0.0];
//    [self.lbl_rollValue setHidden:NO];
//    
//    [UIView animateWithDuration:0.75
//                          delay:0.25
//                        options: UIViewAnimationOptionCurveEaseIn
//                     animations:^{
//                         [self.lbl_rollValue setAlpha:1.0];
//                     }
//                     completion:^(BOOL finished){
//                         [self.lbl_rollValue setAlpha:0.0];
//                         [self.lbl_rollValue setHidden:YES];
//                         
//                         [m_lbl_activePlayer setText:[NSString stringWithFormat:@"%d", currentPlayerScore]];
//                         
//                         [self.btn_dice1 setEnabled:YES];
//                         [self.btn_dice2 setEnabled:YES];
//                         
//                         // Determine if the current player can roll again or not
//                         if (turnEnded == YES) {
//                             // Turn is over, toggle the active player
//                             [self onPassButtonPressed:nil];
//                         }
//                         else if (self.onePlayerGame == YES && m_lbl_activePlayer == self.lbl_player2) {
//                             // Computer's turn
//                             if (currentPlayerScore >= _turnThreshold) {
//                                 // Computer has passed turn threshold, toggle the active player
//                                 [self onPassButtonPressed:nil];
//                             }
//                             else {
//                                 [self computerTurn];
//                             }
//                         }
//                         else if (_doubleCount == 0) {
//                             // Player can roll again or Pass
//                             [self.btn_pass setEnabled:YES];
//                             [self.btn_pass setTitleColor:[UIColor pigBlueColor] forState:UIControlStateNormal];
//                             [self.btn_pass setTitle:[NSString stringWithFormat:@"Pass"] forState:UIControlStateNormal];
//                         }
//                     }];
    
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
    
//    CGPoint originalCenter = rollView.center;
//    CGPoint newCenter = [self.view convertPoint:m_lbl_activePlayer.center fromView:m_lbl_activePlayer];
////    CGPoint newCenter = CGPointMake(160.0f, 122.0f);
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
                                                                                        
                                                                                        [m_lbl_activePlayer setText:[NSString stringWithFormat:@"%d", currentPlayerScore]];
                                                                                        
                                                                                        [self.btn_dice1 setEnabled:YES];
                                                                                        [self.btn_dice2 setEnabled:YES];
                                                                                        
                                                                                        // Determine if the current player can roll again or not
                                                                                        if (turnEnded == YES) {
                                                                                            // Turn is over, toggle the active player
                                                                                            [self onPassButtonPressed:nil];
                                                                                        }
                                                                                        else if (self.onePlayerGame == YES && m_lbl_activePlayer == self.lbl_player2) {
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
                                                                                            [self.btn_pass setTitle:[NSString stringWithFormat:@"Pass"] forState:UIControlStateNormal];
                                                                                        }
                                                                                        
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
    [self.btn_pass setTitle:@"Pass" forState:UIControlStateNormal];
    
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
    
    [self.iv_circlePlayer1 setImage:[UIImage imageNamed:@"points-bg-pink.png"]];
    [self.iv_circlePlayer2 setImage:[UIImage imageNamed:@"points-bg-solid-blue.png"]];
    [self.lbl_player1 setTextColor:[UIColor pigBlueColor]];
    [self.lbl_player2 setTextColor:[UIColor whiteColor]];
    
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
    
    [self.iv_circlePlayer1 setImage:[UIImage imageNamed:@"points-bg-solid-pink.png"]];
    [self.iv_circlePlayer2 setImage:[UIImage imageNamed:@"points-bg-blue.png"]];
    [self.lbl_player1 setTextColor:[UIColor whiteColor]];
    [self.lbl_player2 setTextColor:[UIColor pigBlueColor]];
    
    m_lbl_activePlayer = self.lbl_player2;
}

#pragma mark - Phone Shake Handler
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.subtype == UIEventSubtypeMotionShake )
    {
        // User shook the device, we roll only if player is active and state is ready.
        if (self.onePlayerGame == YES && m_lbl_activePlayer == self.lbl_player2) {
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

#pragma mark - UIAction Methods
- (IBAction)onHomeButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onPassButtonPressed:(id)sender {
    _canRollDice = NO;
    
    // Reset the turn score
    _turnScore = 0;
    
    // Reset the dice
    [self.btn_dice1 setAdjustsImageWhenDisabled:YES];
    [self.btn_dice2 setAdjustsImageWhenDisabled:YES];
    [self.btn_dice1 setImage:[_whiteDiceImages objectAtIndex:_dice1-1] forState:UIControlStateNormal];
    [self.btn_dice2 setImage:[_whiteDiceImages objectAtIndex:_dice2-1] forState:UIControlStateNormal];
    
    // Determin if there is a winner
    if (_score1 >= 101 && _score1 > _score2) {
        _winner2 = NO;
    }
    else if (_score2 >= 101 && _score2 > _score1) {
        _winner1 = NO;
    }
    
    if (m_lbl_activePlayer == self.lbl_player1) {
        if (_winner2 == YES) {
            _gameOver = YES;
            
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            [self playerTwoActive];
            
            [self.btn_playerReady setEnabled:NO];
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"Winner!\n%@", _namePlayer2] forState:UIControlStateNormal];
        }
        else if (_score1 >= 101 && _score1 > _score2) {
            _winner1 = YES;
            
            [self playerTwoActive];
            
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"%@\nLast Chance", _namePlayer2] forState:UIControlStateNormal];
        }
        else {
            [self playerTwoActive];
            
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"%@ Ready", _namePlayer2] forState:UIControlStateNormal];
        }
    }
    else {
        if (_winner1 == YES) {
            _gameOver = YES;
            
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            [self playerOneActive];
            
            [self.btn_playerReady setEnabled:NO];
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"Winner!\nPlayer 1"] forState:UIControlStateNormal];
        }
        else if (_score2 >= 101 && _score2 > _score1) {
            _winner2 = YES;
            
            [self playerOneActive];
            
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"Player 1\nLast Chance"] forState:UIControlStateNormal];
        }
        else {
            [self playerOneActive];
            
            [self.btn_playerReady setTitle:[NSString stringWithFormat:@"Player 1 Ready"] forState:UIControlStateNormal];
        }
    }
    
    if (self.onePlayerGame == YES &&
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
        [self.btn_playerReady setHidden:NO];
        [self.btn_dice1 setHidden:YES];
        [self.btn_dice2 setHidden:YES];
        [self.btn_pass setEnabled:YES];
        [self.btn_pass setHidden:YES];
        
        if (_gameOver == YES) {
            _canRollDice = NO;
            [self.btn_newGame setHidden:NO];
        }
        else {
            _canRollDice = YES;
        }
    }
}

- (IBAction)onDiceButtonPressed:(id)sender {
    _canRollDice = NO;
    
    // Disable the Pass button until the roll is complete
    [self.btn_pass setHidden:NO];
    [self.btn_pass setEnabled:NO];
    [self.btn_pass setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.btn_pass setTitle:@"Pass" forState:UIControlStateNormal];
    
    [self rollDice];
}

- (IBAction)onPlayerReadyButtonPressed:(id)sender {
    [self.btn_playerReady setHidden:YES];
    [self.btn_dice1 setEnabled:YES];
    [self.btn_dice2 setEnabled:YES];
    [self.btn_dice1 setHidden:NO];
    [self.btn_dice2 setHidden:NO];
    
    [self.btn_pass setHidden:NO];
    [self.btn_pass setEnabled:YES];
    [self.btn_pass setTitleColor:[UIColor pigBlueColor] forState:UIControlStateNormal];
    [self.btn_pass setTitle:[NSString stringWithFormat:@"Pass"] forState:UIControlStateNormal];
    
    _canRollDice = YES;
}

- (IBAction)onNewGameButtonPressed:(id)sender {
    [self reset];
}

- (IBAction)onGameSpeedValueChanged:(id)sender {
    // Change the game speed
    if (self.sgmt_gameSpeed.selectedSegmentIndex == 0) {
        _gameSpeedMultiplier = kSLOWGAME;
    }
    else {
        _gameSpeedMultiplier = kFASTGAME;
    }

    // Save setting to user defaults
    [[NSUserDefaults standardUserDefaults] setFloat:_gameSpeedMultiplier forKey:kGAMESPEEDSETTING];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
