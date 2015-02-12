//
//  ModifyPasswordViewController.m
//  WeCall
//
//  Created by Vic on 14-12-11.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCModifyPasswordViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <SSKeychain/SSKeychain.h>

@interface WCModifyPasswordViewController ()

@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *myNewPasswordTextField;
- (IBAction)modifyPassword:(id)sender;
@end

@implementation WCModifyPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    _phoneNumberLabel.text = userInfoDict[USER_NAME_KEY];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)modifyPassword:(id)sender {
    NSString *oldPassword = _oldPasswordTextField.text;
    NSString *newPassword = _myNewPasswordTextField.text;
    
    if([oldPassword length] < 6 || [oldPassword length] > 20){
        [VCViewUtil showAlertMessage:@"原密码须6-20位" andTitle:nil];
    }
    else if([newPassword length] < 6 || [newPassword length] > 20){
        [VCViewUtil showAlertMessage:@"新密码须6-20位" andTitle:nil];
    }
    else{
        [self modifyPasswordFromServer];
    }
}

-(void)modifyPasswordFromServer
{
    NSString *userName = _phoneNumberLabel.text;
    NSString *oldPassword = _oldPasswordTextField.text;
    NSString *newPassword = _myNewPasswordTextField.text;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSDictionary *parameters = @{@"username": userName,@"oldpassword":oldPassword,@"password":newPassword};
    AFHTTPRequestOperationManager *manager = [VCNetworkingUtil httpManager];
    [manager POST:WC_SERVER_MODIFY_PASSWORD
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
                  
                  // 修改成功
                  if ([dataDict[@"result"] integerValue] == 1) {
                      
                      hud.mode = MBProgressHUDModeCustomView;
                      hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                      hud.labelText = @"修改成功";
                      [hud hide:YES afterDelay:2];
                      
                      // 保存新密码
                      if (![SSKeychain setPassword:newPassword forService:KEY_KEYCHAIN_SERVICE_ACCOUNT account:userName]) {
                          NSLog(@"Fail to save password in keychain!");
                      }
                      
                      _oldPasswordTextField.text = @"";
                      _myNewPasswordTextField.text = @"";
                  }
                  
                  // 修改不成功
                  else if([dataDict[@"result"] integerValue] == 0){
                      hud.mode = MBProgressHUDModeText;
                      hud.labelText = @"修改失败，请重试";
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
