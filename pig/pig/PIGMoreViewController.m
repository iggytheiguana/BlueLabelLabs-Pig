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
    
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
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
