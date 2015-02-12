//
//  WCDirectCallingViewController.h
//  WeCall
//
//  Created by Vic on 14-12-13.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WCDirectCallingViewController : UIViewController

@property (nonatomic,strong) NSString *calledPhoneNumber;
@property (nonatomic,strong) NSDictionary *calledUserContact;      // 联系人姓名和电话类型，没有则为未知

@property (nonatomic) BOOL isCallOut;                       // 是否是呼出电话
@property (nonatomic,strong) NSString *callDate;            // 呼出日期，时间戳


@end
