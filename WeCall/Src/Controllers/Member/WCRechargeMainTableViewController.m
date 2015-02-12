//
//  WCRechargeMainTableViewController.m
//  WeCall
//
//  Created by Vic on 14-12-28.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCRechargeMainTableViewController.h"
#import <WanpuPay/WanpuConnect.h>
#import <MBProgressHUD/MBProgressHUD.h>


@interface WCRechargeMainTableViewController ()

@end

@implementation WCRechargeMainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 充值30元
    if (indexPath.row == 0) {
        [self payGoods:@"30.00"];
    }
    // 充值50元
    else if (indexPath.row == 1){
        [self payGoods:@"50.00"];

    }
    // 充值100元
    else if (indexPath.row == 2){
        [self payGoods:@"100.00"];

    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

}

// 生成订单号

- (void)payGoods:(NSString *)money{
    

    // 用户名
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    NSString *userName = userInfoDict[USER_NAME_KEY];
    
    // 请求订单号URL
    NSString *tradeURL = [NSString stringWithFormat:@"%@username=%@&money=%@",WC_SERVER_TRADENO_URL,userName,money];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc]init];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain",@"text/html", nil];

    [manager GET:tradeURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [hud hide:YES];
        NSString *fetchedTradeNO = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        //创建订单
        WanpuOrderObj *wanpuOrder=[[WanpuOrderObj alloc] init];
        wanpuOrder.goodsName=@"充值";                       //商品名称，必填
        wanpuOrder.goodsPrice= money;                        //物品价格，必填(单位元，精确到小数点后两位)
        wanpuOrder.goodsInfo= @"网络电话充值";                          //物品介绍，必填
        wanpuOrder.goodsOrderID= fetchedTradeNO;     //生成订单号，必填
        wanpuOrder.customUserID= userName;            //用户账号，选填
        wanpuOrder.payNotifyURL= WC_SERVER_TRADE_NOTIFY;           //购买成功后通知服务器地址，最好填写
        wanpuOrder.goodsImage= nil; //物品图片，选填
        
        //提交订单，进入支付页面
        
        [WanpuConnect payCenter:self WanpuOrderObj:wanpuOrder];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"请求订单号失败";
        hud.detailsLabelText = error.localizedDescription;
        [hud hide:YES afterDelay:2];
    }];
}



@end
