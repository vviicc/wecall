//
//  AppDelegate.m
//  WeCall
//
//  Created by Vic on 14-12-10.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "AppDelegate.h"
#import "WanpuPay/WanpuConnect.h"
#import "WCDirectCallingViewController.h"
#import "UMSocial.h"
#import "HHSIPUtil.h"
#import "EaseMob.h"
#import "CoreData+MagicalRecord.h"
#import <WPLib/AppConnect.h>
#import <pjsua-lib/pjsua.h>



@interface AppDelegate ()

//@property (nonatomic,strong) NSInputStream *read;
//@property (nonatomic,strong) NSOutputStream *write;

@end

@implementation AppDelegate

static pj_thread_desc   a_thread_desc;
static pj_thread_t     *a_thread;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 推送权限
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){//8.0以后使用这种方法来注册推送通知
        
        UIUserNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:myTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }else{
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
    }
    
//    [self setupSocket];
    [self setupEaseMob:application WithOptions:launchOptions];
    
    // 第三方支付
    [WanpuLog setLogThreshold:LOG_DEBUG];
    // 友盟社会化分享
    [UMSocialData setAppKey:THIRD_PARTY_UMENG_APPID];
    
    //初始化
    [WanpuConnect getConnect:@"7fb6c63e59238bca306d308dd5d5376e" pid:@"Appstore"];
    [AppConnect getConnect:@"7fb6c63e59238bca306d308dd5d5376e" pid:@"appstore"];
    
    
    //建立通知监听
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(paySucess:) name:WANPU_PAY_SUCESS object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(payFailed:) name:WANPU_PAY_FAILED object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(signFailed:) name:WANPU_SIGN_FAILED  object:nil];
    
    //单任务系统handleURL处理
    [WanpuConnect singleTaskApplication:application options:launchOptions];
    return YES;
}

/*
-(void)setupSocket
{
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)WC_SIP_HOST_IP,WC_SIP_HOST_PORT, &readStream, &writeStream);
    
    CFReadStreamSetProperty(readStream,kCFStreamNetworkServiceType,kCFStreamNetworkServiceTypeVoIP);
    CFWriteStreamSetProperty(writeStream, kCFStreamNetworkServiceType, kCFStreamNetworkServiceTypeVoIP);
    
    self.read = (__bridge NSInputStream *)readStream;
    [self.read setDelegate:self];
    [self.read scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.read open];
    
    self.write = (__bridge NSOutputStream *)writeStream;
    [self.write setDelegate:self];
    [self.write scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.write open];
}
 */

-(void)setupEaseMob:(UIApplication *)application WithOptions:(NSDictionary *)launchOptions
{
#warning SDK注册 APNS文件的名字, 需要与后台上传证书时的名字一一对应
    NSString *apnsCertName = nil;
#if DEBUG
    apnsCertName = @"chatdemoui_dev";
#else
    apnsCertName = @"chatdemoui";
#endif
    [[EaseMob sharedInstance] registerSDKWithAppKey:@"feixiang#24h" apnsCertName:nil];
    
    [[[EaseMob sharedInstance] chatManager] setIsAutoFetchBuddyList:YES];
    
#warning 注册为SDK的ChatManager的delegate (及时监听到申请和通知)
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
    
    //以下一行代码的方法里实现了自动登录，异步登录，需要监听[didLoginWithInfo: error:]
    //demo中此监听方法在MainViewController中
    [[EaseMob sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    
#warning 如果使用MagicalRecord, 要加上这句初始化MagicalRecord
    //demo coredata, .pch中有相关头文件引用
    [MagicalRecord setupCoreDataStackWithStoreNamed:[NSString stringWithFormat:@"%@.sqlite", @"UIDemo"]];
    
    
}


/*
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"handleEvent");
}
 */

#pragma mark - 第三方支付

-(void)debugOrderInfo:(NSNotification *)notify{
    WanpuOrderObj *wanpuObj = notify.object;
    NSLog(@"%d",wanpuObj.payType);           //支付渠道类型 1银行卡 2支付宝 3充值卡
    NSLog(@"%d",wanpuObj.payResult);         //支付结果码   1成功  2失败   3取消支付
    NSLog(@"%d",wanpuObj.payStatusCode);     //支付状态码，随支付渠道不同规则会有变化
    NSLog(@"%@",wanpuObj.payStatusMessage);  //支付结果信息
    NSLog(@"%@",wanpuObj.goodsOrderID);
    NSLog(@"%@",wanpuObj.wanpuOrderID);
    NSLog(@"%@",wanpuObj.goodsName);
    NSLog(@"%@",wanpuObj.goodsInfo);
    NSLog(@"%@",wanpuObj.goodsPrice);
}



-(void)paySucess:(NSNotification *)notify{
    NSLog(@"支付成功!");
    [self debugOrderInfo:notify];
    
}
-(void)payFailed:(NSNotification *)notify{
    NSLog(@"支付失败!");
    [self debugOrderInfo:notify];
}

-(void)signFailed:(NSNotification *)notify{
    NSLog(@"验签错误!");
    [self debugOrderInfo:notify];
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    [WanpuConnect parseURL:url application:application];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"=====回调处理=====%@",url);
    [WanpuConnect parseURL:url application:application];
    return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {

    [self performSelectorOnMainThread:@selector(keepAlive) withObject:nil waitUntilDone:YES];
    [application setKeepAliveTimeout:600 handler: ^{
        [self performSelectorOnMainThread:@selector(keepAlive) withObject:nil waitUntilDone:YES];
    }];

}

- (void)keepAlive {
    int i;
    
    if (!pj_thread_is_registered())
    {
        pj_thread_register("ipjsua", a_thread_desc, &a_thread);
    }
    
    /* Since iOS requires that the minimum keep alive interval is 600s,
     * application needs to make sure that the account's registration
     * timeout is long enough.
     */
    

    
    for (i = 0; i < (int)pjsua_acc_get_count(); ++i) {
        if (pjsua_acc_is_valid(i)) {
            pjsua_acc_set_registration(i, PJ_TRUE);
        }
    }
    

}

#pragma mark - 来电回调方法

-(void)handleIncomingCall:(NSString *)callNumber;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        WCDirectCallingViewController *dailVC = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"VOIP Dail Storyboard"];
        dailVC.calledPhoneNumber = callNumber;
        dailVC.isCallOut = NO;
        NSDate *currentDate = [NSDate date];
        NSTimeInterval timeInterval = currentDate.timeIntervalSince1970;
        NSNumber *timeNumber = [NSNumber numberWithDouble:timeInterval];
        NSString *callDateInterval = [timeNumber stringValue];
        dailVC.callDate = callDateInterval;
        [self.window.rootViewController presentViewController:dailVC animated:YES completion:nil];
        [self showNotificationWithAction:@"来电话啦" andContent:@"接听"];
    });
}


- (void)showNotificationWithAction:(NSString *)action andContent:(NSString *)content
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = content;
    notification.alertAction = action;
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {

}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"didReceiveLocalNotification");
}

@end
