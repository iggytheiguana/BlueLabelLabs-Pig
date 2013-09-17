//
//  PIGRulesViewController.h
//  pig
//
//  Created by Jordan Gurrieri on 8/29/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PIGRulesViewControllerDelegate <NSObject>
- (void)pigRulesViewControllerDidClose;
@end

@interface PIGRulesViewController : UIViewController

@property (weak, nonatomic) id <PIGRulesViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIScrollView *sv_scrollView;
@property (weak, nonatomic) IBOutlet UILabel *lbl_lastRule;

- (IBAction)onCloseButtonPressed:(id)sender;

@end
