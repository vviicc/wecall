//
//  WCMoreSettingTableViewController.m
//  WeCall
//
//  Created by Vic on 15-1-9.
//  Copyright (c) 2015年 feixiang. All rights reserved.
//

#import "WCMoreSettingTableViewController.h"
#import <SSKeychain/SSKeychain.h>
#import "HHSIPUtil.h"
#import "WCMoreWebPageViewController.h"
#import <StoreKit/StoreKit.h>
#import "UMSocial.h"
#import <MBProgressHUD/MBProgressHUD.h>


#define SEGUE_SETTING_LOGIN @"Setting 2 Login"


@interface WCMoreSettingTableViewController ()<SKStoreProductViewControllerDelegate,UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *showYourPhoneSwitch;
- (IBAction)changeShowPhone:(id)sender;

- (IBAction)logout:(id)sender;

@end

@implementation WCMoreSettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setup
{
    // 如果之前没有显号设置则默认显号，如果有设置则使用设置值
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([userDefaults objectForKey:CALL_SHOW_YOURPHONENUM] == nil || [[userDefaults objectForKey:CALL_SHOW_YOURPHONENUM] boolValue] == YES){
        [_showYourPhoneSwitch setOn:YES animated:NO];
    }
    else if ([[userDefaults objectForKey:CALL_SHOW_YOURPHONENUM] boolValue] == NO){
        [_showYourPhoneSwitch setOn:NO animated:NO];
    }
}

- (IBAction)changeShowPhone:(id)sender {
    UISwitch *mySwitch = (UISwitch *)sender;
    // 保存设置值
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@([mySwitch isOn]) forKey:CALL_SHOW_YOURPHONENUM];
    [userDefaults synchronize];
}

- (IBAction)logout:(id)sender {
    UIAlertView *logoutAlertView = [[UIAlertView alloc]initWithTitle:@"退出当前账号" message:@"是否退出当前账号？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    logoutAlertView.tag = 11;
    [logoutAlertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // 退出账号
    if (alertView.tag == 11) {
        if (alertView.cancelButtonIndex != buttonIndex) {
            // 删除本地的账户信息
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
            NSString *phoneNumber = userInfoDict[USER_NAME_KEY];
            [userDefaults removeObjectForKey:USER_MODEL_USERDEFAULT];
            [userDefaults synchronize];
            
            if (![SSKeychain deletePasswordForService:KEY_KEYCHAIN_SERVICE_ACCOUNT account:phoneNumber]) {
                NSLog(@"Fail to delete password in keychain!");
            }
            
            // 删除sip账号
            HHSIPUtil *sipUtil = [HHSIPUtil sharedInstance];
            [sipUtil deleteAccount2];
            
            [self performSegueWithIdentifier:SEGUE_SETTING_LOGIN sender:self];
            
        }
    }
    
    // 联系客服
    if (alertView.tag == 22) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",WC_STATIC_CONTACT_US]]];
            
        }
    }

}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger selectedSection = indexPath.section;
    NSInteger selectedRow = indexPath.row;
    
    // 资费说明
    if(selectedSection == 2 && selectedRow == 0){
        WCMoreWebPageViewController *webPageVC = [self.storyboard instantiateViewControllerWithIdentifier:@"More About Page Storyboard"];
        webPageVC.loadURLString = WC_STATIC_PAGE_ZFSM;
        webPageVC.webPageTitle = @"资费说明";
        [self.navigationController pushViewController:webPageVC animated:YES];
        
    }
    
    // 帮助中心
    else if(selectedSection == 2 && selectedRow == 1){
        WCMoreWebPageViewController *webPageVC = [self.storyboard instantiateViewControllerWithIdentifier:@"More About Page Storyboard"];
        webPageVC.loadURLString = WC_STATIC_PAGE_HELP;
        webPageVC.webPageTitle = @"帮助中心";
        [self.navigationController pushViewController:webPageVC animated:YES];
        
    }
    
    // 关于我们
    else if(selectedSection == 3 && selectedRow == 3){
        WCMoreWebPageViewController *webPageVC = [self.storyboard instantiateViewControllerWithIdentifier:@"More About Page Storyboard"];
        webPageVC.loadURLString = WC_STATIC_PAGE_ABOUT;
        webPageVC.webPageTitle = @"关于我们";
        [self.navigationController pushViewController:webPageVC animated:YES];
        
    }
    
    // 联系我们
    else if (selectedSection == 3 && selectedRow == 2){
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:WC_STATIC_CONTACT_US message:nil delegate:self cancelButtonTitle:@"拨打" otherButtonTitles:@"取消", nil];
        alert.tag = 22;
        [alert show];
    }
    
    // 评分页面
    else if (selectedSection == 3 && selectedRow == 1){
        MBProgressHUD *hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hub.labelText = @"加载APP评分页面中...";
        SKStoreProductViewController *storeProductViewContorller = [[SKStoreProductViewController alloc] init];
        storeProductViewContorller.delegate = self;
        [storeProductViewContorller loadProductWithParameters:
         @{SKStoreProductParameterITunesItemIdentifier : WC_STATIC_APPID} completionBlock:^(BOOL result, NSError *error) {
             if(error){
                 [VCViewUtil showAlertMessage:@"加载失败" andTitle:nil];
                 [hub hide:YES];
             }else{
                 [hub hide:YES];
                 [self presentViewController:storeProductViewContorller animated:YES completion:nil];
             }
         }];
    }
    
    // 分享页面
    else if(selectedSection == 3 && selectedRow == 0){

        [UMSocialSnsService presentSnsIconSheetView:self
                                             appKey:nil
                                          shareText:@"移动互联网时代的最佳网络电话应用！"
                                         shareImage:nil
                                    shareToSnsNames:[NSArray arrayWithObjects:UMShareToSina,UMShareToTencent,UMShareToSms,UMShareToEmail,nil]
                                           delegate:nil];
    }
}


#pragma mark -SKStoreProductViewControllerDelegate回调函数

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
