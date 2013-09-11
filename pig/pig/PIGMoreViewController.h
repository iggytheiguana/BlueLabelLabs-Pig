//
//  PIGMoreViewController.h
//  pig
//
//  Created by Jordan Gurrieri on 9/10/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PIGMoreViewControllerDelegate <NSObject>
- (void)pigMoreViewControllerDidClose;
@end

@interface PIGMoreViewController : UIViewController < UITableViewDelegate >

@property (weak, nonatomic) id <PIGMoreViewControllerDelegate> delegate;

- (IBAction)onHomeButtonPressed:(id)sender;

@end
