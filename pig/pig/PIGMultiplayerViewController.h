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

@protocol PIGMultiplayerViewControllerDelegate <NSObject>
- (void)pigMultiplayerViewControllerDidClose;
@end

@interface PIGMultiplayerViewController : UITableViewController < PIGViewControllerDelegate, GCHelperDelegate, GKTurnBasedMatchmakerViewControllerDelegate >

@property (weak, nonatomic) id <PIGMultiplayerViewControllerDelegate> delegate;

@property (nonatomic, weak) UIViewController *gamePlayViewController;

@end
