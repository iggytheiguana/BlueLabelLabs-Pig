//
//  PIGRulesViewController.m
//  pig
//
//  Created by Jordan Gurrieri on 8/29/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGRulesViewController.h"
#import "UIColor+PIGCustomColors.h"

@interface PIGRulesViewController ()

@end

@implementation PIGRulesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    CGSize contentSize = CGSizeMake(320.0, self.lbl_lastRule.frame.origin.y + self.lbl_lastRule.frame.size.height + 20.0);
    [self.sv_scrollView setContentSize:contentSize];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    // Hide the Navigation bar line
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]]) {
                [view2 removeFromSuperview];
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIAction Methods
- (IBAction)onCloseButtonPressed:(id)sender {
    [self.delegate pigRulesViewControllerDidClose];
}

@end
