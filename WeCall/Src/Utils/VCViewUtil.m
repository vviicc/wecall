//
//  VCViewUtil.m
//  YUE
//
//  Created by Vic on 14-8-14.
//  Copyright (c) 2014年 vic. All rights reserved.
//

#import "VCViewUtil.h"


@implementation VCViewUtil

+ (void)showAlertMessage:(NSString *)message andTitle:(NSString *)title {
	UIAlertView *alertDialog = [[UIAlertView alloc] initWithTitle:title
                                                          message:message
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                otherButtonTitles:nil
                                ];
	[alertDialog show];
}

@end
