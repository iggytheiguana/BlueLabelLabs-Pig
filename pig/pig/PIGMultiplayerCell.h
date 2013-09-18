//
//  PIGMultiplayerCell.h
//  pig
//
//  Created by Jordan Gurrieri on 9/18/13.
//  Copyright (c) 2013 bluelabellabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PIGMultiplayerCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iv_opponentLabel;
@property (weak, nonatomic) IBOutlet UILabel *lbl_nameOpponent;
@property (weak, nonatomic) IBOutlet UILabel *lbl_pointsOpponent;
@property (weak, nonatomic) IBOutlet UILabel *lbl_pointsPlayer;
@property (weak, nonatomic) IBOutlet UILabel *lbl_turn;

@end
