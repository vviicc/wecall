//
//  WCPhoneContactDetailViewController.m
//  WeCall
//
//  Created by Vic on 14-12-11.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCPhoneContactDetailViewController.h"
#import <APAddressBook/APPhoneWithLabel.h>
#import "WCPhoneContactDetailTableViewCell.h"

@interface WCPhoneContactDetailViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (nonatomic,strong) NSArray *phonesWithLabelArray;
@end

@implementation WCPhoneContactDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)setup
{
    NSArray *phones = _contact.phonesWithLabels;
    _phonesWithLabelArray = [NSArray arrayWithArray:phones];
    
    UIImage *thumbnail = _contact.thumbnail;
    _nameLabel.text = _contact.compositeName;
    _avatarImageView.image = thumbnail ? thumbnail : [UIImage imageNamed:@"avatar-128"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_phonesWithLabelArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *contactDetailCellIdentifier = @"Phone Contact Detail Cell";
    WCPhoneContactDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:contactDetailCellIdentifier forIndexPath:indexPath];
    if(cell == nil){
        cell = [[WCPhoneContactDetailTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:contactDetailCellIdentifier];
    }
    
    APPhoneWithLabel *phoneWithLabel = (APPhoneWithLabel *)(_phonesWithLabelArray[indexPath.row]);
    cell.typeLabel.text = phoneWithLabel.label;
    cell.phoneLabel.text = phoneWithLabel.phone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    APPhoneWithLabel *phoneWithLabel = (APPhoneWithLabel *)(_phonesWithLabelArray[indexPath.row]);
    NSString *selectedPhone = phoneWithLabel.phone;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_CALL_PHONE object:[self handlePhoneNum:selectedPhone]];
    if(_isFromDailVC){
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{
        [self.tabBarController setSelectedIndex:0];

    }

}

#pragma mark - 去掉手机号码中的特殊字符

- (NSString *)handlePhoneNum:(NSString *)oldPhoneNum
{
    return [[[[[oldPhoneNum stringByReplacingOccurrencesOfString:@"-" withString:@""]
               stringByReplacingOccurrencesOfString:@"(" withString:@""]
              stringByReplacingOccurrencesOfString:@")" withString:@""]
             stringByReplacingOccurrencesOfString:@" " withString:@""]
            stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
