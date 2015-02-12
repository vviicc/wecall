//
//  WCRegisterFirstStepViewController.m
//  WeCall
//
//  Created by Vic on 14-12-10.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCRegisterFirstStepViewController.h"
#import "UserModel.h"
#import "WCRegisterSecondStepViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>


#define SEGUE_REGISTER_FIRST_SECOND_STEP @"Register First 2 Second Step"

@interface WCRegisterFirstStepViewController ()
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;

@property (strong,nonatomic) UserModel *myUser;

- (IBAction)nextStep:(id)sender;

@end

@implementation WCRegisterFirstStepViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _myUser = [[UserModel alloc]init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



- (IBAction)nextStep:(id)sender {
    NSString *phoneNumber = _phoneNumberTextField.text;
    if([phoneNumber length] != 11){
        [VCViewUtil showAlertMessage:@"请输入11位的手机号码" andTitle:nil];
        _phoneNumberTextField.text = @"";
    }
    else{
        _myUser.phoneNumber = phoneNumber;
        
        // 请求验证码
        [self fetchVerficationCodeFromServer];
    }
}

-(void)fetchVerficationCodeFromServer
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSDictionary *parameters = @{@"username": _myUser.phoneNumber};
    AFHTTPRequestOperationManager *manager = [VCNetworkingUtil httpManager];
    [manager POST:WC_SERVER_SMS
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
             NSDictionary *statusDict = [responseObject objectForKey:@"status"];
             
             // 操作失败
             if ([statusDict[@"succeed"] integerValue] == 0) {
                 NSString *errorCode = statusDict[@"error_code"];
                 if ([errorCode isEqualToString:@"sms.send.1"]) {
                     NSString *errorDesc = statusDict[@"error_desc"];
                     
                     hud.mode = MBProgressHUDModeText;
                     hud.labelText = @"操作失败";
                     hud.detailsLabelText = errorDesc;
                     [hud hide:YES afterDelay:2];
                 }
             }
             
             // 操作成功
             else if([statusDict[@"succeed"] integerValue] == 1){
                 NSDictionary *dataDict = [responseObject objectForKey:@"data"];
                 
                 // 发送成功
                 if ([dataDict[@"send"] integerValue] == 1) {
                     NSString *smscode = dataDict[@"smscode"];
                     _myUser.verficationCode = smscode;
                     
                     hud.mode = MBProgressHUDModeCustomView;
                     hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                     hud.labelText = @"发送成功";
                     [hud hide:YES afterDelay:2];
                     
                     [self performSegueWithIdentifier:SEGUE_REGISTER_FIRST_SECOND_STEP sender:self];
                 }
                 
                 // 发送不成功
                 else if([dataDict[@"send"] integerValue] == 0){
                     hud.mode = MBProgressHUDModeText;
                     hud.labelText = @"发送失败，请重试";
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


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:SEGUE_REGISTER_FIRST_SECOND_STEP]){
        WCRegisterSecondStepViewController *secondStep = segue.destinationViewController;
        secondStep.myUser = _myUser;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}
@end
