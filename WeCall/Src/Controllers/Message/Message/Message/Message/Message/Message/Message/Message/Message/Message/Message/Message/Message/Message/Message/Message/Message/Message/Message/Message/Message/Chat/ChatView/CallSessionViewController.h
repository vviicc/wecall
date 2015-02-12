//
//  CallSessionViewController.h
//  ChatDemo-UI2.0
//
//  Created by dhcdht on 14-10-29.
//  Copyright (c) 2014年 dhcdht. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    CallNone = 0,
    CallOut,
    CallIn,
}CallType;

@interface CallSessionViewController : UIViewController

- (instancetype)initCallOutWithChatter:(NSString *)chatter;
- (instancetype)initCallInWithSession:(EMCallSession *)callSession;

@end
