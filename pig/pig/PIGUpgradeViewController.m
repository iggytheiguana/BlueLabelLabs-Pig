//
//  PIGUpgradeViewController.m
//  pig
//
//  Created by Jordan Gurrieri on 9/17/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGUpgradeViewController.h"
#import <StoreKit/StoreKit.h>
#import "PIGIAPHelper.h"
#import "Reachability.h"
#import "Flurry+PIGFlurry.h"

@interface PIGUpgradeViewController () {
    NSArray *_products;
    UIActivityIndicatorView *m_ai_RestorePurchases;
}

@end

@implementation PIGUpgradeViewController

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
    
    // Setup activity indicator in the navigation bar
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    m_ai_RestorePurchases = activityIndicator;
    
    // Load In App Purchases
    [self loadIAPs];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [Flurry logEvent:@"UPGRADE_SCREEN_VIEWING" withParameters:[Flurry flurryUserParams] timed:YES];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    // Add Restore button to navigation bar
    UIBarButtonItem *btn_restore = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Restore"
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                    action:@selector(onRestoreButtonPressed:)];
    self.navigationItem.rightBarButtonItem = btn_restore;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedTransaction:) name:IAPHelperFailedTransactionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreFailed:) name:IAPHelperRestoreFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreCanceled:) name:IAPHelperRestoreCanceledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreCompleted:) name:IAPHelperRestoreCompletedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [Flurry endTimedEvent:@"UPGRADE_SCREEN_VIEWING" withParameters:[Flurry flurryUserParams]];
    
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
            
            [m_ai_RestorePurchases stopAnimating];
            [self.navigationController.navigationItem setTitleView:nil];
            
            if ([[PIGIAPHelper sharedInstance] productPurchased:product.productIdentifier]) {
                [self.delegate pigUpgradeViewControllerDidClose];
            }
            else {
                
            }
        }
    }];
}

- (void)productPurchased:(NSNotification *)notification {
    NSString * productIdentifier = notification.object;
    [_products enumerateObjectsUsingBlock:^(SKProduct *product, NSUInteger idx, BOOL *stop) {
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            [m_ai_RestorePurchases stopAnimating];
            [self.navigationController.navigationItem setTitleView:nil];
            [self.delegate pigUpgradeViewControllerDidClose];
            *stop = YES;
        }
    }];
}

- (void)failedTransaction:(NSString *)errorMessage {
    [m_ai_RestorePurchases stopAnimating];
    [self.navigationController.navigationItem setTitleView:nil];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iTunes Store Error"
                                                    message:[NSString stringWithFormat:@"Transaction error: %@", errorMessage]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)restoreFailed:(NSString *)errorMessage {
    [m_ai_RestorePurchases stopAnimating];
    [self.navigationController.navigationItem setTitleView:nil];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iTunes Store Error"
                                                    message:[NSString stringWithFormat:@"Transaction error: %@", errorMessage]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)restoreCanceled:(NSError *)error {
    [m_ai_RestorePurchases stopAnimating];
    [self.navigationController.navigationItem setTitleView:nil];
}

- (void)restoreCompleted:(NSError *)error {
    [m_ai_RestorePurchases stopAnimating];
    [self.navigationController.navigationItem setTitleView:nil];
}


#pragma mark - UIAlert Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
}

#pragma mark - UIAction Buttons
- (IBAction)onUpgradeButtonPressed:(id)sender {
    [Flurry logEvent:@"UPGRADE_SCREEN_UPGRADE_PRESSED" withParameters:[Flurry flurryUserParams]];
    
    Reachability *internetReachable = [Reachability reachabilityWithHostname:@"www.itunes.com"];
    
    if (internetReachable.isReachable && [_products count] != 0) {
        [self.navigationItem setTitleView:m_ai_RestorePurchases];
        [m_ai_RestorePurchases startAnimating];
        
        SKProduct *product = _products[0];
        
        NSLog(@"Buying %@...", product.productIdentifier);
        [[PIGIAPHelper sharedInstance] buyProduct:product];
    }
    else {
        [self loadIAPs];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot connect to iTunes Store"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)onRestoreButtonPressed:(id)sender {
    [self.navigationItem setTitleView:m_ai_RestorePurchases];
    [m_ai_RestorePurchases startAnimating];
    
    [[PIGIAPHelper sharedInstance] restoreCompletedTransactions];
}

@end
