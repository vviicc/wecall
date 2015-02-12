//
//  HHSIPUtil.h
//  huihaiIOS
//
//  Created by Vic on 14-9-20.
//  Copyright (c) 2014年 huihai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "zmt_type.h"



@interface HHSIPUtil : NSObject
{
    NSString *sipServerIp;
    int sipServerPort;
    NSString *sipNumber;
    NSString *sipPassword;
    int sipRegisterTimeout;
}

// 单例
+(HHSIPUtil *)sharedInstance;

-(BOOL)registerSIP;
-(BOOL)registerSIP2;

-(BOOL)callSIP:(NSString *)calledPhoneNumber;
-(BOOL)callSIP2:(NSString *)calledPhoneNumber;

-(void)hungupSIP;
-(void)hungupSIP2;

-(void)rejectCall;
-(void)rejectCall2;

-(void)answerCall;
-(void)answerCall2;


// 删除账号
-(void)deleteAccount;
-(void)deleteAccount2; 


// 开始录音
-(void)startRecord:(NSString *)filePath;
-(void)startRecord2:(NSString *)filePath;


// 停止录音
-(void)stopRecord;
-(void)stopRecord2;


// 播放录音
-(void)startPlayFile:(NSString *)filePath;

// 停止播放录音
-(void)stopPlayFile;

// 保持通话
-(void)holdCall;

// 释放保持通话
-(void)unholdCall;

-(void)daildtmf:(NSString *)dailNum;


@end
