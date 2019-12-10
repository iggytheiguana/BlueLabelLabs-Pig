//
//  UINavigationController+PIGCustomNavigationController.m
//  pig
//
//  Created by Jordan Gurrieri on 9/17/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "UINavigationController+PIGCustomNavigationController.h"

@implementation UINavigationController (PIGCustomNavigationController)

- (void)applyCustomStyle {
    if (@available(iOS 13.0, *)) {
        [self setModalPresentationStyle: UIModalPresentationFullScreen];
    }
    
    [self.navigationBar setBarTintColor:[UIColor whiteColor]];
    
    // Hide the Navigation bar line
    for (UIView *view in self.navigationBar.subviews) {
        for (UIView *view2 in view.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]]) {
                [view2 removeFromSuperview];
            }
        }
    }
}

@end
