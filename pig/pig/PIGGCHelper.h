//
//  PIGGCHelper.h
//  pig
//
//  Created by Jordan Gurrieri on 9/6/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "GCHelper.h"

@interface PIGGCHelper : GCHelper

+ (PIGGCHelper *)sharedInstance;
- (void)getHighestGameScore;
- (void)getTotalScore;

@end
