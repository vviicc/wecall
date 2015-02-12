

#import <Foundation/Foundation.h>
#import <UIKit/UIkit.h>
#import "WanpuOrderObj.h"


#define WANPU_PAY_SDK_VERSION_NUMBER            @"2.1.0p"

enum WanpuPayConnectionType {
    WANPU_CONNECT_TYPE_PAY_CONNECT = 0,
    WANPU_CONNECT_TYPE_ALIPAY = 1,
    WANPU_CONNECT_TYPE_PHONEPAY = 2,
    WANPU_CONNECT_TYPE_CHECK_PHONEPAY = 3,
    WANPU_CONNECT_TYPE_UNIONPAY = 4
};

@interface WanpuConnect : NSObject{


    
@private
    NSString *appID_;
    NSString *userID_;
    NSMutableData *data_;
    int connectAttempts_;
    BOOL isInitialConnect_;
    int responseCode_;
    NSURLConnection *connectConnection_;
    NSURLConnection *payConnection_;
    NSURLConnection *phonePayConnection_;
    NSURLConnection *checkPhonePayConnection_;
    
    NSURLConnection *RunningNumberConnection_;
//    NSURLConnection *comfirmPayConnection_;
//    NSURLConnection *checkPayInfoConnection_;
    NSString *appChannel_;
    NSString *appCount_;
    NSString *appleID_;

    WanpuOrderObj *wanpuOrderObj_;
    

}

@property(nonatomic, copy) NSString *appID;
@property(nonatomic, copy) NSString *appChannel;
@property(nonatomic, copy) NSString *userID;
@property(nonatomic, copy) NSMutableDictionary *configItems;
@property(nonatomic, copy) NSString *appCount;
@property(nonatomic, copy) NSString *appleID;
@property(nonatomic, copy) WanpuOrderObj *wanpuOrderObj;
@property(assign) BOOL isInitialConnect;




+ (WanpuConnect *)getConnect:(NSString *)appID;

+ (WanpuConnect *)getConnect:(NSString *)appID pid:(NSString *)appChannel;

+ (void)singleTaskApplication:(UIApplication *)application options:(NSDictionary *)launchOptions;

- (NSString *)generateTradeNO;

- (NSString *)getAppScheme;

+ (void)payCenter:(UIViewController *)viewController WanpuOrderObj:(WanpuOrderObj *) wanpuPayOrder;

+ (WanpuConnect *)payForAliPay:(WanpuOrderObj *)wanpuPayObj;
+ (WanpuConnect *)payForUnion:(UIViewController *)viewController WanpuOrderObj:(WanpuOrderObj *)wanpuPayObj;

+ (WanpuConnect *)payForPhonePay:(WanpuOrderObj *)obj Amount:(NSString *)amount CardNum:(NSString *)card_num CardPass:(NSString *)card_pass;

+ (WanpuConnect *)checkForPhonePay:(WanpuOrderObj *)obj Amount:(NSString *)amount CardNum:(NSString *)card_num CardPass:(NSString *)card_pass;

+ (WanpuConnect *)payForPhonePay:(UIViewController *)viewController WanpuOrderObj:(WanpuOrderObj *)obj;

+ (WanpuConnect *)sharedWanpuPayConnect;

+ (void)deviceNotificationReceived;

+ (NSString *)getAppID;

+ (NSMutableDictionary *)getConfigItems;

- (void)connectWithType:(int)connectionType withParams:(NSDictionary *)params;

- (NSString *)getURLStringWithConnectionType:(int)connectionType;

- (void)initiateConnectionWithConnectionType:(int)connectionType requestString:(NSString *)requestString;

- (BOOL)isJailBroken;

+ (NSString *)isJailBrokenStr;

- (NSMutableDictionary *)genericParameters;

- (NSString *)createQueryStringFromDict:(NSDictionary *)paramDict;

+ (NSString *)createQueryStringFromDict:(NSDictionary *)paramDict;

- (NSString *)createQueryStringFromString:(NSString *)string;

+ (NSString *)createQueryStringFromString:(NSString *)string;

- (NSString *)createQueryStringFromStringDecode:(NSString *)string;

+ (NSString *)createQueryStringFromStringDecode:(NSString *)string;

+ (void)clearCache;

+ (NSString *)getOpenID;

+ (NSString *)getIDFA;

+ (NSString *)getIDFV;

+ (NSString *)getMACAddress;

+ (NSString *)getMACID;

+ (NSString *)getSHA1MacAddress;

+ (NSString *)getUniqueIdentifier;

+ (NSString *)getTimeStamp;

+ (id)parseURL:(NSURL *)url application:(UIApplication *)application;

@end

#import "WanpuConnectConstants.h"