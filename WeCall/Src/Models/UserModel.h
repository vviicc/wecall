//
//  RegisterUser.h
//  WeCall
//
//  Created by Vic on 14-12-10.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserModel : NSObject

@property (strong,nonatomic) NSString *phoneNumber;
@property (strong,nonatomic) NSString *verficationCode;
@property (strong,nonatomic) NSString *password;
@property (strong,nonatomic) NSString *hxUUID;

@end
