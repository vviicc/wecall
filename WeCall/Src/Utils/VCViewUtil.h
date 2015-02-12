//
//  VCViewUtil.h
//  YUE
//
//  Created by Vic on 14-8-14.
//  Copyright (c) 2014年 vic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VCViewUtil : NSObject

/**
 *    弹出Alert提醒
 *
 *    @param message message
 *    @param title   title
 */

+ (void)showAlertMessage:(NSString *)message andTitle:(NSString *)title;

@end
