//
//  WCCallAndRecordHistoryTableViewCell.h
//  WeCall
//
//  Created by Vic on 15-1-1.
//  Copyright (c) 2015年 feixiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WCCallAndRecordHistoryTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;

@end
