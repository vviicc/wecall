//
//  VCPinyin.h
//  YUE
//
//  Created by Vic on 14-8-20.
//  Copyright (c) 2014年 vic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VCPinyin : NSObject

/**
 *    将汉字转为第一个首字母
 *
 *    @param hanzi 汉字
 *
 *    @return 第一个首字母
 */
char pinyinFirstLetter(unsigned short hanzi);

@end
