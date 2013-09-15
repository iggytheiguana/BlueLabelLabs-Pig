//
//  PIGMoreViewController.m
//  pig
//
//  Created by Jordan Gurrieri on 9/10/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGMoreViewController.h"

@interface PIGMoreViewController ()

@end

@implementation PIGMoreViewController

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    // Hide the Navigation bar line
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]]) {
                [view2 removeFromSuperview];
            }
        }
    }
    
//    CGRect frame = CGRectMake(150.0, 44.0, 100.0, 42.0);
//    UILabel *titleLabel = [[UILabel alloc] initWithFrame:frame];
//    
//    [titleLabel setBackgroundColor:[UIColor clearColor]];
//    // here's where you can customize the font size
//    [titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
//    [titleLabel setTextColor:[UIColor whiteColor]];
//    [titleLabel setText:@"More"];
//    [titleLabel sizeToFit];
//    [titleLabel setCenter:[self.navigationItem.titleView center]];
//    
//    [self.navigationItem setTitleView:titleLabel];
    
    // Increase the navigation bar height
//    CGRect frame = CGRectMake(150.0, 44.0, 100.0, 42.0);
//    [self.navigationController.navigationBar setFrame:frame];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IB Actions
- (IBAction)onHomeButtonPressed:(id)sender {
    [self.delegate pigMoreViewControllerDidClose];
}

@end
