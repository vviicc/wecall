//
//  WCPhoneContactDetailViewController.h
//  WeCall
//
//  Created by Vic on 14-12-11.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <APAddressBook/APContact.h>

@interface WCPhoneContactDetailViewController : UIViewController

@property (strong,nonatomic) APContact *contact;
@property (nonatomic) BOOL isFromDailVC;

@end
