//
//  WCCallHistoryTableViewCell.h
//  WeCall
//
//  Created by Vic on 15-1-2.
//  Copyright (c) 2015年 feixiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WCCallHistoryTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end
