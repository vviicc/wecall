//
//  WCCardRechargeViewController.m
//  WeCall
//
//  Created by Vic on 14-12-28.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCCardRechargeViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface WCCardRechargeViewController ()
@property (weak, nonatomic) IBOutlet UITextField *cardNumberTextField;
@property (weak, nonatomic) IBOutlet UITextField *cardPasswordTextField;
- (IBAction)recharge:(id)sender;

@end

@implementation WCCardRechargeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)recharge:(id)sender {
    NSString *cardNumber = _cardNumberTextField.text;
    NSString *cardPassword = _cardPasswordTextField.text;
    
    // 用户手机号
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    NSString *userName = userInfoDict[USER_NAME_KEY];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSDictionary *parameters = @{@"username": userName,@"card_number":cardNumber,@"card_passwd":cardPassword};
    AFHTTPRequestOperationManager *manager = [VCNetworkingUtil httpManager];
    [manager POST:WC_SERVER_RECHARGE
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
                  
                  // 充值成功
                  if ([dataDict[@"result"] integerValue] == 1) {
                      
                      hud.mode = MBProgressHUDModeCustomView;
                      hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                      hud.labelText = @"充值成功";
                      [hud hide:YES afterDelay:2];
                      
                  }
                  
                  // 充值不成功
                  else if([dataDict[@"result"] integerValue] == 0){
                      hud.mode = MBProgressHUDModeText;
                      hud.labelText = @"充值失败，请重试";
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
