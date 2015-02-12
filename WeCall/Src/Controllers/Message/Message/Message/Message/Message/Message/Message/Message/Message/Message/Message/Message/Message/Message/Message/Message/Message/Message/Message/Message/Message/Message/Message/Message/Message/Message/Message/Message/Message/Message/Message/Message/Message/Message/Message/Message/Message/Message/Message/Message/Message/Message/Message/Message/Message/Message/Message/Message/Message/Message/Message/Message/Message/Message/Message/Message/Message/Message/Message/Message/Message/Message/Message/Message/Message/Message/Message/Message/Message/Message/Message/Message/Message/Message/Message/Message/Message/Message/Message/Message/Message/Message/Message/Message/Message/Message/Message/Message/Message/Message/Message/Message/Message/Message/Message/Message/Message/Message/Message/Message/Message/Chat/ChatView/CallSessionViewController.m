//
//  CallSessionViewController.m
//  ChatDemo-UI2.0
//
//  Created by dhcdht on 14-10-29.
//  Copyright (c) 2014年 dhcdht. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "CallSessionViewController.h"

#define kAlertViewTag_Close 1000

@interface CallSessionViewController ()<UIAlertViewDelegate, ICallManagerDelegate>
{
    NSString *_chatter;
    NSUInteger _callLength;
    
    int _callType;
    UIImageView *_bgImageView;
    UILabel *_statusLabel;
    UIImageView *_headerImageView;
    UILabel *_nameLabel;
    
    UIButton *_silenceButton;
    UILabel *_silenceLabel;
    UIButton *_speakerOutButton;
    UILabel *_outLabel;
    UIButton *_hangupButton;
    UIButton *_answerButton;
    
    AVAudioPlayer *_player;
}

@property (strong, nonatomic) EMCallSession *callSession;

@end

@implementation CallSessionViewController

@synthesize callSession = _callSession;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _callType = CallNone;
        _callSession = nil;
        _callLength = 0;
        
        [[EMSDKFull sharedInstance].callManager addDelegate:self delegateQueue:nil];
    }
    return self;
}

- (instancetype)initCallOutWithChatter:(NSString *)chatter
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        _callType = CallOut;
        _chatter = chatter;
    }
    
    return self;
}

- (instancetype)initCallInWithSession:(EMCallSession *)callSession
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        _callType = CallIn;
        _callSession = callSession;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (_callType == CallOut) {
        [self _callOutWithChatter:_chatter];
    }
    [self _setupSubviews];
    [self _beginRing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
//    [[EMSDKFull sharedInstance].callManager removeDelegate:self];
}

#pragma mark - private

- (void)_layouSubviews
{
    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    
    _bgImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _bgImageView.contentMode = UIViewContentModeScaleToFill;
    _bgImageView.image = [UIImage imageNamed:@"callBg.png"];
    [self.view addSubview:_bgImageView];
    
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 80)];
    _statusLabel.font = [UIFont systemFontOfSize:15.0];
    _statusLabel.backgroundColor = [UIColor clearColor];
    _statusLabel.textColor = [UIColor whiteColor];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_statusLabel];
    
    _headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 50) / 2, CGRectGetMaxY(_statusLabel.frame) + 20, 50, 50)];
    _headerImageView.image = [UIImage imageNamed:@"chatListCellHead"];
    [self.view addSubview:_headerImageView];
    
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_headerImageView.frame) + 5, self.view.frame.size.width, 20)];
    _nameLabel.font = [UIFont systemFontOfSize:14.0];
    _nameLabel.backgroundColor = [UIColor clearColor];
    _nameLabel.textColor = [UIColor whiteColor];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_nameLabel];
    
    CGFloat tmpWidth = self.view.frame.size.width / 2;
    _silenceButton = [[UIButton alloc] initWithFrame:CGRectMake((tmpWidth - 40) / 2, self.view.frame.size.height - 230, 40, 40)];
    [_silenceButton setImage:[UIImage imageNamed:@"call_silence"] forState:UIControlStateNormal];
    [_silenceButton setImage:[UIImage imageNamed:@"call_silence_h"] forState:UIControlStateSelected];
    [_silenceButton addTarget:self action:@selector(silenceAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_silenceButton];
    
    _silenceLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_silenceButton.frame), CGRectGetMaxY(_silenceButton.frame) + 5, 40, 20)];
    _silenceLabel.backgroundColor = [UIColor clearColor];
    _silenceLabel.textColor = [UIColor whiteColor];
    _silenceLabel.font = [UIFont systemFontOfSize:13.0];
    _silenceLabel.textAlignment = NSTextAlignmentCenter;
    _silenceLabel.text = @"静音";
    [self.view addSubview:_silenceLabel];
    
    _speakerOutButton = [[UIButton alloc] initWithFrame:CGRectMake(tmpWidth + (tmpWidth - 40) / 2, self.view.frame.size.height - 230, 40, 40)];
    [_speakerOutButton setImage:[UIImage imageNamed:@"call_out"] forState:UIControlStateNormal];
    [_speakerOutButton setImage:[UIImage imageNamed:@"call_out_h"] forState:UIControlStateSelected];
    [_speakerOutButton addTarget:self action:@selector(speakerOutAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_speakerOutButton];
    
    _outLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_speakerOutButton.frame), CGRectGetMaxY(_speakerOutButton.frame) + 5, 40, 20)];
    _outLabel.backgroundColor = [UIColor clearColor];
    _outLabel.textColor = [UIColor whiteColor];
    _outLabel.font = [UIFont systemFontOfSize:13.0];
    _outLabel.textAlignment = NSTextAlignmentCenter;
    _outLabel.text = @"免提";
    [self.view addSubview:_outLabel];
    
    _hangupButton = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 200) / 2, self.view.frame.size.height - 120, 200, 40)];
    [_hangupButton setTitle:@"挂断" forState:UIControlStateNormal];
    [_hangupButton setBackgroundColor:[UIColor colorWithRed:191 / 255.0 green:48 / 255.0 blue:49 / 255.0 alpha:1.0]];;
    [_hangupButton addTarget:self action:@selector(hangupAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_hangupButton];
    
    _answerButton = [[UIButton alloc] initWithFrame:CGRectMake(tmpWidth + (tmpWidth - 100) / 2, self.view.frame.size.height - 120, 100, 40)];
    [_answerButton setTitle:@"接听" forState:UIControlStateNormal];
    [_answerButton setBackgroundColor:[UIColor colorWithRed:191 / 255.0 green:48 / 255.0 blue:49 / 255.0 alpha:1.0]];;
    [_answerButton addTarget:self action:@selector(answerAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)_setupSubviews
{
    [self _layouSubviews];
    
    if (_callType == CallIn) {
        _statusLabel.text = @"等待接听...";
        _nameLabel.text = _chatter;
        
        CGFloat tmpWidth = self.view.frame.size.width / 2;
        _hangupButton.frame = CGRectMake((tmpWidth - 100) / 2, self.view.frame.size.height - 120, 100, 40);
        [self.view addSubview:_answerButton];
        _silenceButton.hidden = YES;
        _silenceLabel.hidden = YES;
        _speakerOutButton.hidden = YES;
        _outLabel.hidden = YES;
    }
    else if (_callType == CallOut)
    {
        _statusLabel.text = @"正在建立连接...";
        _nameLabel.text = _chatter;
        
        [_answerButton removeFromSuperview];
        _hangupButton.frame = CGRectMake((self.view.frame.size.width - 200) / 2, self.view.frame.size.height - 120, 200, 40);
        _silenceButton.hidden = NO;
        _silenceLabel.hidden = NO;
        _speakerOutButton.hidden = NO;
        _outLabel.hidden = NO;
    }
    
    
    if (_callSession) {
//        _statusLabel.text = @"通话进行中...";
//        _nameLabel.text = _chatter;
//        
//        [_answerButton removeFromSuperview];
//        _hangupButton.frame = CGRectMake((self.view.frame.size.width - 200) / 2, self.view.frame.size.height - 120, 200, 40);
//        _silenceButton.hidden = NO;
//        _silenceLabel.hidden = NO;
//        _speakerOutButton.hidden = NO;
//        _outLabel.hidden = NO;
    }
}

- (void)_callOutWithChatter:(NSString *)chatter
{
    EMError *error = nil;
    _callSession = [[EMSDKFull sharedInstance].callManager asyncCallAudioWithChatter:chatter timeout:50 error:&error];
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"错误" message:error.description delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        alertView.tag = kAlertViewTag_Close;
        [alertView show];
    }
}

- (void)_close
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"callControllerClose" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_insertMessageWithStr:(NSString *)str
{
    EMChatText *chatText = [[EMChatText alloc] initWithText:str];
    EMTextMessageBody *textBody = [[EMTextMessageBody alloc] initWithChatObject:chatText];
    EMMessage *message = [[EMMessage alloc] initWithReceiver:_callSession.conversationChatter bodies:@[textBody]];
    message.isRead = YES;
    [[EaseMob sharedInstance].chatManager insertMessageToDB:message append2Chat:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"insertCallMessage" object:message];
}

- (void)_beginRing
{
    [_player stop];
    
    NSString *musicPath = [[NSBundle mainBundle] pathForResource:@"callRing" ofType:@"mp3"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:musicPath];
    
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [_player setVolume:1];
    _player.numberOfLoops = -1; //设置音乐播放次数  -1为一直循环
    if([_player prepareToPlay])
    {
        [_player play]; //播放
    }
}

- (void)_stopRing
{
    [_player stop];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kAlertViewTag_Close)
    {
        [self _close];
    }
}

#pragma mark - ICallManagerDelegate

- (void)callSessionStatusChanged:(EMCallSession *)callSession changeReason:(EMCallStatusChangedReason)reason error:(EMError *)error
{
    if (_callSession && ![callSession.sessionId isEqualToString:_callSession.sessionId] && callSession.status == eCallSessionStatusRinging)
    {
        [self showHint:@"有新的语音请求，当前正在通话中，已自动拒绝"];
        
        [self _insertMessageWithStr:@"语音通话已取消"];
        
        return;
    }
    
    if ([_callSession.sessionId isEqualToString:callSession.sessionId])
    {
        UIAlertView *alertView = nil;
        if (error) {
            [self _stopRing];
            [self _insertMessageWithStr:@"语音通话失败"];
            
            _statusLabel.text = @"连接失败";
            alertView = [[UIAlertView alloc] initWithTitle:@"错误" message:error.description delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            alertView.tag = kAlertViewTag_Close;
            [alertView show];
        }
        else{
            if (callSession.status == eCallSessionStatusDisconnected) {
                [self _stopRing];
                NSString *str = @"语音通话结束";
                if(_callLength == 0)
                {
                    if (_callType == CallIn) {
                        str = reason == eCallReason_Reject ? @"拒接语音通话" : @"对方取消语音通话";
                    }
                    else{
                        str = reason == eCallReason_Hangup ? @"取消语音通话" : @"对方拒接语音通话";
                    }
                }
                [self _insertMessageWithStr:str];
                
                _statusLabel.text = @"通话已挂断";
                [_answerButton removeFromSuperview];
                [_hangupButton removeFromSuperview];
                [self _close];
            }
            else if (callSession.status == eCallSessionStatusAccepted)
            {
                [self _stopRing];
                _statusLabel.text = @"可以通话了...";
                //开始计时,测试数据
                _callLength = 1;
                
                if(_callType == CallIn)
                {
                    [_answerButton removeFromSuperview];
                    _hangupButton.frame = CGRectMake((self.view.frame.size.width - 200) / 2, self.view.frame.size.height - 120, 200, 40);
                    _silenceButton.hidden = NO;
                    _silenceLabel.hidden = NO;
                    _speakerOutButton.hidden = NO;
                    _outLabel.hidden = NO;
                }
            }
        }
    }
}

#pragma mark - action

- (void)silenceAction:(id)sender
{
    _silenceButton.selected = !_silenceButton.selected;
}

- (void)speakerOutAction:(id)sender
{
    _speakerOutButton.selected = !_speakerOutButton.selected;
}

- (void)hangupAction:(id)sender
{
    [self _stopRing];
    
    EMCallStatusChangedReason reason = eCallReason_Hangup;
    if(_callLength == 0)
    {
        reason = _callType == CallIn ? eCallReason_Reject : eCallReason_Hangup;
    }
    
    [[EMSDKFull sharedInstance].callManager asyncTerminateCallSessionWithId:_callSession.sessionId reason:reason];
    
    [self _close];
}

- (void)answerAction:(id)sender
{
    [self _stopRing];
    
    [[EMSDKFull sharedInstance].callManager asyncAcceptCallSessionWithId:_callSession.sessionId];
}

@end
