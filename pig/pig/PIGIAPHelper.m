//
//  PIGIAPHelper.m
//  pig
//
//  Created by Jordan Gurrieri on 8/29/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGIAPHelper.h"

NSString *const IAPUnlockTwoPlayerGameProductIdentifier = @"com.bluelabellabs.pig.unlock2playergame";

@implementation PIGIAPHelper

+ (PIGIAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static PIGIAPHelper *sharedInstance;
    dispatch_once(&once, ^{
        NSSet *productIdentifiers = [NSSet setWithObjects:
                                     @"com.bluelabellabs.pig.unlock2playergame",
                                     nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

@end
