//
//  PIGHomeViewController.m
//  pig
//
//  Created by Jordan Gurrieri on 8/27/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGHomeViewController.h"
#import <StoreKit/StoreKit.h>
#import "PIGIAPHelper.h"
#import "Reachability.h"

NSString *const IAPUnlockTwoPlayerGameProductPurchased = @"IAPUnlockTwoPlayerGameProductPurchased";

@interface PIGHomeViewController () {
    NSArray *_products;
}

//@property (nonatomic) UIDynamicAnimator *animator;

@end

@implementation PIGHomeViewController

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
    
    [self loadIAPs];
    
//    // Add dynamic animations to the one player and two player buttons
//    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
//    
//    // Add Snap Behaviors to the one player and two player buttons
//    UISnapBehavior *onePlayerSnap = [[UISnapBehavior alloc] initWithItem:self.v_containerPlayerOne snapToPoint:CGPointMake(self.v_containerPlayerOne.center.x, self.v_containerPlayerOne.center.y)];
//    UISnapBehavior *twoPlayerSnap = [[UISnapBehavior alloc] initWithItem:self.v_containerPlayerTwo snapToPoint:CGPointMake(self.v_containerPlayerTwo.center.x, self.v_containerPlayerTwo.center.y)];
//    
//    [animator addBehavior:onePlayerSnap];
//    [animator addBehavior:twoPlayerSnap];
//    
//    self.animator = animator;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Check if two-palyer game has been unlocked already
    BOOL twoPlayerProductPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:IAPUnlockTwoPlayerGameProductIdentifier];
    if (twoPlayerProductPurchased == YES) {
        [self.btn_buyTwoPlayer setHidden:YES];
        [self.lbl_buyText setHidden:YES];
    }
    else {
        [self.lbl_buyText setHidden:NO];
        [self.btn_buyTwoPlayer setHidden:NO];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedTransaction:) name:IAPHelperFailedTransactionNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Storyboard Methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"Home_to_OnePlayerGame"])
	{
		PIGViewController *gameplayViewController = segue.destinationViewController;
        gameplayViewController.delegate = self;
        gameplayViewController.onePlayerGame = YES;
	}
    else if ([segue.identifier isEqualToString:@"Home_to_TwoPlayerGame"])
	{
		PIGViewController *gameplayViewController = segue.destinationViewController;
        gameplayViewController.delegate = self;
        gameplayViewController.onePlayerGame = NO;
	}
    else if ([segue.identifier isEqualToString:@"Home_to_More"])
	{
        PIGMoreViewController *moreViewController = segue.destinationViewController;
        moreViewController.delegate = self;
	}
}

#pragma mark - PIGViewController Delegate
- (void)pigViewControllerDidClose {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - PIGMoreViewController Delegate
- (void)pigMoreViewControllerDidClose {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - In App Purchase Methods
- (void)loadIAPs {
    _products = nil;
    
    [[PIGIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            _products = products;
            SKProduct *product = (SKProduct *)_products[0];
            
            if ([[PIGIAPHelper sharedInstance] productPurchased:product.productIdentifier]) {
                [self.btn_buyTwoPlayer setHidden:YES];
                [self.lbl_buyText setHidden:YES];
            }
            else {
                [self.lbl_buyText setHidden:NO];
                [self.btn_buyTwoPlayer setHidden:NO];
            }
        }
    }];
}

- (void)productPurchased:(NSNotification *)notification {
    NSString * productIdentifier = notification.object;
    [_products enumerateObjectsUsingBlock:^(SKProduct *product, NSUInteger idx, BOOL *stop) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            [self.lbl_buyText setHidden:YES];
            [self.btn_buyTwoPlayer setHidden:YES];
            *stop = YES;
        }
    }];
}

- (void)failedTransaction:(NSString *)errorMessage {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iTunes Store Error"
                                                    message:[NSString stringWithFormat:@"Transaction error: %@", errorMessage]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Game Center Methods
- (void)showLeaderboard {
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.viewState = GKGameCenterViewControllerStateDefault;
        
        [self presentViewController:gameCenterController animated:YES completion:nil];
    }
}

- (void)showAchievements {
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.viewState = GKGameCenterViewControllerStateAchievements;
        
        [self presentViewController:gameCenterController animated:YES completion:nil];
    }
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlert Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
}

#pragma mark - UI Actions
- (IBAction)onBuyTwoPlayerButtonPressed:(id)sender {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.onePlayerGame = NO;
    [self.navigationController pushViewController:gameplayViewController animated:YES];
    
//    Reachability *internetReachable = [Reachability reachabilityWithHostname:@"www.itunes.com"];
//    
//    if (internetReachable.isReachable && [_products count] != 0) {
//        SKProduct *product = _products[0];
//        
//        NSLog(@"Buying %@...", product.productIdentifier);
//        [[PIGIAPHelper sharedInstance] buyProduct:product];
//    }
//    else {
//        [self loadIAPs];
//        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot connect to iTunes Store"
//                                                        message:nil
//                                                       delegate:self
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//    }
}

@end
