//
//  PIGHomeViewController.m
//  pig
//
//  Created by Jordan Gurrieri on 8/27/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGHomeViewController.h"
#import <StoreKit/StoreKit.h>
#import "PIGViewController.h"
#import "PIGIAPHelper.h"
#import "Reachability.h"

NSString *const IAPUnlockTwoPlayerGameProductPurchased = @"IAPUnlockTwoPlayerGameProductPurchased";

@interface PIGHomeViewController () {
    NSArray *_products;
    NSNumberFormatter *_priceFormatter;
}

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
    
    // Check if two-palyer game has been unlocked already
    BOOL twoPlayerProductPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:IAPUnlockTwoPlayerGameProductIdentifier];
    if (twoPlayerProductPurchased == YES) {
        [self.btn_buyTwoPlayer setHidden:YES];
        [self.lbl_buyText setHidden:YES];
        [self.btn_twoPlayer setHidden:NO];
    }
    else {
        [self.btn_twoPlayer setHidden:YES];
        [self.lbl_buyText setHidden:NO];
        [self.btn_buyTwoPlayer setHidden:NO];
    }
    
    [self loadIAPs];
    
    // Set the currency format on the two-player IAP button
    _priceFormatter = [[NSNumberFormatter alloc] init];
    [_priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
                [self.btn_twoPlayer setHidden:NO];
            }
            else {
                [_priceFormatter setLocale:product.priceLocale];
//                [self.btn_buyTwoPlayer setTitle:[NSString stringWithFormat:@"2 Player Game (LOCKED - %@)", [_priceFormatter stringFromNumber:product.price]] forState:UIControlStateNormal];
                
                [self.btn_twoPlayer setHidden:YES];
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
            [self.btn_twoPlayer setHidden:NO];
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

#pragma mark - UIAlert Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
}

#pragma mark - UI Actions
- (IBAction)onOnePlayerButtonPressed:(id)sender {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.onePlayerGame = YES;
    [self.navigationController pushViewController:gameplayViewController animated:YES];
}

- (IBAction)onTwoPlayerButtonPressed:(id)sender {
    PIGViewController *gameplayViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GamePlayIdentifier"];
    gameplayViewController.onePlayerGame = NO;
    [self.navigationController pushViewController:gameplayViewController animated:YES];
}

- (IBAction)onBuyTwoPlayerButtonPressed:(id)sender {
    [self onTwoPlayerButtonPressed:sender];
    
//    Reachability *internetReachable = [Reachability reachabilityWithHostname:@"www.itunes.com"];
//    
//    if (internetReachable.isReachable && [_products count] != 0) {
//        SKProduct *product = _products[0];
//        
//        NSLog(@"Buying %@...", product.productIdentifier);
//        [[PIGIAPHelper sharedInstance] buyProduct:product];
//    }
//    else {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot connect to iTunes Store"
//                                                        message:nil
//                                                       delegate:self
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//    }
}

- (IBAction)onRestoreIAPButtonPressed:(id)sender {
    [[PIGIAPHelper sharedInstance] restoreCompletedTransactions];
}

@end
