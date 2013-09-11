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

- (IBAction)onCloseButtonPressed:(id)sender;

@end
