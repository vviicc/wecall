//
//  VCNetworkingUtil.m
//  YUE
//
//  Created by Vic on 14-8-16.
//  Copyright (c) 2014年 vic. All rights reserved.
//

#import "VCNetworkingUtil.h"

@implementation VCNetworkingUtil

+(AFHTTPRequestOperationManager *)httpManager
{
    NSURL *baseURL = [NSURL URLWithString:WC_SERVER_BASERUL];
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc]initWithBaseURL:baseURL];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain",@"text/html", nil];
    return manager;
}

+(AFHTTPRequestOperationManager *)voipManager
{
    NSURL *baseURL = [NSURL URLWithString:@""];
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc]initWithBaseURL:baseURL];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain",@"text/html", nil];
    
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    securityPolicy.allowInvalidCertificates = YES;
    manager.securityPolicy = securityPolicy;
    return manager;

}

+(NSString *)parseDicToJson:(NSDictionary *) dic
{
    NSError *error;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    NSString * json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return json;
}

+(NSDictionary *)parseDataToDict:(id)object
{
    NSData *data = (NSData *)object;
    NSDictionary *responseDict;
    NSError *error;
    if (data != nil) {
        responseDict = [NSJSONSerialization JSONObjectWithData:data
                                                       options:NSJSONReadingMutableContainers
                                                         error:&error];
    }
    return responseDict;
}


@end
