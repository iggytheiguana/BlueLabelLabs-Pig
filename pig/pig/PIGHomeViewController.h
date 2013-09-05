//
//  PIGHomeViewController.h
//  pig
//
//  Created by Jordan Gurrieri on 8/27/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PIGHomeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *btn_onePlayer;
@property (weak, nonatomic) IBOutlet UIButton *btn_twoPlayer;
@property (weak, nonatomic) IBOutlet UIButton *btn_buyTwoPlayer;
@property (weak, nonatomic) IBOutlet UILabel *lbl_buyText;

- (IBAction)onOnePlayerButtonPressed:(id)sender;
- (IBAction)onTwoPlayerButtonPressed:(id)sender;
- (IBAction)onBuyTwoPlayerButtonPressed:(id)sender;
- (IBAction)onRestoreIAPButtonPressed:(id)sender;

@end
