//
//  WCDirectCallingViewController.m
//  WeCall
//
//  Created by Vic on 14-12-13.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCDirectCallingViewController.h"
#import "HHSIPUtil.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "WCCallHistoryHeader.h"
#import "WCRecordHistoryHeader.h"
#import <pjsua-lib/pjsua.h>

#define DAIL_OFFSET 28

@interface WCDirectCallingViewController ()
@property (weak, nonatomic) IBOutlet UILabel *calledPhoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (weak, nonatomic) IBOutlet UIView *keypadControlView;
@property (weak, nonatomic) IBOutlet UIButton *acceptBtn;
@property (weak, nonatomic) IBOutlet UIButton *rejectBtn;
@property (weak, nonatomic) IBOutlet UIButton *hungupBtn;
@property (weak, nonatomic) IBOutlet UIButton *loudSpeakerBtn;
@property (weak, nonatomic) IBOutlet UIButton *muteBtn;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *holdBtn;
@property (weak, nonatomic) IBOutlet UIView *dailNumView;
@property (weak, nonatomic) IBOutlet UIButton *hideDailNumBtn;
@property (weak, nonatomic) IBOutlet UILabel *dailNumeLabel;

@property (strong,nonatomic) HHSIPUtil *sipUtil;
@property (nonatomic,strong) AVAudioPlayer *player;

@property (nonatomic) BOOL isConnected; // 是否接通
@property (nonatomic) BOOL isHungup;    // 是否主动挂断
@property (nonatomic) BOOL isRecoring;  // 是否正在录音
@property (nonatomic) BOOL isLoudSpeaker;   // 扬声器是否打开
@property (nonatomic) BOOL isMute;          // 静音是否打开

@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) NSUInteger callSeconds;   // 通话时长，单位秒
@property (nonatomic,strong) NSString *recordDate;  // 录音时间，时间戳
@property (nonatomic,strong) NSString *recordName;  // 录音文件名，格式：自己号码-被叫号码-时间.wav



- (IBAction)mute:(id)sender;
- (IBAction)showDail:(id)sender;
- (IBAction)loudspeaker:(id)sender;
- (IBAction)stayCall:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)callup:(id)sender;
- (IBAction)accept:(id)sender;
- (IBAction)reject:(id)sender;
- (IBAction)hideDailNum:(id)sender;
- (IBAction)dailNumberBtnClicked:(id)sender;

@end

@implementation WCDirectCallingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - 监听通话状态通知

- (void)viewWillAppear:(BOOL)animated
{
    // 监听通话状态
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(callStateCallBack2:) name:@"zmt_call_event" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"zmt_call_event" object:nil];
}

-(void)callStateCallBack:(NSNotification *)noti
{
    zmt_call_event_e callStatus = [[noti object]integerValue];
    NSLog(@"------------zmt_call_event_e:%d",callStatus);
    
    // 响铃
    if(callStatus == ZMT_CALLEVENT_RING){
        dispatch_async(dispatch_get_main_queue(), ^{
            _callStatusLabel.text = @"响铃中";
        });
        
    }
    // 拨通，开始计时
    else if(callStatus == ZMT_CALLEVENT_CONNECTED){
        dispatch_async(dispatch_get_main_queue(), ^{
            _isConnected = YES;
            [self stopPlayWaitingAlert];
            [self startTimer];
            
        });
        
    }
    // 挂断
    else if(callStatus == ZMT_CALLEVENT_HUNGUP){
        dispatch_async(dispatch_get_main_queue(), ^{
            _callStatusLabel.text = @"通话结束";
            [_sipUtil hungupSIP2];
            [self stopPlayWaitingAlert];
            
            if (_isConnected) {
                [self stopTimer];
            }
            [self saveCallStatusHistory];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        });
        
    }
    // 失败
    else if(callStatus == ZMT_CALLEVENT_FAILED){
        dispatch_async(dispatch_get_main_queue(), ^{
            _callStatusLabel.text = @"呼叫失败";
            [self savePhoneHistory:@"呼叫失败"];
            [_sipUtil hungupSIP2];
            [self stopPlayWaitingAlert];
            [self dismissViewControllerAnimated:YES completion:nil];
        });
        
    }
    
}

-(void)callStateCallBack2:(NSNotification *)noti
{
    
    pjsip_inv_state callStatus = [[noti object]integerValue];
    NSLog(@"------------zmt_call_event_e:%d",callStatus);
    
    /*
    // 响铃
    if(callStatus == PJSIP_INV_STATE_CONNECTING){
        dispatch_async(dispatch_get_main_queue(), ^{
            _callStatusLabel.text = @"响铃中";
        });
        
    }
     */
    
    // 拨通，开始计时
    if(callStatus == PJSIP_INV_STATE_CONFIRMED){
        dispatch_async(dispatch_get_main_queue(), ^{
            _isConnected = YES;
            [self stopPlayWaitingAlert];
            [self startTimer];
            
        });
        
    }
    // 挂断
    else if(callStatus == PJSIP_INV_STATE_DISCONNECTED){
        dispatch_async(dispatch_get_main_queue(), ^{
            _callStatusLabel.text = @"通话结束";
            [_sipUtil hungupSIP2];
            [self stopPlayWaitingAlert];
            
            if (_isConnected) {
                [self stopTimer];
            }
            [self saveCallStatusHistory];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        });
        
    }
    // 失败
    /*
    else if(callStatus == PJSIP_INV_STATE_DISCONNECTED){
        dispatch_async(dispatch_get_main_queue(), ^{
            _callStatusLabel.text = @"呼叫失败";
            [self savePhoneHistory:@"呼叫失败"];
            [_sipUtil hungupSIP];
            [self stopPlayWaitingAlert];
            [self dismissViewControllerAnimated:YES completion:nil];
        });
        
    }
     */
    
}


#pragma mark - 初始化

-(void)setup
{
    [self roundView];
    [self setupDailPadNumBtn];
    
    // 初始化通话声音
    pjsua_conf_adjust_rx_level(0, 1);
    pjsua_conf_adjust_tx_level(0, 1);
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    _sipUtil = [HHSIPUtil sharedInstance];
    
    _callSeconds = 0;
    
    _calledPhoneLabel.text = (_calledUserContact == nil) ? _calledPhoneNumber : _calledUserContact[@"name"];
    
    // 呼出电话
    if (_isCallOut) {
        _acceptBtn.hidden = YES;
        _rejectBtn.hidden = YES;
        _hungupBtn.hidden = NO;
        [self sipCall];
    }
    
    // 呼入电话
    else{
        _callStatusLabel.text = @"呼入来电";
        _acceptBtn.hidden = NO;
        _rejectBtn.hidden = NO;
        _hungupBtn.hidden = YES;
        _keypadControlView.hidden = YES;
        [self playWaitingAlert];
    }
}

-(void)roundView
{
    _hungupBtn.layer.cornerRadius = 37.0;
    _hungupBtn.layer.borderWidth = 0.0f;
    _hungupBtn.layer.masksToBounds = YES;
    _acceptBtn.layer.cornerRadius = 37.0;
    _acceptBtn.layer.borderWidth = 0.0f;
    _acceptBtn.layer.masksToBounds = YES;
    _rejectBtn.layer.cornerRadius = 37.0;
    _rejectBtn.layer.borderWidth = 0.0f;
    _rejectBtn.layer.masksToBounds = YES;
    
    for(UIView *subView in _keypadControlView.subviews){
        if([subView isKindOfClass:[UIButton class]]){
            UIButton *keypadBtn = (UIButton *)subView;
            keypadBtn.layer.cornerRadius = 37.0;
            keypadBtn.layer.borderWidth = 1.0f;
            keypadBtn.layer.borderColor = [UIColor whiteColor].CGColor;
            keypadBtn.layer.masksToBounds = YES;
        }
    }

}

-(void)setupDailPadNumBtn
{
    for(UIView *dailSubView in _dailNumView.subviews){
        if([dailSubView isKindOfClass:[UIButton class]]){
            UIButton *dailSubBtn = (UIButton *)dailSubView;
            CGRect oneSizeRECT = dailSubBtn.frame;
            CGRect doubleSizeRect = CGRectMake(oneSizeRECT.origin.x * 2, oneSizeRECT.origin.y * 2, oneSizeRECT.size.width * 2, oneSizeRECT.size.height * 2);
            UIImage *normalDailPadImage = [self imageFromImage:[UIImage imageNamed:@"keypaddtmf"] inRect:doubleSizeRect];
            UIImage *selectedDailPadImage = [self imageFromImage:[UIImage imageNamed:@"keypaddtmf_pressed"] inRect:doubleSizeRect];
            [dailSubBtn setBackgroundImage:normalDailPadImage forState:UIControlStateNormal];
            [dailSubBtn setBackgroundImage:selectedDailPadImage forState:UIControlStateHighlighted];
        }
    }
    
    
}


- (UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect {
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    return newImage;
}

#pragma mark - 计时和停止计时

-(void)startTimer
{
    if(self.timer!=nil)
    {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startCallTimer) userInfo:nil repeats:YES];
}

-(void)stopTimer
{
    if(self.timer!=nil)
    {
        [self.timer invalidate];
        self.timer = nil;
    }
}

-(void)startCallTimer
{
    _callSeconds = _callSeconds + 1;
    NSUInteger callMins = _callSeconds / 60;
    NSUInteger callSecs = _callSeconds % 60;
    NSString *callMinsString = (callMins < 10) ? [NSString stringWithFormat:@"0%d",callMins] : [NSString stringWithFormat:@"%d",callMins];
    NSString *callSecsString = (callSecs < 10) ? [NSString stringWithFormat:@"0%d",callSecs] : [NSString stringWithFormat:@"%d",callSecs];
    NSString *callTimeString = [NSString stringWithFormat:@"%@:%@",callMinsString,callSecsString];
    _callStatusLabel.text = callTimeString;

}

#pragma mark - 播放和停止播放铃声

// 播放等待对方接听铃声
-(void)playWaitingAlert
{
    if (!_isCallOut) {
//    if (YES) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource: _isCallOut ?  @"CallDailling" : @"ringback"  ofType: _isCallOut ?  @"mp3" : @"wav"]] error:nil];
        _player.numberOfLoops = 1;
        [_player play];
    }
}

// 停止播放等待接听铃声
-(void)stopPlayWaitingAlert
{
    if ([_player isPlaying]) {
        [_player stop];
    }
//    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];

}

#pragma mark - SIP呼叫方法

-(void)sipCall
{
    
    if([_sipUtil callSIP2:[NSString stringWithFormat:@"%@",_calledPhoneNumber]]){
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        _callStatusLabel.text = (_calledUserContact == nil) ? @"呼叫中..." : [NSString stringWithFormat:@"呼叫 %@...",_calledUserContact[@"label"]];
        [self playWaitingAlert];
    }
    else{
        _callStatusLabel.text = @"呼叫失败";
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
            
        });
    }
}

#pragma mark - 交互动作

- (IBAction)mute:(id)sender {
//    [_sipUtil adjust_mic_level:0];
    
    if(_muteBtn.tag == 11){
        _isMute = YES;
        _muteBtn.tag = 22;
        [_muteBtn setImage:[UIImage imageNamed:@"mute_dark"] forState:UIControlStateNormal];
        [_muteBtn setBackgroundColor:[UIColor whiteColor]];

        pjsua_conf_adjust_rx_level (0,0);
        pjsua_conf_adjust_tx_level (0,1);
        
        /*
        if(_isLoudSpeaker){
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
//            [[AVAudioSession sharedInstance] setActive:YES error: nil];
        }
        else{
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];

//            [[AVAudioSession sharedInstance] setActive:YES error: nil];

        }
         */
    }
    else if (_muteBtn.tag == 22){
        _muteBtn.tag = 11;
        _isMute = NO;
        [_muteBtn setImage:[UIImage imageNamed:@"mute"] forState:UIControlStateNormal];
        [_muteBtn setBackgroundColor:[UIColor clearColor]];

        pjsua_conf_adjust_rx_level (0,1);
        pjsua_conf_adjust_tx_level (0,1);
        
        /*
        if(_loudSpeakerBtn.tag == 11){
            [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
//            [[AVAudioSession sharedInstance] setActive:YES error: nil];
        }
        else if (_loudSpeakerBtn.tag == 22){
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
//            [[AVAudioSession sharedInstance] setActive:YES error: nil];

        }
         */
    }

}

- (IBAction)showDail:(id)sender {
    _keypadControlView.hidden = YES;
    _dailNumView.hidden = NO;
    _hideDailNumBtn.hidden = NO;
    
    _calledPhoneLabel.frame = CGRectOffset(_calledPhoneLabel.frame, 0, -DAIL_OFFSET);
    _callStatusLabel.frame = CGRectOffset(_callStatusLabel.frame, 0, -DAIL_OFFSET);
}


// 开启或关闭扬声器
- (IBAction)loudspeaker:(id)sender {
    if(_loudSpeakerBtn.tag == 11){
        _isLoudSpeaker = YES;
        _loudSpeakerBtn.tag = 22;
        [_loudSpeakerBtn setImage:[UIImage imageNamed:@"speaker_dark"] forState:UIControlStateNormal];
        [_loudSpeakerBtn setBackgroundColor:[UIColor whiteColor]];
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];

        /*
        if(_isMute){
            [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
//            [[AVAudioSession sharedInstance] setActive:YES error: nil];
        }
        else{
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
//            [[AVAudioSession sharedInstance] setActive:YES error: nil];

        }
         */
    }
    else if (_loudSpeakerBtn.tag == 22){
        _isLoudSpeaker = NO;
        _loudSpeakerBtn.tag = 11;
        [_loudSpeakerBtn setImage:[UIImage imageNamed:@"speaker"] forState:UIControlStateNormal];
        [_loudSpeakerBtn setBackgroundColor:[UIColor clearColor]];

        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];

        /*
        if(_isMute){
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
//            [[AVAudioSession sharedInstance] setActive:YES error: nil];
        }
        else{
            [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
//            [[AVAudioSession sharedInstance] setActive:YES error: nil];

        }
         */
    }

}

- (IBAction)stayCall:(id)sender {
    if(_holdBtn.tag == 11){
        _holdBtn.tag = 22;
        [_holdBtn setImage:[UIImage imageNamed:@"hold_dark"] forState:UIControlStateNormal];
        [_holdBtn setBackgroundColor:[UIColor whiteColor]];
        [_sipUtil holdCall];
    }
    else if (_holdBtn.tag == 22){
        _holdBtn.tag = 11;
        [_holdBtn setImage:[UIImage imageNamed:@"hold"] forState:UIControlStateNormal];
        [_holdBtn setBackgroundColor:[UIColor clearColor]];
        [_sipUtil unholdCall];
    }
    
    

}

- (IBAction)record:(id)sender {
    if(_recordBtn.tag == 11){
        _recordBtn.tag = 22;
        _isRecoring = YES;
        [self startRecord];
        [_recordBtn setImage:[UIImage imageNamed:@"stoprecord"] forState:UIControlStateNormal];
        [_recordBtn setBackgroundColor:[UIColor whiteColor]];

    }
    else if (_recordBtn.tag == 22){
        _recordBtn.tag = 11;
        _isRecoring = NO;
        [self stopRecord];
        [_recordBtn setImage:[UIImage imageNamed:@"startrecord"] forState:UIControlStateNormal];
        [_recordBtn setBackgroundColor:[UIColor clearColor]];

    }

}

- (IBAction)callup:(id)sender {
    // 如果在录音，先停止录音并保存录音
    if(_isRecoring){
        [self stopRecord];
    }
    [_sipUtil hungupSIP2];
    _isHungup = YES;
    
    _callStatusLabel.text = @"通话即将结束";
    if (_isConnected) {
        [self stopTimer];
    }

}

- (IBAction)accept:(id)sender {
    _acceptBtn.hidden = YES;
    _rejectBtn.hidden = YES;
    _hungupBtn.hidden = NO;
    _keypadControlView.hidden = NO;
    [_sipUtil answerCall2];
}

- (IBAction)reject:(id)sender {
    _acceptBtn.hidden = YES;
    [_sipUtil rejectCall2];
    
    _callStatusLabel.text = @"通话被拒接";
    [self stopPlayWaitingAlert];

}

- (IBAction)hideDailNum:(id)sender {
    _keypadControlView.hidden = NO;
    _calledPhoneLabel.hidden = NO;
    _dailNumView.hidden = YES;
    _hideDailNumBtn.hidden = YES;
    _dailNumeLabel.hidden = YES;
    _dailNumeLabel.text = @"";
    
    _calledPhoneLabel.frame = CGRectOffset(_calledPhoneLabel.frame, 0, DAIL_OFFSET);
    _callStatusLabel.frame = CGRectOffset(_callStatusLabel.frame, 0, DAIL_OFFSET);
}

- (IBAction)dailNumberBtnClicked:(id)sender {
    NSString *btnNumber = [sender titleForState:UIControlStateDisabled];
    _calledPhoneLabel.hidden = YES;
    _dailNumeLabel.hidden = NO;
    _dailNumeLabel.text = [NSString stringWithFormat:@"%@%@",_dailNumeLabel.text,btnNumber];
    
    [_sipUtil daildtmf:btnNumber];
}

#pragma mark - 保存通话记录
-(void)savePhoneHistory:(NSString *)theCallStatus
{
    // 需要保存的通话信息
    NSString *otherPhoneNumber = _calledPhoneNumber;
    NSString *otherName = (_calledUserContact == nil) ? @"未知" : _calledUserContact[@"name"];
    NSString *inOrOut = _isCallOut ? @"out" : @"in";
    NSString *callDate= _callDate;
    NSString *callDetail = theCallStatus;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    NSString *currentName = userInfoDict[USER_NAME_KEY];
    // 先查找是否有通话记录
    if ([userDefaults objectForKey:CALL_HISTORY]) {
        NSArray *allUserCallHistoryArray = [userDefaults objectForKey:CALL_HISTORY];
        // 如果有数据则查找
        if ([allUserCallHistoryArray count] > 0) {
            BOOL isFound = NO;   // 是否找到当前用户通话记录
            for (NSDictionary *allUserCallHistoryDict in allUserCallHistoryArray) {
                NSString *userName = allUserCallHistoryDict[CALL_HISTORY_USERNAME];
                if ([userName isEqualToString:currentName]) {
                    isFound = YES;
                    NSUInteger currentUserIndex = [allUserCallHistoryArray indexOfObject:allUserCallHistoryDict];
                    NSArray *currentUserCallHistoryArray = allUserCallHistoryDict[CALL_HISROTY_DATA];
                    
                    // 如果有数据则查找
                    if ([currentUserCallHistoryArray count] > 0) {
                        BOOL isFoundPhoneNumber = NO;       // 是否找到对方号码
                        for (NSDictionary *allCallHistoryDict in currentUserCallHistoryArray) {
                            NSString *callHistoryOtherPhone = allCallHistoryDict[kCallHistoryOtherPhone];
                            if ([callHistoryOtherPhone isEqualToString:otherPhoneNumber]) {
                                isFoundPhoneNumber = YES;
                                // 找到当前序号，后面要删除
                                NSUInteger index = [currentUserCallHistoryArray indexOfObject:allCallHistoryDict];
                                NSArray *otherPhoneHistoryArray = allCallHistoryDict[kCallHistoryArray];
                                NSMutableArray *otherPhoneHistoryMutableArray = [otherPhoneHistoryArray mutableCopy];
                                // 插入所需数据
                                [otherPhoneHistoryMutableArray addObject:@{kCallHistoryCallInOrOut:inOrOut,kCallHistoryCallDetail:callDetail,kCallHistoryCallDate:callDate}];
                                NSMutableDictionary *myCallHistoryMutableDict = [allCallHistoryDict mutableCopy];
                                [myCallHistoryMutableDict setObject:[NSArray arrayWithArray:otherPhoneHistoryMutableArray] forKey:kCallHistoryArray];
                                NSMutableArray *currentUserCallHistoryMutableArray = [currentUserCallHistoryArray mutableCopy];
                                [currentUserCallHistoryMutableArray removeObjectAtIndex:index];
                                [currentUserCallHistoryMutableArray insertObject:myCallHistoryMutableDict atIndex:0];
                                NSMutableDictionary *allUserCallHistoryMutableDict = [allUserCallHistoryDict mutableCopy];
                                [allUserCallHistoryMutableDict setObject:currentUserCallHistoryMutableArray forKey:CALL_HISROTY_DATA];
                                NSMutableArray *allUserCallHistoryMutableArray = [allUserCallHistoryArray mutableCopy];
                                [allUserCallHistoryMutableArray removeObjectAtIndex:currentUserIndex];
                                [allUserCallHistoryMutableArray insertObject:allUserCallHistoryMutableDict atIndex:0];
                                [userDefaults setObject:allUserCallHistoryMutableArray forKey:CALL_HISTORY];
                                [userDefaults synchronize];
                                break;
                            }
                        }
                        // 没有找到则直接插入
                        if (!isFoundPhoneNumber) {
                            NSDictionary *newSingleCallHistoryDict = @{kCallHistoryOther:otherName,kCallHistoryOtherPhone:otherPhoneNumber,kCallHistoryArray:@[@{kCallHistoryCallInOrOut:inOrOut,kCallHistoryCallDetail:callDetail,kCallHistoryCallDate:callDate}]};
                            NSMutableArray *currentUserCallHistoryMutableArray = [currentUserCallHistoryArray mutableCopy];
                            [currentUserCallHistoryMutableArray insertObject:newSingleCallHistoryDict atIndex:0];
                            NSMutableDictionary *allUserCallHistoryMutableDict = [allUserCallHistoryDict mutableCopy];
                            [allUserCallHistoryMutableDict setObject:currentUserCallHistoryMutableArray forKey:CALL_HISROTY_DATA];
                            NSMutableArray *allUserCallHistoryMutableArray = [allUserCallHistoryArray mutableCopy];
                            [allUserCallHistoryMutableArray removeObjectAtIndex:currentUserIndex];
                            [allUserCallHistoryMutableArray insertObject:allUserCallHistoryMutableDict atIndex:0];
                            [userDefaults setObject:allUserCallHistoryMutableArray forKey:CALL_HISTORY];
                            [userDefaults synchronize];
                        }
                    }
                    // 直接插入
                    else{
                        NSDictionary *newSingleCallHistoryDict = @{kCallHistoryOther:otherName,kCallHistoryOtherPhone:otherPhoneNumber,kCallHistoryArray:@[@{kCallHistoryCallInOrOut:inOrOut,kCallHistoryCallDetail:callDetail,kCallHistoryCallDate:callDate}]};
                        NSMutableArray *currentUserCallHistoryMutableArray = [currentUserCallHistoryArray mutableCopy];
                        [currentUserCallHistoryMutableArray insertObject:newSingleCallHistoryDict atIndex:0];
                        NSMutableDictionary *allUserCallHistoryMutableDict = [allUserCallHistoryDict mutableCopy];
                        [allUserCallHistoryMutableDict setObject:currentUserCallHistoryMutableArray forKey:CALL_HISROTY_DATA];
                        NSMutableArray *allUserCallHistoryMutableArray = [allUserCallHistoryArray mutableCopy];
                        [allUserCallHistoryMutableArray removeObjectAtIndex:currentUserIndex];
                        [allUserCallHistoryMutableArray insertObject:allUserCallHistoryMutableDict atIndex:0];
                        [userDefaults setObject:allUserCallHistoryMutableArray forKey:CALL_HISTORY];
                        [userDefaults synchronize];
                    }
                    break;
                }
            }
            // 如果没有找到则直接插入
            if (!isFound) {
                NSDictionary *newSingleCallHistoryDict = @{CALL_HISTORY_USERNAME:currentName,CALL_HISROTY_DATA:@[@{kCallHistoryOther:otherName,kCallHistoryOtherPhone:otherPhoneNumber,kCallHistoryArray:@[@{kCallHistoryCallInOrOut:inOrOut,kCallHistoryCallDetail:callDetail,kCallHistoryCallDate:callDate}]}]};
                NSMutableArray *allUserCallHistoryMutableArray = [allUserCallHistoryArray mutableCopy];
                [allUserCallHistoryMutableArray insertObject:newSingleCallHistoryDict atIndex:0];
                [userDefaults setObject:allUserCallHistoryMutableArray forKey:CALL_HISTORY];
                [userDefaults synchronize];
            }
        }
        // 没有数据直接插入
        else{
            NSArray *newSingleCallHistoryArray = @[@{CALL_HISTORY_USERNAME:currentName,CALL_HISROTY_DATA:@[@{kCallHistoryOther:otherName,kCallHistoryOtherPhone:otherPhoneNumber,kCallHistoryArray:@[@{kCallHistoryCallInOrOut:inOrOut,kCallHistoryCallDetail:callDetail,kCallHistoryCallDate:callDate}]}]}];
            [userDefaults setObject:newSingleCallHistoryArray forKey:CALL_HISTORY];
            [userDefaults synchronize];

        }
    }
    
    // 没有通话记录则直接插入
    else{
        NSArray *newSingleCallHistoryArray = @[@{CALL_HISTORY_USERNAME:currentName,CALL_HISROTY_DATA:@[@{kCallHistoryOther:otherName,kCallHistoryOtherPhone:otherPhoneNumber,kCallHistoryArray:@[@{kCallHistoryCallInOrOut:inOrOut,kCallHistoryCallDetail:callDetail,kCallHistoryCallDate:callDate}]}]}];
        [userDefaults setObject:newSingleCallHistoryArray forKey:CALL_HISTORY];
        [userDefaults synchronize];
    }
    
}

-(void)saveCallStatusHistory
{
    if (_isCallOut) {
        if (_isConnected) {
            NSUInteger callMins = _callSeconds / 60;
            NSUInteger callSecs = _callSeconds % 60;
            NSString *callTime;
            if (callMins == 0) {
                callTime = [NSString stringWithFormat:@"%d秒",callSecs];
            }
            else if (callSecs == 0){
                callTime = [NSString stringWithFormat:@"%d分",callMins];
            }
            else{
                callTime = [NSString stringWithFormat:@"%d分%d秒",callMins,callSecs];
            }
            [self savePhoneHistory:callTime];
        }
        else{
            if (_isHungup) {
                [self savePhoneHistory:@"已取消"];
            }
            else{
                [self savePhoneHistory:@"未接通"];
            }
        }
    }
    
    else{
        if (_isConnected) {
            NSUInteger callMins = _callSeconds / 60;
            NSUInteger callSecs = _callSeconds % 60;
            NSString *callTime;
            if (callMins == 0) {
                callTime = [NSString stringWithFormat:@"%d秒",callSecs];
            }
            else if (callSecs == 0){
                callTime = [NSString stringWithFormat:@"%d分",callMins];
            }
            else{
                callTime = [NSString stringWithFormat:@"%d分%d秒",callMins,callSecs];
            }
            [self savePhoneHistory:callTime];

        }
        else{
            [self savePhoneHistory:@"未接来电"];
        }
    }
}

#pragma mark - 录音

// 开始录音，将音频保存路径：NSDocumentDirectory/自己号码/被叫号码/时间戳.音频后缀
-(void)startRecord
{
    // 自己号码
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    NSString *callNumber = userInfoDict[USER_NAME_KEY];
    
    // 被叫号码
    NSString *calledNumber = _calledPhoneNumber;
    
    // 当前时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH-mm-ss-SSS"];
    NSString *currentDateString = [formatter stringFromDate:[NSDate date]];
    
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSNumber *timeNumber = [NSNumber numberWithDouble:timeInterval];
    NSString *callDateInterval = [timeNumber stringValue];
    _recordDate = callDateInterval;
    
    NSString *audioName = [NSString stringWithFormat:@"%@_%@_%@.wav",callNumber,calledNumber,currentDateString];
    _recordName = audioName;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs_dir = [paths objectAtIndex:0];
    NSString *recordFolderDir = [docs_dir stringByAppendingPathComponent:@"recordings"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:recordFolderDir]){
        [fileManager createDirectoryAtPath:recordFolderDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *audioLocation = [recordFolderDir stringByAppendingPathComponent:audioName];

    [_sipUtil startRecord2:audioLocation];
    
}

// 结束录音，保存录音信息
-(void)stopRecord
{
    [_sipUtil stopRecord2];
    [self saveRecord];
}

-(void)saveRecord
{
    // 需要保存的通话信息
    NSString *otherPhoneNumber = _calledPhoneNumber;
    NSString *otherName = (_calledUserContact == nil) ? @"未知" : _calledUserContact[@"name"];
    NSString *callDate= _recordDate;
    NSString *recordFileLocation = _recordName;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    NSString *currentName = userInfoDict[USER_NAME_KEY];
    // 先查找是否有通话记录
    if ([userDefaults objectForKey:RECORD_HISTORY]) {
        NSArray *allUserCallHistoryArray = [userDefaults objectForKey:RECORD_HISTORY];
        // 如果有数据则查找
        if ([allUserCallHistoryArray count] > 0) {
            BOOL isFound = NO;   // 是否找到当前用户通话记录
            for (NSDictionary *allUserCallHistoryDict in allUserCallHistoryArray) {
                NSString *userName = allUserCallHistoryDict[RECORD_HISTORY_USERNAME];
                if ([userName isEqualToString:currentName]) {
                    isFound = YES;
                    NSUInteger currentUserIndex = [allUserCallHistoryArray indexOfObject:allUserCallHistoryDict];
                    NSArray *currentUserCallHistoryArray = allUserCallHistoryDict[RECORD_HISTORY_DATA];
                    
                    // 如果有数据则查找
                    if ([currentUserCallHistoryArray count] > 0) {
                        BOOL isFoundPhoneNumber = NO;       // 是否找到对方号码
                        for (NSDictionary *allCallHistoryDict in currentUserCallHistoryArray) {
                            NSString *callHistoryOtherPhone = allCallHistoryDict[kRecordHistoryOtherPhone];
                            if ([callHistoryOtherPhone isEqualToString:otherPhoneNumber]) {
                                isFoundPhoneNumber = YES;
                                // 找到当前序号，后面要删除
                                NSUInteger index = [currentUserCallHistoryArray indexOfObject:allCallHistoryDict];
                                NSArray *otherPhoneHistoryArray = allCallHistoryDict[kRecordHistoryArray];
                                NSMutableArray *otherPhoneHistoryMutableArray = [otherPhoneHistoryArray mutableCopy];
                                // 插入所需数据
                                [otherPhoneHistoryMutableArray insertObject:@{kRecordHistoryRecordDate:callDate,kRecordHistoryRecordFileName:recordFileLocation} atIndex:0];
                                NSMutableDictionary *myCallHistoryMutableDict = [allCallHistoryDict mutableCopy];
                                [myCallHistoryMutableDict setObject:[NSArray arrayWithArray:otherPhoneHistoryMutableArray] forKey:kRecordHistoryArray];
                                NSMutableArray *currentUserCallHistoryMutableArray = [currentUserCallHistoryArray mutableCopy];
                                [currentUserCallHistoryMutableArray removeObjectAtIndex:index];
                                [currentUserCallHistoryMutableArray insertObject:myCallHistoryMutableDict atIndex:0];
                                NSMutableDictionary *allUserCallHistoryMutableDict = [allUserCallHistoryDict mutableCopy];
                                [allUserCallHistoryMutableDict setObject:currentUserCallHistoryMutableArray forKey:RECORD_HISTORY_DATA];
                                NSMutableArray *allUserCallHistoryMutableArray = [allUserCallHistoryArray mutableCopy];
                                [allUserCallHistoryMutableArray removeObjectAtIndex:currentUserIndex];
                                [allUserCallHistoryMutableArray insertObject:allUserCallHistoryMutableDict atIndex:0];
                                [userDefaults setObject:allUserCallHistoryMutableArray forKey:RECORD_HISTORY];
                                [userDefaults synchronize];
                                break;
                            }
                        }
                        // 没有找到则直接插入
                        if (!isFoundPhoneNumber) {
                            NSDictionary *newSingleCallHistoryDict = @{kRecordHistoryOther:otherName,kRecordHistoryOtherPhone:otherPhoneNumber,kRecordHistoryArray:@[@{kRecordHistoryRecordDate:callDate,kRecordHistoryRecordFileName:recordFileLocation}]};
                            NSMutableArray *currentUserCallHistoryMutableArray = [currentUserCallHistoryArray mutableCopy];
                            [currentUserCallHistoryMutableArray insertObject:newSingleCallHistoryDict atIndex:0];
                            NSMutableDictionary *allUserCallHistoryMutableDict = [allUserCallHistoryDict mutableCopy];
                            [allUserCallHistoryMutableDict setObject:currentUserCallHistoryMutableArray forKey:RECORD_HISTORY_DATA];
                            NSMutableArray *allUserCallHistoryMutableArray = [allUserCallHistoryArray mutableCopy];
                            [allUserCallHistoryMutableArray removeObjectAtIndex:currentUserIndex];
                            [allUserCallHistoryMutableArray insertObject:allUserCallHistoryMutableDict atIndex:0];
                            [userDefaults setObject:allUserCallHistoryMutableArray forKey:RECORD_HISTORY];
                            [userDefaults synchronize];
                        }
                    }
                    // 直接插入
                    else{
                        NSDictionary *newSingleCallHistoryDict = @{kRecordHistoryOther:otherName,kRecordHistoryOtherPhone:otherPhoneNumber,kRecordHistoryArray:@[@{kRecordHistoryRecordDate:callDate,kRecordHistoryRecordFileName:recordFileLocation}]};
                        NSMutableArray *currentUserCallHistoryMutableArray = [currentUserCallHistoryArray mutableCopy];
                        [currentUserCallHistoryMutableArray insertObject:newSingleCallHistoryDict atIndex:0];
                        NSMutableDictionary *allUserCallHistoryMutableDict = [allUserCallHistoryDict mutableCopy];
                        [allUserCallHistoryMutableDict setObject:currentUserCallHistoryMutableArray forKey:RECORD_HISTORY_DATA];
                        NSMutableArray *allUserCallHistoryMutableArray = [allUserCallHistoryArray mutableCopy];
                        [allUserCallHistoryMutableArray removeObjectAtIndex:currentUserIndex];
                        [allUserCallHistoryMutableArray insertObject:allUserCallHistoryMutableDict atIndex:0];
                        [userDefaults setObject:allUserCallHistoryMutableArray forKey:RECORD_HISTORY];
                        [userDefaults synchronize];
                    }
                    break;
                }
            }
            // 如果没有找到则直接插入
            if (!isFound) {
                NSDictionary *newSingleCallHistoryDict = @{RECORD_HISTORY_USERNAME:currentName,RECORD_HISTORY_DATA:@[@{kRecordHistoryOther:otherName,kRecordHistoryOtherPhone:otherPhoneNumber,kRecordHistoryArray:@[@{kRecordHistoryRecordDate:callDate,kRecordHistoryRecordFileName:recordFileLocation}]}]};
                NSMutableArray *allUserCallHistoryMutableArray = [allUserCallHistoryArray mutableCopy];
                [allUserCallHistoryMutableArray insertObject:newSingleCallHistoryDict atIndex:0];
                [userDefaults setObject:allUserCallHistoryMutableArray forKey:RECORD_HISTORY];
                [userDefaults synchronize];
            }
        }
        // 没有数据直接插入
        else{
            NSArray *newSingleCallHistoryArray = @[@{RECORD_HISTORY_USERNAME:currentName,RECORD_HISTORY_DATA:@[@{kRecordHistoryOther:otherName,kRecordHistoryOtherPhone:otherPhoneNumber,kRecordHistoryArray:@[@{kRecordHistoryRecordDate:callDate,kRecordHistoryRecordFileName:recordFileLocation}]}]}];
            [userDefaults setObject:newSingleCallHistoryArray forKey:RECORD_HISTORY];
            [userDefaults synchronize];
            
        }
    }
    
    // 没有通话记录则直接插入
    else{
        NSArray *newSingleCallHistoryArray = @[@{RECORD_HISTORY_USERNAME:currentName,RECORD_HISTORY_DATA:@[@{kRecordHistoryOther:otherName,kRecordHistoryOtherPhone:otherPhoneNumber,kRecordHistoryArray:@[@{kRecordHistoryRecordDate:callDate,kRecordHistoryRecordFileName:recordFileLocation}]}]}];
        [userDefaults setObject:newSingleCallHistoryArray forKey:RECORD_HISTORY];
        [userDefaults synchronize];
    }
    
    NSArray *addedArray = [userDefaults objectForKey:RECORD_HISTORY];
    NSLog(@"%@",addedArray);

}

@end
