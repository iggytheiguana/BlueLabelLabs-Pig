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
    float radiusOffset = fmaxf(fabsf(viewerOffset.vertical), fabsf(viewerOffset.horizontal))*10.0f;
    
    NSDictionary* dict = @{
                           @"layer.shadowOffset" : [NSValue valueWithCGSize:CGSizeMake(-20.0*viewerOffset.horizontal, -20.0*viewerOffset.vertical)],
                           @"layer.shadowRadius" : [NSNumber numberWithFloat:radiusOffset],
                           @"center" : [NSValue valueWithCGPoint:CGPointMake(30.0*viewerOffset.horizontal, 30.0*viewerOffset.vertical)]
                           };
    
    return dict;
}

@end
