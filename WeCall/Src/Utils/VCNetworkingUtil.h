//
//  VCNetworkingUtil.h
//  YUE
//
//  Created by Vic on 14-8-16.
//  Copyright (c) 2014年 vic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface VCNetworkingUtil : NSObject

/**
 *    网络请求manager
 *
 *    @return 网络请求manager
 */
+(AFHTTPRequestOperationManager *)httpManager;

/**
 *    封装云号通后台请求
 *
 *    @return 云号通网络请求manager
 */
+(AFHTTPRequestOperationManager *)voipManager;


/**
 *    将字典类型数据解析成字符类型
 *
 *    @param dic 要传入的字典类型数据
 *
 *    @return 解析成的字符类型
 */
+(NSString *)parseDicToJson:(NSDictionary *)dic;

/**
 *    如果responseObject为NSData类型，将其转成NSDictionary类型
 *
 *    @param object responseObject
 *
 *    @return 字典类型数据
 */
+(NSDictionary *)parseDataToDict:(id)object;

@end
