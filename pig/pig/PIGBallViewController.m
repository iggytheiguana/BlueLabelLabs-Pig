//
//  PIGBallViewController.m
//  pig
//
//  Created by Jordan Gurrieri on 8/28/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import "PIGBallViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface PIGBallViewController ()

@property (nonatomic) UIDynamicAnimator* animator;
@property (nonatomic, weak) UIView *ballView;
@property (nonatomic) UIAttachmentBehavior* touchAttachmentBehavior;

@end

@implementation PIGBallViewController

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
    
    UIDynamicAnimator* animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    int numberOfLinks = 9;
    CGSize linkSize = CGSizeMake(5, 10);
    float spaceBetweenLinks = 2.f;
    NSMutableArray *linksArray = [NSMutableArray array];
    float currentY = self.postView.frame.origin.y + self.postView.bounds.size.height;
    
    
    UIView *previousLink = self.postView;
    
    for (int i = 0; i < numberOfLinks; i++) {
        UIView *link = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - linkSize.width/2, currentY + spaceBetweenLinks, linkSize.width, linkSize.height)];
        link.backgroundColor = [UIColor blueColor];
        [self.view addSubview:link];
        
        UIAttachmentBehavior *attachmentBehavior = nil;
        attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:link attachedToAnchor:self.postView.center];
        
        
        // You can mess with these if you want
        //        [attachmentBehavior setFrequency:50.0];
        //        [attachmentBehavior setDamping:1.0];
        
        [animator addBehavior:attachmentBehavior];
        
        currentY += linkSize.height + spaceBetweenLinks;
        [linksArray addObject:link];
        previousLink = link;
    }
    
    
    // Create the ball
    CGSize ballSize = CGSizeMake(66, 66);
    UIView *ballView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - ballSize.width/2, currentY + spaceBetweenLinks, ballSize.width, ballSize.height)];
    ballView.backgroundColor = [UIColor greenColor];
    ballView.layer.cornerRadius = ballSize.width/2; // Note: there'll be errors in the collision since this is still a square, but this is just an example.
    [self.view addSubview:ballView];
    
    self.ballView = ballView;
    
    
    // Connect the ball to the chain
    UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:previousLink
                                                                           attachedToItem:ballView];
    [animator addBehavior:attachmentBehavior];
    
    // Apply gravity and collision
    [linksArray addObject:ballView];
    UIGravityBehavior *gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:linksArray];
    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:linksArray];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [animator addBehavior:gravityBeahvior];
    [animator addBehavior:collisionBehavior];
    
    self.animator = animator;
}


// Let the user pull the ball around
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIAttachmentBehavior *touchAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.ballView
                                                                              attachedToAnchor:self.ballView.center];
    [self.animator addBehavior:touchAttachmentBehavior];
    [touchAttachmentBehavior setFrequency:1.0];
    [touchAttachmentBehavior setDamping:0.1];
    self.touchAttachmentBehavior = touchAttachmentBehavior;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    self.touchAttachmentBehavior.anchorPoint = [touch locationInView:self.view];;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.animator removeBehavior:self.touchAttachmentBehavior];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.animator removeBehavior:self.touchAttachmentBehavior];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
