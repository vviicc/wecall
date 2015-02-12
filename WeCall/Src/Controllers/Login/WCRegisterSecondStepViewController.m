//
//  WCRegisterSecondStepViewController.m
//  WeCall
//
//  Created by Vic on 14-12-10.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCRegisterSecondStepViewController.h"
#import "WCRegisterThirdStepViewController.h"

#define SEGUE_REGISTER_SECOND_THIRD_STEP @"Register Second 2 Third Step"

@interface WCRegisterSecondStepViewController ()
@property (weak, nonatomic) IBOutlet UITextField *smscodeTextField;
- (IBAction)nextStep:(id)sender;

@end

@implementation WCRegisterSecondStepViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)nextStep:(id)sender {
    NSString *inputCode = _smscodeTextField.text;
    if ([inputCode isEqualToString:_myUser.verficationCode]) {
        [self performSegueWithIdentifier:SEGUE_REGISTER_SECOND_THIRD_STEP sender:self];
    }
    else{
        [VCViewUtil showAlertMessage:@"验证码不正确" andTitle:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:SEGUE_REGISTER_SECOND_THIRD_STEP]){
        WCRegisterThirdStepViewController *thirdStep = segue.destinationViewController;
        thirdStep.myUser = _myUser;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

@end
