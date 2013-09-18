//
//  PIGUpgradeViewController.h
//  pig
//
//  Created by Jordan Gurrieri on 9/17/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PIGUpgradeViewControllerDelegate <NSObject>
- (void)pigUpgradeViewControllerDidClose;
@end

@interface PIGUpgradeViewController : UIViewController < UIAlertViewDelegate >

@property (weak, nonatomic) id <PIGUpgradeViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *btn_upgrade;
//@property (weak, nonatomic) IBOutlet UIImageView *iv_whiteCircle;

- (IBAction)onUpgradeButtonPressed:(id)sender;
//- (IBAction)onUpgradeButtonTouched:(id)sender;
//- (IBAction)onUpgradeButtonReleased:(id)sender;


@end
