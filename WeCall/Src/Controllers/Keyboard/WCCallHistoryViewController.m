//
//  WCCallHistoryViewController.m
//  WeCall
//
//  Created by Vic on 15-1-2.
//  Copyright (c) 2015年 feixiang. All rights reserved.
//

#import "WCCallHistoryViewController.h"
#import "WCCallHistoryTableViewCell.h"
#import "WCCallHistoryHeader.h"


@interface WCCallHistoryViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *callHistoryTableView;

- (IBAction)call:(id)sender;

@end

@implementation WCCallHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)setup
{

    self.navigationItem.title = _name;
    if([_callHistoryArray count] > 0){
        [self scrollToButtom];
    }

    
}

-(void)scrollToButtom
{
    [_callHistoryTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([_callHistoryArray count] - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 65.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_callHistoryArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *callHistoryCellIdentifier = @"Call History Cell";
    WCCallHistoryTableViewCell *callHistoryCell = [tableView dequeueReusableCellWithIdentifier:callHistoryCellIdentifier forIndexPath:indexPath];
    if (callHistoryCell == nil) {
        callHistoryCell = [[WCCallHistoryTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:callHistoryCellIdentifier];
    }
    
    NSDictionary *lastestCallHistoryDict = _callHistoryArray[indexPath.row];
    NSString *inOrOut = [lastestCallHistoryDict[kCallHistoryCallInOrOut] isEqualToString:@"in"] ? @"来电" :@"去电";
    NSString *callStatus = lastestCallHistoryDict[kCallHistoryCallDetail];
    NSString *callDetail = [NSString stringWithFormat:@"%@ - %@",inOrOut,callStatus];
    NSString *callDateIntervalString = lastestCallHistoryDict[kCallHistoryCallDate];
    NSTimeInterval callDateInterval = [callDateIntervalString doubleValue];
    NSDate *calledDate = [NSDate dateWithTimeIntervalSince1970:callDateInterval];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSString *calledDateString = [formatter stringFromDate:calledDate];
    
    callHistoryCell.phoneLabel.text = _phone;
    callHistoryCell.detailLabel.text = callDetail;
    callHistoryCell.dateLabel.text = calledDateString;
    return callHistoryCell;
}



- (IBAction)call:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_CALL_PHONE object:_phone];

}


@end
