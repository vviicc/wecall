//
//  WCLoginViewController.m
//  WeCall
//
//  Created by Vic on 14-12-10.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCLoginViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <SSKeychain/SSKeychain.h>
#import "HHSIPUtil.h"

@interface WCLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
- (IBAction)login:(id)sender;

@end

@implementation WCLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



- (IBAction)login:(id)sender {
    NSString *phoneNumber = _phoneNumberTextField.text;
    NSString *password = _passwordTextField.text;
    if ([phoneNumber length] != 11) {
        [VCViewUtil showAlertMessage:@"手机号须11位" andTitle:nil];
    }
    else if([password length] < 6 || [password length] > 20){
        [VCViewUtil showAlertMessage:@"密码须6-20位" andTitle:nil];
    }
    else{
        [self loginFromServer];
    }
    
}

-(void)loginFromServer
{
    NSString *phoneNumber = _phoneNumberTextField.text;
    NSString *password = _passwordTextField.text;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSDictionary *parameters = @{@"username": phoneNumber,@"password":password};
    AFHTTPRequestOperationManager *manager = [VCNetworkingUtil httpManager];
    [manager POST:WC_SERVER_LOGIN
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
              
              // 登录成功
              else if([statusDict[@"succeed"] integerValue] == 1){
                  
                  
                  hud.mode = MBProgressHUDModeCustomView;
                  hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                  hud.labelText = @"登录成功";
                  [hud hide:YES afterDelay:2];
                  
                  // 保存用户信息到本地，包括用户名，环信UUID，密码使用keychain保存,这里没有返回环信UUID，暂时用空值代替
                  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                  NSDictionary *userInfoDict = @{USER_NAME_KEY:phoneNumber,USER_HUANXIN_UUID_KEY:@""};
                  [userDefaults setObject:userInfoDict forKey:USER_MODEL_USERDEFAULT];
                  [userDefaults synchronize];
                  
                  if (![SSKeychain setPassword:password forService:KEY_KEYCHAIN_SERVICE_ACCOUNT account:phoneNumber]) {
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
                  
                  [self dismissViewControllerAnimated:NO completion:nil];
                
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
              hud.mode = MBProgressHUDModeText;
              hud.labelText = @"操作失败";
              hud.detailsLabelText = error.localizedDescription;
              [hud hide:YES afterDelay:2];
          }];

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}
@end
