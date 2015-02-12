//
//  WCMemberCenterMainViewController.m
//  WeCall
//
//  Created by Vic on 14-12-20.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCMemberCenterMainViewController.h"
#import <WPLib/AppConnect.h>

@interface WCMemberCenterMainViewController ()

- (IBAction)gotoHomePage:(id)sender;
- (IBAction)jifenWall:(id)sender;
@end

@implementation WCMemberCenterMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)gotoHomePage:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:WC_STATIC_PAGE_SITE]];
}

- (IBAction)jifenWall:(id)sender {
    [AppConnect showList:self];
}
@end
