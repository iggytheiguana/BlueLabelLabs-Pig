//
//  PIGMoreTableViewController.h
//  pig
//
//  Created by Jordan Gurrieri on 9/11/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PIGRulesViewController.h"
#import <GameKit/GameKit.h>
#import "PIGUpgradeViewController.h"

@interface PIGMoreTableViewController : UITableViewController < GKGameCenterControllerDelegate, PIGRulesViewControllerDelegate, PIGUpgradeViewControllerDelegate >

@property (weak, nonatomic) IBOutlet UISwitch *sw_vibrate;

- (IBAction)onVibrateSwitchValueChanged:(id)sender;

@end
