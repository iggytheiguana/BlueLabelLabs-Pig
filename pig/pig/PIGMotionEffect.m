//
//  PIGMotionEffect.m
//  pig
//
//  Created by Jordan Gurrieri on 9/1/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGMotionEffect.h"

@implementation PIGMotionEffect

- (NSDictionary *)keyPathsAndRelativeValuesForViewerOffset:(UIOffset)viewerOffset {
    NSDictionary* dict = @{@"center" : [NSValue valueWithCGPoint:CGPointMake(3.4, 1.2)], @"layer.shadowOffset" : [NSValue valueWithCGPoint:CGPointMake(-1.1, 0.0)]};
//    NSDictionary* dict = @{@"center" : [NSValue valueWithCGPoint:CGPointMake(3.4, 1.2)]};
    return dict;
}

@end
