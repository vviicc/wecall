//
//  Global.h
//  WeCall
//
//  Created by Vic on 14-12-10.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#ifndef WeCall_Global_h
#define WeCall_Global_h

/**
 *    配置网络请求 baseURL
 */

#define WC_SERVER_BASERUL @"http://weiku.feixiang.hk/apido/"
#define WC_SIP_HOST_IP @"42.62.55.55"
#define WC_SIP_HOST_PORT 5060

/**
 *    网络请求 URL
 */

// --------------------用户模块----------------------

#define WC_SERVER_SMS @"sms/send"                   // 获取手机验证码 post
#define WC_SERVER_REGISTER @"member/register"       // 用户注册 post
#define WC_SERVER_LOGIN @"member/login"             // 用户登录 post
#define WC_SERVER_FIND_PASSWORD @"member/findPassword" // 找回密码 post
#define WC_SERVER_MODIFY_PASSWORD @"member/modifyPassword" // 修改密码 post

// --------------------拨号模块----------------------

#define WC_SERVER_CALLBACK @"callback/index"        // 回拨 post

// --------------------余额模块----------------------

#define WC_SERVER_RECHARGE @"member/recharge"       // 卡密充值
#define WC_SERVER_TRADENO_URL @"http://weiku.feixiang.hk/?m=restful&c=waps&a=order&"    // 生成订单号
#define WC_SERVER_TRADE_NOTIFY @"http://weiku.feixiang.hk/?m=restful&c=waps&a=receive"  // 支付成功后通知服务器地址

// --------------------静态变量----------------------

#define WC_STATIC_PAGE_ZFSM @"http://weiku.feixiang.hk/page-3.html"     // 资费说明页面
#define WC_STATIC_PAGE_HELP @"http://weiku.feixiang.hk/page-4.html"     // 帮助中心页面
#define WC_STATIC_PAGE_ABOUT @"http://weiku.feixiang.hk/page-2.html"    // 关于我们页面
#define WC_STATIC_PAGE_SITE @"http://feixiang.hk/"                      // 访问主页页面
#define WC_STATIC_CONTACT_US @"10086"                                   // 联系我们电话
#define WC_STATIC_APPID      @"587767923"                               // APP评分APPID

/**
 *    全局设置的一些值，如密码最大最小长度
 */



/**
 *    Keys
 */

#define USER_MODEL_USERDEFAULT @"userModel" // 用户信息
#define USER_NAME_KEY @"userName"            // 用户名,也就是手机号码
#define USER_HUANXIN_UUID_KEY @"hxUUID"          // 环信UUID
#define KEY_KEYCHAIN_SERVICE_ACCOUNT @"account.com.yue" // 用户密码，保存在keychain中
#define CALL_TYPE_SETTTING @"callTypeSetting"       // 保存用户设置的拨打类型，如直拨回拨
#define CALL_SHOW_YOURPHONENUM @"callSHowYourPhoneNum"  // 设置是否显示自己的号码
#define CALL_HISTORY @"Call_History"                    // 通话历史记录
#define CALL_HISTORY_USERNAME @"Call_History_UserName"  // 哪个用户的通话记录
#define CALL_HISROTY_DATA @"Call_History_Data"          // 通话记录用户数据
#define RECORD_HISTORY @"Record_History"                // 录音记录
#define RECORD_HISTORY_USERNAME @"Record_History_UserName"  // 哪个用户的录音记录
#define RECORD_HISTORY_DATA @"Record_History_Data"      // 录音记录用户数据


/**
 *    通知
 */

#define NOTIFY_CALL_PHONE @"Notify_Call_Phone"
#define NOTIFY_LOGIN_SUCCESS @"Notify_Login_Success"
#define NOTIFY_CONTACT_MODIFY @"Notify_Contact_Modify"

/**
 *    第三方组件
 */

#define THIRD_PARTY_UMENG_APPID @"54afdda0fd98c553690003c9"    //  友盟APPID

/**
 *    自定义类型，比如拨号类型
 */

typedef enum{DirectCall=0,BackCall} wc_call_type;

#endif
