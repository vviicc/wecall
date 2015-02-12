//
//  WCRecordHistoryTableViewCell.h
//  WeCall
//
//  Created by Vic on 15-1-2.
//  Copyright (c) 2015年 feixiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WCRecordHistoryTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *callLengthLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
- (IBAction)download:(id)sender;
- (IBAction)email:(id)sender;
- (IBAction)deleteRecord:(id)sender;

@end
