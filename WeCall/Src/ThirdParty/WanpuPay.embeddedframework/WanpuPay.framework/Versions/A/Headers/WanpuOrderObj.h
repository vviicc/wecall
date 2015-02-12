@class UIImage;

@interface WanpuOrderObj : NSObject
{
    NSString *_wanpuOrderID;
    NSString *_goodsName;
    NSString *_goodsOrderID;
    NSString *_customUserID;
    NSString *_goodsPrice;
    NSString *_goodsInfo;
    UIImage *_goodsImage;
    NSString *_payNotifyURL;
    int _payType;
    int _payResult;
    int _payStatusCode;
    NSString *_payStatusMessage;

}

@property(nonatomic, copy) NSString *wanpuOrderID;    //玩铺订单号
@property(nonatomic, copy) NSString *goodsName;       //物品名称
@property(nonatomic, copy) NSString *goodsOrderID;    //物品订单号
@property(nonatomic, copy) NSString *customUserID;    //应用的用户ID
@property(nonatomic, copy) NSString *goodsPrice;      //物品价格
@property(nonatomic, copy) NSString *goodsInfo;       //物品信息
@property(nonatomic, copy) UIImage *goodsImage;       //物品图片
@property(nonatomic, copy) NSString *payNotifyURL;    //反响通知地址
@property(nonatomic) int payType;                     //支付类型 2:支付宝 3:充值卡
@property(nonatomic) int payResult;                   //支付结果 0:初始 1:支付成功  2:未支付
@property(nonatomic) int payStatusCode;                  //支付结果代码 每个支付渠道会有不同
@property(nonatomic, copy) NSString *payStatusMessage;   //支付结果说明

@end
