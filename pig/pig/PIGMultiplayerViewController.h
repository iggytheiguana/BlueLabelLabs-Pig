//
//  PIGMultiplayerViewController.h
//  pig
//
//  Created by Jordan Gurrieri on 9/14/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PIGViewController.h"
#import "PIGGCHelper.h"
#import "PIGUpgradeViewController.h"

@protocol PIGMultiplayerViewControllerDelegate <NSObject>
- (void)pigMultiplayerViewControllerDidClose;
@end

@interface PIGMultiplayerViewController : UITableViewController < UIActionSheetDelegate, UIAlertViewDelegate, PIGViewControllerDelegate, GCHelperDelegate, PIGUpgradeViewControllerDelegate >

@property (weak, nonatomic) id <PIGMultiplayerViewControllerDelegate> delegate;

//@property (nonatomic, weak) UIViewController *gamePlayViewController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btn_newGame;

- (IBAction)onNewTwoPlayerGameButtonPressed:(id)sender;

@end
