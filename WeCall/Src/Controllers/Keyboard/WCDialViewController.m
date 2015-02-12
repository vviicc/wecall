//
//  WCDialViewController.m
//  WeCall
//
//  Created by Vic on 14-12-12.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCDialViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "WCDirectCallingViewController.h"
#import <SSKeychain/SSKeychain.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "HHSIPUtil.h"
#import <APAddressBook/APAddressBook.h>
#import <APAddressBook/APContact.h>
#import <APAddressBook/APPhoneWithLabel.h>
#import "WCPhoneContactDetailViewController.h"
#import "WCCallHistoryHeader.h"
#import "WCRecordHistoryHeader.h"
#import "WCCallAndRecordHistoryTableViewCell.h"
#import "WCCallHistoryViewController.h"
#import "WCRecordHsitoryViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "AppDelegate.h"

#define SEGUE_DAIL_DIRECT_CALLING @"Dail 2 DirectCalling"
#define SEGUE_DAIL_LOGIN @"Dail 2 Login"
#define K_APCONTACT @"apcontact"
#define K_PHONE @"phone"

@interface WCDialViewController ()<UITableViewDataSource,UITableViewDelegate,UITabBarControllerDelegate,ABNewPersonViewControllerDelegate,ABPeoplePickerNavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *displayLabel;
@property (weak, nonatomic) IBOutlet UITableView *searchTableView;
@property (weak, nonatomic) IBOutlet UIButton *addToContactBtn;
@property (weak, nonatomic) IBOutlet UIView *dailNumView;
@property (weak, nonatomic) IBOutlet UIButton *delDailNumBtn;
@property (weak, nonatomic) IBOutlet UITableView *callAndRecordHistoryTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *callAndRecordSegmentedControl;
@property (weak, nonatomic) IBOutlet UIView *dailView;
@property (weak, nonatomic) IBOutlet UIScrollView *dailAndCallBtnScrollView;
- (IBAction)selectFromContact:(id)sender;

@property (strong,nonatomic) APAddressBook *addressBook;
@property (strong,nonatomic) NSArray *contactsArray;
@property (strong,nonatomic) NSMutableArray *filteredContactArray;
@property (strong,nonatomic) NSMutableArray *callHistoryMutableArray;
@property (strong,nonatomic) NSMutableArray *recordHistoryMutableArray;
@property (strong,nonatomic) APContact *selectedContact;
@property (nonatomic) BOOL isInputEmpty;            // 输入是否为空
@property (nonatomic) BOOL isRecordHistoryTapped;     // 用于保存点击了通话记录还是录音记录
@property (nonatomic) BOOL showDailItem;    // 是否拨号界面
@property (nonatomic) NSUInteger selectedTabbar;    // 保存点击的tabbar

- (IBAction)addContact:(id)sender;
- (IBAction)numberButtonClicked:(id)sender;
- (IBAction)delNumber:(id)sender;
- (IBAction)call:(id)sender;
- (IBAction)callAndRecordValueChange:(id)sender;
@end

@implementation WCDialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [self loadContact];
    [self loadCallHistory];
    [self performSelector:@selector(setupLogin) withObject:nil afterDelay:0.0];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(callPhoneNotify:) name:NOTIFY_CALL_PHONE object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loginSuccessNotify:) name:NOTIFY_LOGIN_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(contactModifyNotify:) name:NOTIFY_CONTACT_MODIFY object:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!_showDailItem) {
        [self loadCallAndRecordHistoryFromLocal];
        [_callAndRecordHistoryTableView reloadData];
    }

}



#pragma mark - 拨号通知

-(void)callPhoneNotify:(NSNotification *)noti
{
    NSString *notifyPhoneNumber = [noti object];
    [self showDailAndHideHistoryView:YES];
    _displayLabel.text = notifyPhoneNumber;
    [self searchContact:notifyPhoneNumber];
    
    _selectedTabbar = 0;

    
}

#pragma mark -登录成功通知
-(void)loginSuccessNotify:(NSNotification *)noti
{
    [self loadContact];
    [self loadCallHistory];
    if(self.tabBarController.selectedIndex != 0){
        [self.tabBarController setSelectedIndex:0];
    }
}

#pragma mark -联系人变动通知
-(void)contactModifyNotify:(NSNotification *)noti
{
    [self loadContact];
}




#pragma mark - 加载历史记录数据源

- (void)loadCallAndRecordHistoryFromLocal
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    NSString *currentName = userInfoDict[USER_NAME_KEY];
    // 加载通话记录数据
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
                    NSArray *currentUserCallHistoryArray = allUserCallHistoryDict[CALL_HISROTY_DATA];
                    _callHistoryMutableArray = [NSMutableArray arrayWithArray:currentUserCallHistoryArray];
                    break;
                }
            }
            // 如果没有找到则直接插入
            if (!isFound) {
                _callHistoryMutableArray = nil;
            }
        }
        // 没有数据直接插入
        else{
            _callHistoryMutableArray = nil;
        }
    }
    
    // 没有通话记录则直接插入
    else{
        _callHistoryMutableArray = nil;
    }
    
    
    // 加载录音记录数据
    // 先查找是否有录音记录
    if ([userDefaults objectForKey:RECORD_HISTORY]) {
        NSArray *allUserCallHistoryArray = [userDefaults objectForKey:RECORD_HISTORY];
        // 如果有数据则查找
        if ([allUserCallHistoryArray count] > 0) {
            BOOL isFound = NO;   // 是否找到当前用户录音记录
            for (NSDictionary *allUserCallHistoryDict in allUserCallHistoryArray) {
                NSString *userName = allUserCallHistoryDict[RECORD_HISTORY_USERNAME];
                if ([userName isEqualToString:currentName]) {
                    isFound = YES;
                    NSArray *currentUserCallHistoryArray = allUserCallHistoryDict[RECORD_HISTORY_DATA];
                    _recordHistoryMutableArray = [NSMutableArray arrayWithArray:currentUserCallHistoryArray];
                    break;
                }
            }
            // 如果没有找到则直接插入
            if (!isFound) {
                _recordHistoryMutableArray = nil;
            }
        }
        // 没有数据直接插入
        else{
            _recordHistoryMutableArray = nil;
        }
    }
    
    // 没有录音记录则直接插入
    else{
        _recordHistoryMutableArray = nil;
    }
}

#pragma mark - UITabBarController回调方法

- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
    NSUInteger selectedIndex = tabBarController.selectedIndex;
    if(selectedIndex == 0 && _selectedTabbar == 0)
    {
        if (!_showDailItem) {
            [self showDailAndHideHistoryView:YES];
            
        }
        else{
            [self showDailAndHideHistoryView:NO];
        }
    }
    _selectedTabbar = selectedIndex;
}

#pragma mark - 隐藏与显示
-(void)showDailAndHideHistoryView:(BOOL)showDailView
{
    // 显示拨号盘视图
    if (showDailView) {
        _showDailItem = YES;
        _dailView.hidden = NO;
        _callAndRecordHistoryTableView.hidden = YES;
    }
    // 显示历史记录并更新数据源
    else{
        _showDailItem = NO;
        _dailView.hidden = YES;
        _callAndRecordHistoryTableView.hidden = NO;
        [self loadCallAndRecordHistoryFromLocal];
        [_callAndRecordHistoryTableView reloadData];
    }
}

#pragma mark - 初始化
- (void)setup
{
    [self setupDailPadNumBtn];
    self.tabBarController.delegate = self;
    _filteredContactArray = [NSMutableArray array];
    _callHistoryMutableArray = [NSMutableArray array];
    _recordHistoryMutableArray = [NSMutableArray array];
    _isInputEmpty = YES;
    _showDailItem = YES;
    _addressBook = [[APAddressBook alloc]init];
    _addressBook.fieldsMask = APContactFieldFirstName | APContactFieldLastName | APContactFieldCompositeName |
    APContactFieldPhones | APContactFieldPhonesWithLabels | APContactFieldThumbnail;
    _addressBook.filterBlock = ^BOOL(APContact *contact)
    {
        return contact.phones.count > 0 && ((contact.firstName != nil) || (contact.lastName !=nil));
    };
}

-(void)setupDailPadNumBtn
{
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(delNumLongPress:)];
    [_delDailNumBtn addGestureRecognizer:longPressGesture];
    for(UIView *dailSubView in _dailNumView.subviews){
        if([dailSubView isKindOfClass:[UIButton class]]){
            UIButton *dailSubBtn = (UIButton *)dailSubView;
            CGRect oneSizeRECT = dailSubBtn.frame;
            CGRect doubleSizeRect = CGRectMake(oneSizeRECT.origin.x * 2, oneSizeRECT.origin.y * 2, oneSizeRECT.size.width * 2, oneSizeRECT.size.height * 2);
            UIImage *normalDailPadImage = [self imageFromImage:[UIImage imageNamed:@"dialerkeypad-i4"] inRect:doubleSizeRect];
            UIImage *selectedDailPadImage = [self imageFromImage:[UIImage imageNamed:@"dialerkeypadpressed-i4"] inRect:doubleSizeRect];
            [dailSubBtn setImage:normalDailPadImage forState:UIControlStateNormal];
            [dailSubBtn setImage:selectedDailPadImage forState:UIControlStateHighlighted];
            [dailSubBtn setImage:selectedDailPadImage forState:UIControlStateSelected];

        }
    }
    if([UIScreen mainScreen].bounds.size.height <= 480){
        _dailAndCallBtnScrollView.contentSize = CGSizeMake(self.view.frame.size.width, 438.0);
    }

}

- (void)delNumLongPress:(UILongPressGestureRecognizer*)gesture {
    if ( gesture.state == UIGestureRecognizerStateBegan ) {
        _displayLabel.text = @"";
        [self searchContact:_displayLabel.text];
        
    }
}

- (UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect {
    CGImageRef sourceImageRef = [image CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    return newImage;
}

#pragma mark - 加载通讯录
- (void)loadContact
{
    [_addressBook loadContacts:^(NSArray *contacts, NSError *error) {
        if(!error){
            NSArray *soretdArray = [contacts sortedArrayUsingFunction:contactSort context:NULL];
            _contactsArray = [NSArray arrayWithArray:soretdArray];
            [self searchContact:_displayLabel.text];
        }
        else{
            switch([APAddressBook access])
            {
                    //TODO: 下面方法没有调用
                case APAddressBookAccessUnknown:
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [VCViewUtil showAlertMessage:@"请到 系统设置-隐私-通讯录 中开启" andTitle:@"无法访问通讯录"];
                    });
                    break;
                    
                case APAddressBookAccessGranted:
                    break;
                    
                case APAddressBookAccessDenied:
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [VCViewUtil showAlertMessage:@"请到 系统设置-隐私-通讯录 中开启" andTitle:@"无法访问通讯录"];
                    });
                    break;
            }
        }
    }];
}

NSInteger contactSort(id contact1, id contact2, void *context)
{
    NSString *name1 = [NSString stringWithFormat:@"%@%@",
                       [(APContact *)contact1 lastName] ? [(APContact *)contact1 lastName] : @"",
                       [(APContact *)contact1 firstName] ? [(APContact *)contact1 firstName] :@""];
    NSString *name2 = [NSString stringWithFormat:@"%@%@",
                       [(APContact *)contact2 lastName] ? [(APContact *)contact2 lastName] : @"",
                       [(APContact *)contact2 firstName] ? [(APContact *)contact2 firstName] :@""];
    return  [name1 localizedCaseInsensitiveCompare:name2];
}

#pragma mark - 登录
// 自动登录，如果用户之前登录过，则自动执行登录操作，登录成功要登录sip服务器，否则跳转到登录界面
-(void)setupLogin
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    NSString *username = userInfoDict[USER_NAME_KEY];
    NSString *password = [SSKeychain passwordForService:KEY_KEYCHAIN_SERVICE_ACCOUNT account:username];
    
    // 用户登陆过
    if (username && password) {
        [self autoLoginFromServerWithUserName:username andPasswor:password];
    }
    // 用户未登录过
    else{
        [self performSegueWithIdentifier:SEGUE_DAIL_LOGIN sender:self];
    }
}

-(void)autoLoginFromServerWithUserName:(NSString *)username andPasswor:(NSString *)password
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSDictionary *parameters = @{@"username": username,@"password":password};
    AFHTTPRequestOperationManager *manager = [VCNetworkingUtil httpManager];
    [manager POST:WC_SERVER_LOGIN
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              
              NSDictionary *statusDict = [responseObject objectForKey:@"status"];
              
              // 登录失败
              if ([statusDict[@"succeed"] integerValue] == 0) {
                  [hud hide:YES];
                  [self performSegueWithIdentifier:SEGUE_DAIL_LOGIN sender:self];
              }
              
              // 登录成功
              else if([statusDict[@"succeed"] integerValue] == 1){
                  
                  // 登录sip服务器
                  HHSIPUtil *sharedSIPUtil = [HHSIPUtil sharedInstance];
                  /*
                  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                      BOOL result = [sharedSIPUtil registerSIP2];
                      dispatch_async(dispatch_get_main_queue(), ^{
                          if (result) {
                              [hud hide:YES];
                          }
                          else{
                              hud.mode = MBProgressHUDModeText;
                              hud.labelText = @"登录sip服务器失败";
                              [hud hide:YES afterDelay:2];
                          }
                      });
                  });
                   */
                  
                  if ([sharedSIPUtil registerSIP2]) {
                      [hud hide:YES];
                  }
                  else{
                      hud.mode = MBProgressHUDModeText;
                      hud.labelText = @"登录sip服务器失败";
                      [hud hide:YES afterDelay:2];
                  }
                   
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
              hud.mode = MBProgressHUDModeText;
              hud.labelText = @"网络请求失败";
              hud.detailsLabelText = error.localizedDescription;
              [hud hide:YES afterDelay:2];
          }];
}

#pragma mark - 添加联系人

- (IBAction)addContact:(id)sender {
    ABNewPersonViewController *picker = [[ABNewPersonViewController alloc] init];
    picker.newPersonViewDelegate = self;
    
    ABRecordRef aContact = ABPersonCreate();
    CFErrorRef anError = NULL;
    ABMultiValueRef phoneRef = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    bool didAdd = ABMultiValueAddValueAndLabel(phoneRef, (__bridge CFTypeRef)(_displayLabel.text), kABPersonPhoneMobileLabel, NULL);
    
    if (didAdd == YES)
    {
        ABRecordSetValue(aContact, kABPersonPhoneProperty, phoneRef, &anError);
        if (anError == NULL)
        {
            picker.displayedPerson = aContact;
            
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"失败"
                                                            message:@"添加联系人失败"
                                                           delegate:nil 
                                                  cancelButtonTitle:@"好"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
    
    CFRelease(phoneRef);
    CFRelease(aContact);
    
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:picker];
    [self presentViewController:navigation animated:YES completion:nil];
    

}

#pragma mark - 交互操作

- (IBAction)numberButtonClicked:(id)sender {
    NSString *btnNumber = [sender titleForState:UIControlStateDisabled];
    _displayLabel.text = [NSString stringWithFormat:@"%@%@",_displayLabel.text,btnNumber];
    [self searchContact:_displayLabel.text];
}

- (IBAction)delNumber:(id)sender {
    if ([_displayLabel.text length] >= 1) {
        _displayLabel.text = [_displayLabel.text substringToIndex:([_displayLabel.text length] - 1)];
        [self searchContact:_displayLabel.text];
    }
}

- (IBAction)call:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // 使用直拨，跳到直拨通话界面
    if([userDefaults objectForKey:CALL_TYPE_SETTTING] == nil || [[userDefaults objectForKey:CALL_TYPE_SETTTING] integerValue] == DirectCall){
        [self performSegueWithIdentifier:SEGUE_DAIL_DIRECT_CALLING sender:self];
    }
    // 使用回拨，调用回拨方法
    else if ([[userDefaults objectForKey:CALL_TYPE_SETTTING] integerValue] == BackCall){
        [self callbackFromServer];
    }
    
}

- (IBAction)callAndRecordValueChange:(id)sender {
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    // 选中通话记录
    if (segment.selectedSegmentIndex == 0) {
        _isRecordHistoryTapped = NO;
    }
    // 选中录音记录
    else if (segment.selectedSegmentIndex == 1){
        _isRecordHistoryTapped = YES;
    }
    
    [self showDailAndHideHistoryView:NO];

}

#pragma mark - 动态搜索联系人

-(void)searchContact:(NSString *)inputText
{
    // 如果输入为空，则显示历史通话记录
    if ([inputText length] == 0) {
        _isInputEmpty = YES;
        [self loadCallHistory];
    }
    
    // 动态搜索联系人
    else{
        _isInputEmpty = NO;
        [_filteredContactArray removeAllObjects];
        for (APContact *contact in _contactsArray) {
            NSArray *phones = contact.phones;
            for (NSString *phone in phones) {
                NSRange phoneRange = [[self handlePhoneNum:phone] rangeOfString:inputText];
                if (phoneRange.length > 0) {
                    NSDictionary *filteredDict = @{K_APCONTACT:contact,K_PHONE:phone};
                    [_filteredContactArray addObject:filteredDict];
                }
            }
        }
        [_searchTableView reloadData];
    }
}

#pragma mark - 显示历史通话记录

-(void)loadCallHistory
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    NSString *currentName = userInfoDict[USER_NAME_KEY];
    
    if ([userDefaults objectForKey:CALL_HISTORY]) {
        NSArray *allUserCallHistoryArray = [userDefaults objectForKey:CALL_HISTORY];
        if ([allUserCallHistoryArray count] > 0) {
            BOOL isFound = NO;
            for (NSDictionary *allUserCallHistoryDict in allUserCallHistoryArray) {
                NSString *userName = allUserCallHistoryDict[CALL_HISTORY_USERNAME];
                if ([userName isEqualToString:currentName]) {
                    isFound = YES;
                    NSArray *currentUserCallHistoryArray = allUserCallHistoryDict[CALL_HISROTY_DATA];
                    
                    if ([currentUserCallHistoryArray count] > 0) {
                        [_filteredContactArray removeAllObjects];
                        for (NSDictionary *currentUserCallHistoryDict in currentUserCallHistoryArray) {
                            NSString *phone = currentUserCallHistoryDict[kCallHistoryOtherPhone];
                            NSString *contact = currentUserCallHistoryDict[kCallHistoryOther];
                            NSDictionary *filteredDict = @{K_APCONTACT:contact,K_PHONE:phone};
                            [_filteredContactArray addObject:filteredDict];
                        }
                    }
                }
                break;
            }
            
            if (!isFound) {
                [_filteredContactArray removeAllObjects];
            }
        }
        else{
            [_filteredContactArray removeAllObjects];
        }
    }
    else{
        [_filteredContactArray removeAllObjects];
    }
    
    [_searchTableView reloadData];
}

#pragma mark - TableView委托方法

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    // 搜索tableview
    if(tableView.tag == 11){
        return 35.0;
    }
    else{
        return 80.0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // 搜索tableview
    if(tableView.tag == 11){
        // 如果没有相关联系人，则显示添加联系人按钮，否则不显示
        if ([_filteredContactArray count] == 0 && !_isInputEmpty) {
            _searchTableView.hidden = YES;
            _addToContactBtn.hidden = NO;
        }
        else{
            _searchTableView.hidden = NO;
            _addToContactBtn.hidden = YES;
        }
        return [_filteredContactArray count];
    }
    
    // 通话或录音记录
    else{
        // 通话记录
        if(!_isRecordHistoryTapped){
            return [_callHistoryMutableArray count];
        }
        // 录音记录
        else{
            return [_recordHistoryMutableArray count];
        }
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 搜索tableview
    if(tableView.tag == 11){
        static NSString *searchcellInderfier = @"Search Contact Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:searchcellInderfier forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:searchcellInderfier];
        }
        NSDictionary *searchDict = _filteredContactArray[indexPath.row];
        NSString *phone = searchDict[K_PHONE];
        if ([searchDict[K_APCONTACT] isKindOfClass:[APContact class]]) {
            APContact *contact = searchDict[K_APCONTACT];
            NSString *name = contact.compositeName;
            cell.textLabel.text = name;
        }
        else{
            cell.textLabel.text = searchDict[K_APCONTACT];
        }
        cell.detailTextLabel.text = [self handlePhoneNum:phone];
        
        if (_isInputEmpty) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else{
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
        }
        return cell;

    }
    
    // 通话或录音记录tableview
    else{
        static NSString *historyCellIdentifier = @"Call And Record History Cell";
        WCCallAndRecordHistoryTableViewCell *historyCell = [tableView dequeueReusableCellWithIdentifier:historyCellIdentifier forIndexPath:indexPath];
        if(historyCell == nil){
            historyCell = [[WCCallAndRecordHistoryTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:historyCellIdentifier];
        }
        
        // 通话记录
        if(!_isRecordHistoryTapped){
            NSDictionary *callHistoryDict = _callHistoryMutableArray[indexPath.row];
            NSString *otherName = callHistoryDict[kCallHistoryOther];
            NSString *otherPhone = callHistoryDict[kCallHistoryOtherPhone];
            NSArray *otherCallHistoryArray = callHistoryDict[kCallHistoryArray];
            NSDictionary *lastestCallHistoryDict = [otherCallHistoryArray lastObject];
            NSString *inOrOut = [lastestCallHistoryDict[kCallHistoryCallInOrOut] isEqualToString:@"in"] ? @"来电" :@"去电";
            NSString *callStatus = lastestCallHistoryDict[kCallHistoryCallDetail];
            NSString *callDetail = [NSString stringWithFormat:@"%@ - %@",inOrOut,callStatus];
            NSString *callDateIntervalString = lastestCallHistoryDict[kCallHistoryCallDate];
            NSTimeInterval callDateInterval = [callDateIntervalString doubleValue];
            NSDate *calledDate = [NSDate dateWithTimeIntervalSince1970:callDateInterval];
            NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
            [formatter setDateFormat:@"MM/dd yyyy"];
            NSString *calledDateString = [formatter stringFromDate:calledDate];
            
            historyCell.nameLabel.text = otherName;
            historyCell.phoneLabel.text = otherPhone;
            historyCell.detailLabel.text = callDetail;
            historyCell.dateLabel.text = calledDateString;
            //TODO: 来电图标
            historyCell.typeImageView.image = [lastestCallHistoryDict[kCallHistoryCallInOrOut] isEqualToString:@"in"] ? [UIImage imageNamed:@"phonecall_out"] : [UIImage imageNamed:@"phonecall_out"];

            return historyCell;

        }
        else{
            NSDictionary *recordHistoryDict = _recordHistoryMutableArray[indexPath.row];
            NSString *otherName = recordHistoryDict[kRecordHistoryOther];
            NSString *otherPhone = recordHistoryDict[kRecordHistoryOtherPhone];
            NSArray *otherCallHistoryArray = recordHistoryDict[kRecordHistoryArray];
            NSString *recordAudioLength = nil;
            NSString *calledDateString = nil;

            if([otherCallHistoryArray count] > 0){
                NSDictionary *lastestCallHistoryDict = [otherCallHistoryArray firstObject];
                NSString *callDateIntervalString = lastestCallHistoryDict[kRecordHistoryRecordDate];
                NSTimeInterval callDateInterval = [callDateIntervalString doubleValue];
                NSDate *calledDate = [NSDate dateWithTimeIntervalSince1970:callDateInterval];
                NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
                [formatter setDateFormat:@"MM/dd yyyy"];
                calledDateString = [formatter stringFromDate:calledDate];
                
                NSString *recordFileName = lastestCallHistoryDict[kRecordHistoryRecordFileName];
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *docs_dir = [paths objectAtIndex:0];
                NSString *recordFolderDir = [docs_dir stringByAppendingPathComponent:@"recordings"];
                NSString *recordFileLoacton = [recordFolderDir stringByAppendingPathComponent:recordFileName];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if([fileManager fileExistsAtPath:recordFileLoacton]){
                    NSURL *fileURL = [NSURL fileURLWithPath:recordFileLoacton];
                    AVURLAsset *urlAsset = [[AVURLAsset alloc]initWithURL:fileURL options:nil];
                    CMTime audioDuration = urlAsset.duration;
                    float audioDurationSecondsFloat = CMTimeGetSeconds(audioDuration);
                    int audioSeconds = (int)floor(audioDurationSecondsFloat);
                    recordAudioLength = [NSString stringWithFormat:@"录制声音 - %d 秒",audioSeconds];
                }
            }
            
            else{
                recordAudioLength = @"录制声音";
                calledDateString = @"";
            }
            
            
            historyCell.nameLabel.text = otherName;
            historyCell.phoneLabel.text = otherPhone;
            historyCell.detailLabel.text = recordAudioLength;
            historyCell.typeImageView.image = [UIImage imageNamed:@"phonecall_recording"];
            historyCell.dateLabel.text = calledDateString;
            return historyCell;
            
        }
        
        
        
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    // 搜索tableview
    if (tableView.tag == 11) {
        NSDictionary *searchDict = _filteredContactArray[indexPath.row];
        APContact *contact = searchDict[K_APCONTACT];
        
        WCPhoneContactDetailViewController *detailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Contact Detail Storyboard"];
        detailVC.contact = contact;
        detailVC.isFromDailVC = YES;
        [self.navigationController pushViewController:detailVC animated:YES];
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 搜索tableview
    if (tableView.tag == 11) {
        // 将所选的联系人号码显示，刷新tableview
        if (indexPath.row >= 0) {
            _isInputEmpty = NO;
            NSDictionary *searchDict = _filteredContactArray[indexPath.row];
            NSString *phone = [self handlePhoneNum:searchDict[K_PHONE]];
            _displayLabel.text = phone;
            [self searchContact:phone];
        }
    }
    
    // 通话或录音tableview
    else{
        // 通话记录
        if(!_isRecordHistoryTapped){
            NSDictionary *callHistoryDict = _callHistoryMutableArray[indexPath.row];
            NSString *otherName = callHistoryDict[kCallHistoryOther];
            NSString *otherPhone = callHistoryDict[kCallHistoryOtherPhone];
            NSArray *otherCallHistoryArray = callHistoryDict[kCallHistoryArray];
            
            WCCallHistoryViewController *callHistoryVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Call History Storyboard"];
            callHistoryVC.name = otherName;
            callHistoryVC.phone = otherPhone;
            callHistoryVC.callHistoryArray = otherCallHistoryArray;
            [self.navigationController pushViewController:callHistoryVC animated:YES];
            
        }
        // 录音记录
        else{
            NSDictionary *recordHistoryDict = _recordHistoryMutableArray[indexPath.row];
            NSString *otherName = recordHistoryDict[kRecordHistoryOther];
            NSString *otherPhone = recordHistoryDict[kRecordHistoryOtherPhone];
            NSArray *otherRecordHistoryArray = recordHistoryDict[kRecordHistoryArray];
            
            WCRecordHsitoryViewController *recordHistoryVC = [self.storyboard instantiateViewControllerWithIdentifier:@"Record History Storyboard"];
            recordHistoryVC.name = otherName;
            recordHistoryVC.phone = otherPhone;
            recordHistoryVC.recordHistoryArray = [NSMutableArray arrayWithArray:otherRecordHistoryArray];
            [self.navigationController pushViewController:recordHistoryVC animated:YES];
        }
        
    }
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 通话或录音tableview
    if (tableView.tag == 22) {
        return YES;
    }
    else{
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 22) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
            NSString *currentName = userInfoDict[USER_NAME_KEY];
            // 通话记录
            if(!_isRecordHistoryTapped){
                [_callHistoryMutableArray removeObjectAtIndex:indexPath.row];
                
                // 先查找是否有通话记录
                if ([userDefaults objectForKey:CALL_HISTORY]) {
                    NSArray *allUserCallHistoryArray = [userDefaults objectForKey:CALL_HISTORY];
                    // 如果有数据则查找
                    if ([allUserCallHistoryArray count] > 0) {
                        BOOL isFoundUser = NO;   // 是否找到当前用户通话记录
                        for (NSDictionary *allUserCallHistoryDict in allUserCallHistoryArray) {
                            NSString *userName = allUserCallHistoryDict[CALL_HISTORY_USERNAME];
                            if ([userName isEqualToString:currentName]) {
                                isFoundUser = YES;
                                NSUInteger currentUserIndex = [allUserCallHistoryArray indexOfObject:allUserCallHistoryDict];
                                NSMutableDictionary *allUserCallHistoryMutableDict = [allUserCallHistoryDict mutableCopy];
                                [allUserCallHistoryMutableDict setObject:_callHistoryMutableArray forKey:CALL_HISROTY_DATA];
                                NSMutableArray *allUserCallHistoryMutableArray = [allUserCallHistoryArray mutableCopy];
                                [allUserCallHistoryMutableArray removeObjectAtIndex:currentUserIndex];
                                [allUserCallHistoryMutableArray insertObject:allUserCallHistoryMutableDict atIndex:0];
                                [userDefaults setObject:allUserCallHistoryMutableArray forKey:CALL_HISTORY];
                                [userDefaults synchronize];

                                break;
                            }
                        }
                    }
                }
            }
            // 录音记录
            else{
                
                // 删除本地保存录音
                NSDictionary *recordHistoryDict = _recordHistoryMutableArray[indexPath.row];
                NSString *otherPhone = recordHistoryDict[kRecordHistoryOtherPhone];
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *docs_dir = [paths objectAtIndex:0];
                NSString *recordFolderDir = [docs_dir stringByAppendingPathComponent:@"recordings"];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if([fileManager fileExistsAtPath:recordFolderDir]){
                    NSArray *filesArray = [fileManager contentsOfDirectoryAtPath:recordFolderDir error:nil];
                    for (NSString *fileNameInDir in filesArray) {
                        NSString *beginFileName = [NSString stringWithFormat:@"%@_%@",currentName,otherPhone];
                        if ([fileNameInDir hasPrefix:beginFileName]) {
                            NSString *fileDir= [recordFolderDir stringByAppendingPathComponent:fileNameInDir];
                            [fileManager removeItemAtPath:fileDir error:nil];
                        }
                    }
                    
                }
                
                [_recordHistoryMutableArray removeObjectAtIndex:indexPath.row];


                // 先查找是否有通话记录
                if ([userDefaults objectForKey:RECORD_HISTORY]) {
                    NSArray *allUserCallHistoryArray = [userDefaults objectForKey:RECORD_HISTORY];
                    // 如果有数据则查找
                    if ([allUserCallHistoryArray count] > 0) {
                        BOOL isFoundUser = NO;   // 是否找到当前用户通话记录
                        for (NSDictionary *allUserCallHistoryDict in allUserCallHistoryArray) {
                            NSString *userName = allUserCallHistoryDict[RECORD_HISTORY_USERNAME];
                            if ([userName isEqualToString:currentName]) {
                                isFoundUser = YES;
                                NSUInteger currentUserIndex = [allUserCallHistoryArray indexOfObject:allUserCallHistoryDict];
                                NSMutableDictionary *allUserCallHistoryMutableDict = [allUserCallHistoryDict mutableCopy];
                                [allUserCallHistoryMutableDict setObject:_recordHistoryMutableArray forKey:RECORD_HISTORY_DATA];
                                NSMutableArray *allUserCallHistoryMutableArray = [allUserCallHistoryArray mutableCopy];
                                [allUserCallHistoryMutableArray removeObjectAtIndex:currentUserIndex];
                                [allUserCallHistoryMutableArray insertObject:allUserCallHistoryMutableDict atIndex:0];
                                [userDefaults setObject:allUserCallHistoryMutableArray forKey:RECORD_HISTORY];
                                [userDefaults synchronize];
                                
                                break;
                            }
                        }
                    }
                }
            }


            
            [_callAndRecordHistoryTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
        }
    }
}

#pragma mark - 添加联系人委托方法

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person
{

    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFY_CONTACT_MODIFY object:nil];
    }];
}

#pragma mark - 回拨

-(void)callbackFromServer
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfoDict = [userDefaults objectForKey:USER_MODEL_USERDEFAULT];
    NSString *username = userInfoDict[USER_NAME_KEY];
    NSString *callees = _displayLabel.text;
    NSString *type;
    
    if([userDefaults objectForKey:CALL_SHOW_YOURPHONENUM] == nil || [[userDefaults objectForKey:CALL_SHOW_YOURPHONENUM] boolValue] == YES){
        type = @"t";
    }
    else if ([[userDefaults objectForKey:CALL_SHOW_YOURPHONENUM] boolValue] == NO){
        type = @"h";
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSDictionary *parameters = @{@"username": username,@"callees":callees,@"type":type};
    AFHTTPRequestOperationManager *manager = [VCNetworkingUtil httpManager];
    [manager POST:WC_SERVER_CALLBACK
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              
              NSDictionary *statusDict = [responseObject objectForKey:@"status"];
              
              // 操作失败
              if ([statusDict[@"succeed"] integerValue] == 0) {
                  // NSString *errorCode = statusDict[@"error_code"];
                  NSString *errorDesc = statusDict[@"error_desc"];
                  
                  hud.mode = MBProgressHUDModeText;
                  hud.labelText = @"操作失败";
                  hud.detailsLabelText = errorDesc;
                  [hud hide:YES afterDelay:2];
              }
              
              // 操作成功
              else if([statusDict[@"succeed"] integerValue] == 1){
                  NSDictionary *dataDict = [responseObject objectForKey:@"data"];
                  
                  // 回拨成功
                  if ([dataDict[@"result"] integerValue] == 1) {
                      
                      hud.mode = MBProgressHUDModeCustomView;
                      hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
                      hud.labelText = @"回拨成功";
                      [hud hide:YES afterDelay:2];
                      
                      [self savePhoneHistory:@"回拨"];
                      
                      
                  }
                  
                  // 回拨不成功
                  else if([dataDict[@"result"] integerValue] == 0){
                      hud.mode = MBProgressHUDModeText;
                      hud.labelText = @"回拨失败，请重试";
                      [hud hide:YES afterDelay:2];
                  }
                  else if([dataDict[@"result"] integerValue] == 2){
                      hud.mode = MBProgressHUDModeText;
                      hud.labelText = @"重复请求";
                      [hud hide:YES afterDelay:2];
                  }
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
              hud.mode = MBProgressHUDModeText;
              hud.labelText = @"操作失败";
              hud.detailsLabelText = error.localizedDescription;
              [hud hide:YES afterDelay:2];
          }];

}

#pragma mark - 保存通话记录
-(void)savePhoneHistory:(NSString *)theCallStatus
{
    // 需要保存的通话信息
    
    
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = currentDate.timeIntervalSince1970;
    NSNumber *timeNumber = [NSNumber numberWithDouble:timeInterval];
    NSString *callDateInterval = [timeNumber stringValue];
    
    NSString *name = nil;
    // 如果是通讯录中号码则传姓名
    if (!_isInputEmpty && ([_filteredContactArray count] == 1)) {
        NSDictionary *searchDict = [_filteredContactArray lastObject];
        NSString *phone = searchDict[K_PHONE];
        if ([phone isEqualToString:_displayLabel.text]) {
            APContact *contact = searchDict[K_APCONTACT];
            name = contact.compositeName;
        }
    }

    NSString *otherPhoneNumber =  _displayLabel.text;
    NSString *otherName = (name == nil) ? @"未知" : name;
    NSString *inOrOut = @"out";
    NSString *callDate= callDateInterval;
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

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:SEGUE_DAIL_DIRECT_CALLING]){
        WCDirectCallingViewController *directCalling = segue.destinationViewController;
        directCalling.isCallOut = YES;
        directCalling.calledPhoneNumber = _displayLabel.text;
        
        NSDate *currentDate = [NSDate date];
        NSTimeInterval timeInterval = currentDate.timeIntervalSince1970;
        NSNumber *timeNumber = [NSNumber numberWithDouble:timeInterval];
        NSString *callDateInterval = [timeNumber stringValue];
        directCalling.callDate = callDateInterval;
        
        // 如果是通讯录中号码则传姓名
        if (!_isInputEmpty && ([_filteredContactArray count] == 1)) {
            NSDictionary *searchDict = [_filteredContactArray lastObject];
            NSString *phone = searchDict[K_PHONE];
            if ([phone isEqualToString:_displayLabel.text]) {
                APContact *contact = searchDict[K_APCONTACT];
                NSString *name = contact.compositeName;
                NSArray *phoneLabels = contact.phonesWithLabels;
                for (APPhoneWithLabel *phoneLabel in phoneLabels) {
                    NSString *myPhone = phoneLabel.phone;
                    if ([myPhone isEqualToString:phone]) {
                        NSString *label = phoneLabel.label;
                        directCalling.calledUserContact = @{@"name":name,@"label":label};
                        break;
                    }
                }
            }

        }
    }
}

#pragma mark - 去掉手机号码中的特殊字符

- (NSString *)handlePhoneNum:(NSString *)oldPhoneNum
{
    return [[[[[oldPhoneNum stringByReplacingOccurrencesOfString:@"-" withString:@""]
               stringByReplacingOccurrencesOfString:@"(" withString:@""]
              stringByReplacingOccurrencesOfString:@")" withString:@""]
             stringByReplacingOccurrencesOfString:@" " withString:@""]
            stringByReplacingOccurrencesOfString:@" " withString:@""];
}

#pragma mark - 从通讯录中选择联系人

- (IBAction)selectFromContact:(id)sender {
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    // Display only a person's phone, email, and birthdate
    NSArray *displayedItems = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonPhoneProperty],
                                nil];
    
    
    picker.displayedProperties = displayedItems;
    // Show the picker
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - 选择联系人回调

// Called after the user has pressed cancel.
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;

}


- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    if (property == kABPersonPhoneProperty) {
        ABMutableMultiValueRef phoneMulti = ABRecordCopyValue(person, property);
        
        int index = ABMultiValueGetIndexForIdentifier(phoneMulti,identifier);
        
        NSString* selectedPhone = [NSString stringWithFormat:@"%@",ABMultiValueCopyValueAtIndex(phoneMulti, index)];
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_CALL_PHONE object:[self handlePhoneNum:selectedPhone]];
        [peoplePicker dismissViewControllerAnimated:YES completion:nil];
        
    }
    
    return NO;
}


- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    if (property == kABPersonPhoneProperty) {
        ABMutableMultiValueRef phoneMulti = ABRecordCopyValue(person, property);
        
        int index = ABMultiValueGetIndexForIdentifier(phoneMulti,identifier);
        
        NSString* selectedPhone = [NSString stringWithFormat:@"%@",ABMultiValueCopyValueAtIndex(phoneMulti, index)];
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_CALL_PHONE object:[self handlePhoneNum:selectedPhone]];
        [peoplePicker dismissViewControllerAnimated:YES completion:nil];
        
    }

}
@end

