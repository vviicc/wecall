//
//  VCVerification.m
//  YUE
//
//  Created by Vic on 14-8-12.
//  Copyright (c) 2014年 vic. All rights reserved.
//

#import "VCVerificationUtil.h"

@implementation VCVerificationUtil

+ (BOOL)isAValidPhoneNum:(NSString *)number
{
	if ([number length] == 0) {
		return NO;
	}
	
	NSString *regex = @"^((13[0-9])|(170)|(17[6-8])|(15[^4,\\D])|(18[0-9]))\\d{8}$";
	
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	
	BOOL isMatch = [pred evaluateWithObject:number];
	
	if (!isMatch) {
		return NO;
	}
	
	return YES;
}

+ (NSDictionary *)isAValidPassword:(NSString *)password
               withConfirmPassword:(NSString *)confirmPassword
                            minLen:(NSUInteger)minLength
                            maxLen:(NSUInteger)maxLength
{
    BOOL lenPassword = (minLength <= [password length] &&  [password length] <= maxLength) ? YES : NO;
    BOOL lenConfirmPassword = (minLength <= [confirmPassword length] &&  [confirmPassword length] <= maxLength) ? YES : NO;
    BOOL samePassword = ([password isEqualToString:confirmPassword]) ? YES :NO;
    
    NSString *lenErrorMessage = NSLocalizedString(@"lenPasswordError", nil);
    NSString *sameErrorMessage = NSLocalizedString(@"samePasswordError", nil);
    
    NSString *message;
    NSDictionary *resultDict;
    
    if ((!lenPassword) || (!lenConfirmPassword)) {
        message = lenErrorMessage;
        resultDict = @{@"result": @NO,@"message":message};
    }
    else if (!samePassword){
        message = sameErrorMessage;
        resultDict = @{@"result": @NO,@"message":message};
    }
    else{
        resultDict = @{@"result": @YES,@"message":@"OK"};
    }
    
    return resultDict;
}

@end
