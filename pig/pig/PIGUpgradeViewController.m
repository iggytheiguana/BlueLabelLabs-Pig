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

@interface PIGUpgradeViewController () {
    NSArray *_products;
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
    
    // Load In App Purchases
    [self loadIAPs];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
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
            [self.delegate pigUpgradeViewControllerDidClose];
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

#pragma mark - UIAction Buttons
- (IBAction)onUpgradeButtonPressed:(id)sender {
    Reachability *internetReachable = [Reachability reachabilityWithHostname:@"www.itunes.com"];
    
    if (internetReachable.isReachable && [_products count] != 0) {
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

@end
