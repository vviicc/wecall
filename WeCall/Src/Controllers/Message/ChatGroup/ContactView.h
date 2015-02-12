//
//  ContactView.h
//  ChatDemo-UI2.0
//
//  Created by dhcdht on 14-11-11.
//  Copyright (c) 2014年 dhcdht. All rights reserved.
//

#import "EMRemarkImageView.h"

@interface ContactView : EMRemarkImageView
{
    UIButton *_deleteButton;
}

@property (copy) void (^deleteContact)(NSInteger index);

@end
