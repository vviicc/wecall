//
//  WCBalanceTableViewController.m
//  WeCall
//
//  Created by Vic on 14-12-20.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCBalanceTableViewController.h"
#import <SSKeychain/SSKeychain.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface WCBalanceTableViewController ()
@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UILabel *balanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *availableDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *suitLabel;

@end

@implementation WCBalanceTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)setup
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    NSString *username = userInfoDict[USER_NAME_KEY];
    NSString *password = [SSKeychain passwordForService:KEY_KEYCHAIN_SERVICE_ACCOUNT account:username];
    
    // 用户登陆过
    if (username && password) {
        [self autoLoginFromServerWithUserName:username andPasswor:password];
    }
    else{
        [VCViewUtil showAlertMessage:@"请先登录" andTitle:nil];
    }
}

-(void)autoLoginFromServerWithUserName:(NSString *)username andPasswor:(NSString *)password
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSDictionary *parameters = @{@"username": username,@"password":password};
    AFHTTPRequestOperationManager *manager = [VCNetworkingUtil httpManager];
    [manager POST:WC_SERVER_LOGIN
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              
              NSDictionary *statusDict = [responseObject objectForKey:@"status"];
              
              // 登录失败
              if ([statusDict[@"succeed"] integerValue] == 0) {
                  [hud hide:YES];
                  [VCViewUtil showAlertMessage:@"查询失败，请重新登录再查询" andTitle:nil];
              }
              
              // 登录成功
              else if([statusDict[@"succeed"] integerValue] == 1){
                  [hud hide:YES];
                  NSDictionary *dataDict = responseObject[@"data"];
                  _accountLabel.text = dataDict[@"username"];
                  _balanceLabel.text = dataDict[@"money"];
                  _suitLabel.text = [dataDict[@"suite"] isEqualToString:@""] ? @"无" : dataDict[@"suite"];
                  _availableDateLabel.text = dataDict[@"validtime"];
                }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
              hud.mode = MBProgressHUDModeText;
              hud.labelText = @"网络请求失败";
              hud.detailsLabelText = error.localizedDescription;
              [hud hide:YES afterDelay:2];
          }];
}


@end
