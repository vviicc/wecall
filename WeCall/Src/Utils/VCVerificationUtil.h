//
//  VCVerification.h
//  YUE
//
//  Created by Vic on 14-8-12.
//  Copyright (c) 2014年 vic. All rights reserved.
//

/**
 *    各种验证通用类，如验证手机号码等
 */

#import <Foundation/Foundation.h>

@interface VCVerificationUtil : NSObject


/**
 *    检查手机号码是否合法
 *
 *    @param number 手机号码
 *
 *    @return 合法返回YES，非法返回NO
 */

+ (BOOL)isAValidPhoneNum:(NSString *)number;

/**
 *    检查密码是否合法
 *
 *    @param password        密码
 *    @param confirmPassword 确定密码
 *    @param minLength       密码最小长度
 *    @param maxLength       密码最大长度
 *
 *    @return key为"result"和"message"的dictionary,密码合法result值为YES，message值为OK，密码非法result值为NO，message值为错误消息
 */

+ (NSDictionary *)isAValidPassword:(NSString *)password
               withConfirmPassword:(NSString *)confirmPassword
                            minLen:(NSUInteger)minLength
                            maxLen:(NSUInteger)maxLength;

@end
