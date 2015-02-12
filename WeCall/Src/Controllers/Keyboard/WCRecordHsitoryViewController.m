//
//  WCRecordHsitoryViewController.m
//  WeCall
//
//  Created by Vic on 15-1-2.
//  Copyright (c) 2015年 feixiang. All rights reserved.
//

#import "WCRecordHsitoryViewController.h"
#import "WCRecordHistoryTableViewCell.h"
#import "WCRecordHistoryHeader.h"
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>


@interface WCRecordHsitoryViewController ()<AVAudioPlayerDelegate,UITableViewDataSource,UITableViewDelegate,MFMailComposeViewControllerDelegate,UIAlertViewDelegate>
- (IBAction)playRecord:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *playStatusLabel;
@property (weak, nonatomic) IBOutlet UISlider *controlSlider;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UITableView *recordTableView;
- (IBAction)downloadRecord:(id)sender;
- (IBAction)emailRecord:(id)sender;
- (IBAction)deleteRecord:(id)sender;

@property (nonatomic, strong) AVAudioPlayer* audioPlayer;
@property (nonatomic, strong) NSTimer* audioTimer;
@property (nonatomic,strong) NSString *selectedAudioLocation;   // 选中的录音文件路径
@property (nonatomic) BOOL isPlaying;
@property (nonatomic,strong) NSIndexPath *selectedIndexPath;

@end

@implementation WCRecordHsitoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopTimer];
}

#pragma mark- 初始化

-(void)setup
{
    self.navigationItem.title = _name;
    [self setupPlayer];
}

-(void)setupPlayer
{
    NSDictionary *lastestRecordHistoryDict = [_recordHistoryArray firstObject];
    NSString *recordFileName = lastestRecordHistoryDict[kRecordHistoryRecordFileName];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs_dir = [paths objectAtIndex:0];
    NSString *recordFolderDir = [docs_dir stringByAppendingPathComponent:@"recordings"];
    NSString *recordFileLoacton = [recordFolderDir stringByAppendingPathComponent:recordFileName];
    _selectedAudioLocation = recordFileLoacton;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:recordFileLoacton]){
        NSURL *fileURL = [NSURL fileURLWithPath:recordFileLoacton];
        _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:fileURL error:nil];
        _audioPlayer.delegate = self;
        [_audioPlayer prepareToPlay];
        _controlSlider.minimumValue = 0.0f;
        _controlSlider.maximumValue = _audioPlayer.duration;
        [self updateDisplay];

    }
}

#pragma mark - 更新视图

// 更新时间显示和进度条
- (void)updateDisplay
{
    NSTimeInterval currentTime = _audioPlayer.currentTime;
    NSTimeInterval audioLength = _audioPlayer.duration;
    int currentTimeInt = (int)floor(currentTime);
    int audioLengthInt = (int)floor(audioLength);
    NSString *currentTimeString = [self transformSeconds:currentTimeInt];
    NSString *audioLengthString = [self transformSeconds:audioLengthInt];
    _playStatusLabel.text = [NSString stringWithFormat:@"%@/%@",currentTimeString,audioLengthString];
    
    _controlSlider.value = currentTime;
}


// 将秒数转为00:05这种形式
-(NSString *)transformSeconds:(int)seconds
{
    NSUInteger callMins = seconds / 60;
    NSUInteger callSecs = seconds % 60;
    NSString *callMinsString = (callMins < 10) ? [NSString stringWithFormat:@"0%d",callMins] : [NSString stringWithFormat:@"%d",callMins];
    NSString *callSecsString = (callSecs < 10) ? [NSString stringWithFormat:@"0%d",callSecs] : [NSString stringWithFormat:@"%d",callSecs];
    NSString *callTimeString = [NSString stringWithFormat:@"%@:%@",callMinsString,callSecsString];
    return callTimeString;
}

#pragma mark - 委托方法

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 60.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_recordHistoryArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *recordHistoryCellIdentifier = @"Record History Cell";
    WCRecordHistoryTableViewCell *recordHistoryCell = [tableView dequeueReusableCellWithIdentifier:recordHistoryCellIdentifier forIndexPath:indexPath];
    if (recordHistoryCell == nil) {
        recordHistoryCell = [[WCRecordHistoryTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:recordHistoryCellIdentifier];
    }
    
    NSDictionary *lastestRecordHistoryDict = _recordHistoryArray[indexPath.row];
    NSString *recordDateIntervalString = lastestRecordHistoryDict[kRecordHistoryRecordDate];
    NSTimeInterval recordDateInterval = [recordDateIntervalString doubleValue];
    NSDate *recordedDate = [NSDate dateWithTimeIntervalSince1970:recordDateInterval];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSString *recordedDateString = [formatter stringFromDate:recordedDate];
    
    NSString *recordFileName = lastestRecordHistoryDict[kRecordHistoryRecordFileName];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs_dir = [paths objectAtIndex:0];
    NSString *recordFolderDir = [docs_dir stringByAppendingPathComponent:@"recordings"];
    NSString *recordFileLoacton = [recordFolderDir stringByAppendingPathComponent:recordFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *recordAudioLength = nil;
    if([fileManager fileExistsAtPath:recordFileLoacton]){
        NSURL *fileURL = [NSURL fileURLWithPath:recordFileLoacton];
        AVURLAsset *urlAsset = [[AVURLAsset alloc]initWithURL:fileURL options:nil];
        CMTime audioDuration = urlAsset.duration;
        float audioDurationSecondsFloat = CMTimeGetSeconds(audioDuration);
        int audioSeconds = (int)floor(audioDurationSecondsFloat);
        recordAudioLength = [NSString stringWithFormat:@"%d 秒",audioSeconds];
    }
    
    recordHistoryCell.phoneLabel.text = _phone;
    recordHistoryCell.callLengthLabel.text = recordAudioLength;
    recordHistoryCell.dateLabel.text = recordedDateString;
    return recordHistoryCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *lastestRecordHistoryDict = _recordHistoryArray[indexPath.row];
    
    NSString *recordFileName = lastestRecordHistoryDict[kRecordHistoryRecordFileName];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs_dir = [paths objectAtIndex:0];
    NSString *recordFolderDir = [docs_dir stringByAppendingPathComponent:@"recordings"];
    NSString *recordFileLoacton = [recordFolderDir stringByAppendingPathComponent:recordFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:recordFileLoacton]){
        NSURL *fileURL = [NSURL fileURLWithPath:recordFileLoacton];
        _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:fileURL error:nil];
        _audioPlayer.delegate = self;
        _controlSlider.minimumValue = 0.0f;
        _controlSlider.maximumValue = _audioPlayer.duration;
        [self updateDisplay];
        _playBtn.tag = 11;
        [self playRecord:nil];
    }
}

#pragma mark - 交互操作

- (IBAction)playRecord:(id)sender {
    // 播放
    if (_playBtn.tag == 11 && _audioPlayer!= nil) {
        _isPlaying = YES;
        _playBtn.tag = 22;
        [_playBtn setImage:[UIImage imageNamed:@"pause_button"] forState:UIControlStateNormal];
        [_audioPlayer play];
        _audioTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
        
    }
    // 暂停
    else if (_playBtn.tag == 22){
        _isPlaying = NO;
        _playBtn.tag = 11;
        [_playBtn setImage:[UIImage imageNamed:@"play_button"] forState:UIControlStateNormal];

        [_audioPlayer pause];
        [self stopTimer];
        [self updateDisplay];

    }
    
}

- (IBAction)sliderValueChanged:(id)sender {
    if(self.audioTimer)
        [self stopTimer];
    
    [_audioPlayer stop];
    _audioPlayer.currentTime = _controlSlider.value;
    [self updateDisplay];
    
    if (_isPlaying) {
        [_audioPlayer play];
        self.audioTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    }
}



#pragma mark - Timer
- (void)timerFired:(NSTimer*)timer
{
    [self updateDisplay];
}

- (void)stopTimer
{
    if ([_audioTimer isValid]) {
        [self.audioTimer invalidate];
        self.audioTimer = nil;
    }
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self stopTimer];
    [_playBtn setImage:[UIImage imageNamed:@"play_button"] forState:UIControlStateNormal];
    [self updateDisplay];
    _playBtn.tag = 11;
    _isPlaying = NO;
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    [self stopTimer];
    [_playBtn setImage:[UIImage imageNamed:@"play_button"] forState:UIControlStateNormal];
    [self updateDisplay];
    _playBtn.tag = 11;
    _isPlaying = NO;

}

#pragma mark - 交互界面

- (IBAction)downloadRecord:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"使用iTunes下载" message:@"1.连接您的设备到电脑，打开iTunes，找到您的设备并选择它。点击上方的'应用'菜单。2.找到'文件共享'部分下方的'应用',选择WeChat,在有方找到'recordings'目录，点下方的'保存到'按钮将目录保存到您的电脑。3.在您的电脑里打开'recordings'目录，在此目录下能找到录音文件" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
    [alert show];
}

- (IBAction)emailRecord:(id)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:_recordTableView];
    NSIndexPath *indexPath = [_recordTableView indexPathForRowAtPoint:buttonPosition];
    NSDictionary *lastestRecordHistoryDict = _recordHistoryArray[indexPath.row];
    
    NSString *recordFileName = lastestRecordHistoryDict[kRecordHistoryRecordFileName];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs_dir = [paths objectAtIndex:0];
    NSString *recordFolderDir = [docs_dir stringByAppendingPathComponent:@"recordings"];
    NSString *recordFileLoacton = [recordFolderDir stringByAppendingPathComponent:recordFileName];
    
    
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        
        mailer.mailComposeDelegate = self;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:recordFileLoacton]){
            NSData *recData = [NSData dataWithContentsOfFile:recordFileLoacton];
            [mailer addAttachmentData:recData mimeType:@"audio/wav" fileName:recordFileName];
            
        }
        
        [self presentViewController:mailer animated:YES completion:nil];
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"邮件功能未开启"
                                                        message:@"您当前的邮件服务处于未开启状态，请先前往系统设置中配置邮件服务后，再进行分享 "
                                                       delegate:nil
                                              cancelButtonTitle:@"好"
                                              otherButtonTitles: nil];
        [alert show];
    }

}

- (IBAction)deleteRecord:(id)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:_recordTableView];
    NSIndexPath *indexPath = [_recordTableView indexPathForRowAtPoint:buttonPosition];
    _selectedIndexPath = indexPath;
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"确认" message:@"您确认要删除此录音文件吗?" delegate:self cancelButtonTitle:@"不" otherButtonTitles:@"是的", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.cancelButtonIndex != buttonIndex){
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
                                if ([callHistoryOtherPhone isEqualToString:_phone]) {
                                    isFoundPhoneNumber = YES;
                                    // 找到当前序号，后面要删除
                                    NSUInteger index = [currentUserCallHistoryArray indexOfObject:allCallHistoryDict];
                                    NSArray *otherPhoneHistoryArray = allCallHistoryDict[kRecordHistoryArray];
                                    NSMutableArray *otherPhoneHistoryMutableArray = [otherPhoneHistoryArray mutableCopy];
                                    // 删除当前行
                                    [otherPhoneHistoryMutableArray removeObjectAtIndex:_selectedIndexPath.row];
                                    NSMutableDictionary *myCallHistoryMutableDict = [allCallHistoryDict mutableCopy];
                                    [myCallHistoryMutableDict setObject:[NSArray arrayWithArray:otherPhoneHistoryMutableArray] forKey:kRecordHistoryArray];
                                    NSMutableArray *currentUserCallHistoryMutableArray = [currentUserCallHistoryArray mutableCopy];

                                    [currentUserCallHistoryMutableArray replaceObjectAtIndex:index withObject:myCallHistoryMutableDict];
                                    NSMutableDictionary *allUserCallHistoryMutableDict = [allUserCallHistoryDict mutableCopy];
                                    [allUserCallHistoryMutableDict setObject:currentUserCallHistoryMutableArray forKey:RECORD_HISTORY_DATA];
                                    NSMutableArray *allUserCallHistoryMutableArray = [allUserCallHistoryArray mutableCopy];
                                    [allUserCallHistoryMutableArray replaceObjectAtIndex:currentUserIndex withObject:allUserCallHistoryMutableDict];
                                    [userDefaults setObject:allUserCallHistoryMutableArray forKey:RECORD_HISTORY];
                                    [userDefaults synchronize];
                                    break;
                                }
                            }
                        }
                        break;
                    }
                }
            }
        }
        
        NSArray *addedArray = [userDefaults objectForKey:RECORD_HISTORY];
        NSLog(@"%@",addedArray);
        
        // 删除本地保存录音
        NSDictionary *lastestRecordHistoryDict = _recordHistoryArray[_selectedIndexPath.row];
        NSString *recordFileName = lastestRecordHistoryDict[kRecordHistoryRecordFileName];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docs_dir = [paths objectAtIndex:0];
        NSString *recordFolderDir = [docs_dir stringByAppendingPathComponent:@"recordings"];
        NSString *recordFileLoacton = [recordFolderDir stringByAppendingPathComponent:recordFileName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:recordFileLoacton]){
            [fileManager removeItemAtPath:recordFileLoacton error:nil];
        }
        
        [_recordHistoryArray removeObjectAtIndex:_selectedIndexPath.row];
        [_recordTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:_selectedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [_audioPlayer stop];
        _audioPlayer.currentTime = 0.0;
        _audioPlayer = nil;
        _isPlaying = NO;
        _playBtn.tag = 22;
        [self playRecord:self];
    }
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
