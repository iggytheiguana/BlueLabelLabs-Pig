//
//  PIGIAPHelper.h
//  pig
//
//  Created by Jordan Gurrieri on 8/29/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "IAPHelper.h"

UIKIT_EXTERN NSString *const IAPUnlockTwoPlayerGameProductIdentifier;

@interface PIGIAPHelper : IAPHelper

+ (PIGIAPHelper *)sharedInstance;

@end
