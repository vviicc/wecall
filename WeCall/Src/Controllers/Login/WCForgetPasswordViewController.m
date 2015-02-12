//
//  WCForgetPasswordViewController.m
//  WeCall
//
//  Created by Vic on 14-12-10.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCForgetPasswordViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>


@interface WCForgetPasswordViewController ()
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;

- (IBAction)findPassword:(id)sender;
@end

@implementation WCForgetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    if(userInfoDict){
        _phoneNumberTextField.text = userInfoDict[USER_NAME_KEY];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)findPassword:(id)sender {
    NSString *phoneNumber = _phoneNumberTextField.text;
    if ([phoneNumber length] != 11) {
        [VCViewUtil showAlertMessage:@"手机号须11位" andTitle:nil];
    }
    else{
        [self findPasswordFromServer];
    }
}

-(void)findPasswordFromServer
{
    NSString *phoneNumber = _phoneNumberTextField.text;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSDictionary *parameters = @{@"username": phoneNumber};
    AFHTTPRequestOperationManager *manager = [VCNetworkingUtil httpManager];
    [manager POST:WC_SERVER_FIND_PASSWORD
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
                  
                  // 发送短信成功
                  if ([dataDict[@"result"] integerValue] == 1) {
                      
                      hud.mode = MBProgressHUDModeCustomView;
                      hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                      hud.labelText = @"发送短信成功";
                      [hud hide:YES afterDelay:2];
                      
                  }
                  
                  // 发送短信不成功
                  else if([dataDict[@"result"] integerValue] == 0){
                      hud.mode = MBProgressHUDModeText;
                      hud.labelText = @"发送短信失败，请重试";
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
