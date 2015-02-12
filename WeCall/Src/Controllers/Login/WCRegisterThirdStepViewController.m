//
//  WCRegisterThirdStepViewController.m
//  WeCall
//
//  Created by Vic on 14-12-10.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCRegisterThirdStepViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <SSKeychain/SSKeychain.h>
#import "HHSIPUtil.h"

@interface WCRegisterThirdStepViewController ()
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

- (IBAction)register:(id)sender;
@end

@implementation WCRegisterThirdStepViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



- (IBAction)register:(id)sender {
    NSString *password = _passwordTextField.text;
    if([password length] < 6 || [password length] > 20){
        [VCViewUtil showAlertMessage:@"密码须6-20位" andTitle:nil];
    }
    else{
        _myUser.password = password;
        [self registerFromServer];
    }
}

- (void)registerFromServer
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSDictionary *parameters = @{@"username": _myUser.phoneNumber,@"password":_myUser.password};
    AFHTTPRequestOperationManager *manager = [VCNetworkingUtil httpManager];
    [manager POST:WC_SERVER_REGISTER
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              
              NSDictionary *statusDict = [responseObject objectForKey:@"status"];
              
              // 操作失败
              if ([statusDict[@"succeed"] integerValue] == 0) {
                  // NSString *errorCode = statusDict[@"error_code"];
                  NSString *errorDesc = statusDict[@"error_desc"];
                  
                  hud.mode = MBProgressHUDModeText;
                  hud.labelText = @"操作失败";
                  hud.detailsLabelText = errorDesc;
                  [hud hide:YES afterDelay:2];
              }
              
              // 操作成功
              else if([statusDict[@"succeed"] integerValue] == 1){
                  NSDictionary *dataDict = [responseObject objectForKey:@"data"];
                  
                  // 注册成功
                  if ([dataDict[@"result"] integerValue] == 1) {
                      NSString *hxUUID = dataDict[@"uuid"];
                      _myUser.hxUUID = hxUUID;
                      
                      hud.mode = MBProgressHUDModeCustomView;
                      hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                      hud.labelText = @"注册成功";
                      [hud hide:YES afterDelay:2];
                      
                      // 保存用户信息到本地，包括用户名，环信UUID，密码使用keychain保存
                      NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                      NSDictionary *userInfoDict = @{USER_NAME_KEY:_myUser.phoneNumber,USER_HUANXIN_UUID_KEY:_myUser.hxUUID};
                      [userDefaults setObject:userInfoDict forKey:USER_MODEL_USERDEFAULT];
                      [userDefaults synchronize];
                      
                      if (![SSKeychain setPassword:_myUser.password forService:KEY_KEYCHAIN_SERVICE_ACCOUNT account:_myUser.phoneNumber]) {
                          NSLog(@"Fail to save password in keychain!");
                      }
                      
                      // 登录sip服务器
                      HHSIPUtil *sharedSIPUtil = [HHSIPUtil sharedInstance];
                      if ([sharedSIPUtil registerSIP2]) {
                      }
                      else{
                          [VCViewUtil showAlertMessage:@"登录Sip服务器失败" andTitle:nil];
                      }
                      
                      [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_LOGIN_SUCCESS object:nil];
                      
                      // 回到主界面
                      [self dismissViewControllerAnimated:NO completion:nil];

                  }
                  
                  // 注册不成功
                  else if([dataDict[@"result"] integerValue] == 0){
                      hud.mode = MBProgressHUDModeText;
                      hud.labelText = @"注册失败，请重试";
                      [hud hide:YES afterDelay:2];
                  }
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
              hud.mode = MBProgressHUDModeText;
              hud.labelText = @"操作失败";
              hud.detailsLabelText = error.localizedDescription;
              [hud hide:YES afterDelay:2];
          }];
}

@end
