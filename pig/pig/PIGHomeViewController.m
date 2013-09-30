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
#import "PIGMotionEffect.h"
#import "PIGGameConstants.h"
#import "UINavigationController+PIGCustomNavigationController.h"
#import "Flurry+PIGFlurry.h"

@interface PIGHomeViewController () {
    NSArray *_products;
}

//@property (nonatomic) UIDynamicAnimator *animator;

@end

@implementation PIGHomeViewController

#pragma mark - Initialization
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
    
    // Customize the Navigation Bar style
    [self.navigationController applyCustomStyle];
    
    // Check Game Center availability and authentication
    [[PIGGCHelper sharedInstance] authenticateLocalUserFromViewController:self];
    [PIGGCHelper sharedInstance].delegate = self;
    
    // Load In App Purchases
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
    
    // Give the PIG logo a shadow to add to the motion effect
    self.iv_pigLogo.layer.shadowColor = [UIColor blackColor].CGColor;
    self.iv_pigLogo.layer.shadowOpacity = 0.2f;
    self.iv_pigLogo.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.iv_pigLogo.layer.shadowRadius = 0.0f;
    
    // Add motion effects to dice
    PIGMotionEffect *motionEffect = [[PIGMotionEffect alloc] init];
    [self.iv_pigLogo addMotionEffect:motionEffect];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [Flurry logEvent:@"HOME_SCREEN_VIEWING" withParameters:[Flurry flurryUserParams] timed:YES];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [PIGGCHelper sharedInstance].delegate = self;
    
//    // Check if two-palyer game has been unlocked already
//    BOOL twoPlayerProductPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:IAPUnlockTwoPlayerGameProductIdentifier];
//    if (twoPlayerProductPurchased == YES) {
//        [self.btn_buyTwoPlayer setHidden:YES];
//        [self.lbl_buyText setHidden:YES];
//    }
//    else {
//        [self.lbl_buyText setHidden:NO];
//        [self.btn_buyTwoPlayer setHidden:NO];
//    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedTransaction:) name:IAPHelperFailedTransactionNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Show the Rules screen is this is the first time launching the app
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kRulesTutorialCompleted] == NO) {
        PIGRulesViewController *rulesViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RulesIdentifier"];
        rulesViewController.delegate = self;
        [self.navigationController pushViewController:rulesViewController animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [Flurry endTimedEvent:@"HOME_SCREEN_VIEWING" withParameters:[Flurry flurryUserParams]];
    
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
		UINavigationController *navigationController = segue.destinationViewController;
        [navigationController applyCustomStyle];
        
        PIGViewController *gameplayViewController = [navigationController.viewControllers objectAtIndex:0];
        gameplayViewController.delegate = self;
        gameplayViewController.gameType = kONEPLAYERGAME;
	}
    else if ([segue.identifier isEqualToString:@"Home_to_TwoPlayerGame"])
	{
		PIGMultiplayerViewController *multiplayerViewController = segue.destinationViewController;
        multiplayerViewController.delegate = self;
	}
    else if ([segue.identifier isEqualToString:@"Home_to_More"])
	{
        PIGMoreViewController *moreViewController = segue.destinationViewController;
        moreViewController.delegate = self;
	}
}

#pragma mark - PIGViewController Delegate
- (void)pigViewControllerDidClose {
//    [self.navigationController popViewControllerAnimated:YES];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PIGMultiplayerViewController Delegate
- (void)pigMultiplayerViewControllerDidClose {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - PIGMoreViewController Delegate
- (void)pigMoreViewControllerDidClose {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - PIGRulesViewController Delegate
- (void)pigRulesViewControllerDidClose {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - In App Purchase Methods
- (void)loadIAPs {
    _products = nil;
    
    [[PIGIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            _products = products;
//            SKProduct *product = (SKProduct *)_products[0];
            
//            if ([[PIGIAPHelper sharedInstance] productPurchased:product.productIdentifier]) {
//                [self.btn_buyTwoPlayer setHidden:YES];
//                [self.lbl_buyText setHidden:YES];
//            }
//            else {
//                [self.lbl_buyText setHidden:NO];
//                [self.btn_buyTwoPlayer setHidden:NO];
//            }
        }
        [Flurry logEvent:@"SESSION_START" withParameters:[Flurry flurryUserParams]];
    }];
}

- (void)productPurchased:(NSNotification *)notification {
    NSString * productIdentifier = notification.object;
    [_products enumerateObjectsUsingBlock:^(SKProduct *product, NSUInteger idx, BOOL *stop) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
//            [self.lbl_buyText setHidden:YES];
//            [self.btn_buyTwoPlayer setHidden:YES];
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

#pragma mark - GCHelperDelegate Multiplayer Methods
-(void)enterNewGame:(GKTurnBasedMatch *)match {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
    [PIGGCHelper sharedInstance].delegate = gameplayViewController;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gameplayViewController];
    [navigationController applyCustomStyle];
    
    [self presentViewController:navigationController animated:YES completion:^{
        [gameplayViewController enterNewGame:match];
    }];
}

-(void)takeTurn:(GKTurnBasedMatch *)match {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
    [PIGGCHelper sharedInstance].delegate = gameplayViewController;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gameplayViewController];
    [navigationController applyCustomStyle];
    
    [self presentViewController:navigationController animated:YES completion:^{
        [gameplayViewController takeTurn:match];
    }];
}

-(void)layoutMatch:(GKTurnBasedMatch *)match {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
    [PIGGCHelper sharedInstance].delegate = gameplayViewController;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gameplayViewController];
    [navigationController applyCustomStyle];
    
    [self presentViewController:navigationController animated:YES completion:^{
        [gameplayViewController layoutMatch:match];
    }];
}

- (void)sendNotice:(NSString *)notice forMatch:(GKTurnBasedMatch *)match {
    
}

-(void)recieveEndGame:(GKTurnBasedMatch *)match {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.delegate = self;
    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
    [PIGGCHelper sharedInstance].delegate = gameplayViewController;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gameplayViewController];
    [navigationController applyCustomStyle];
    
    [self presentViewController:navigationController animated:YES completion:^{
        [gameplayViewController recieveEndGame:match];
    }];
}

#pragma mark - UIAlert Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
}

#pragma mark - UI Actions
//- (IBAction)onBuyTwoPlayerButtonPressed:(id)sender {
//    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
//    gameplayViewController.delegate = self;
//    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
//    [self.navigationController pushViewController:gameplayViewController animated:YES];
//    
////    Reachability *internetReachable = [Reachability reachabilityWithHostname:@"www.itunes.com"];
////    
////    if (internetReachable.isReachable && [_products count] != 0) {
////        SKProduct *product = _products[0];
////        
////        NSLog(@"Buying %@...", product.productIdentifier);
////        [[PIGIAPHelper sharedInstance] buyProduct:product];
////    }
////    else {
////        [self loadIAPs];
////        
////        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot connect to iTunes Store"
////                                                        message:nil
////                                                       delegate:self
////                                              cancelButtonTitle:@"OK"
////                                              otherButtonTitles:nil];
////        [alert show];
////    }
//}

//- (IBAction)onTwoPlayerButtonPressed:(id)sender {
//    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
//    gameplayViewController.delegate = self;
//    gameplayViewController.gameType = kTWOPLAYERGAMEGAMECENTER;
//    [self.navigationController pushViewController:gameplayViewController animated:YES];
//}

@end
