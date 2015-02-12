//
//  WCCallSettingTableViewController.m
//  WeCall
//
//  Created by Vic on 14-12-13.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCCallSettingTableViewController.h"

@interface WCCallSettingTableViewController ()

@property (nonatomic,strong) NSArray *dataArray;
@property (nonatomic) wc_call_type selectedCallType;

@end

@implementation WCCallSettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // 保存设置
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(_selectedCallType) forKey:CALL_TYPE_SETTTING];
    [userDefaults synchronize];
}

-(void)setup
{
    _dataArray = [NSArray arrayWithObjects:@"默认选择直拨",@"默认选择回拨", nil];
    
    // 如果之前没有设置则默认勾选直拨，如果有设置则使用设置值
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([userDefaults objectForKey:CALL_TYPE_SETTTING] == nil || [[userDefaults objectForKey:CALL_TYPE_SETTTING] integerValue] == DirectCall){
        _selectedCallType = DirectCall;
    }
    else if ([[userDefaults objectForKey:CALL_TYPE_SETTTING] integerValue] == BackCall){
        _selectedCallType = BackCall;
    }
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Call Setting Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if(cell == nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = _dataArray[indexPath.row];
    
    if(_selectedCallType == DirectCall){
        if(indexPath.row == 0)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else if(_selectedCallType == BackCall){
        if(indexPath.row == 1)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0){
        _selectedCallType = DirectCall;
    }
    else if (indexPath.row == 1){
        _selectedCallType = BackCall;
    }
    
    [self.tableView reloadData];
}

@end
