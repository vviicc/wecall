//
//  WCPhoneContactViewController.m
//  WeCall
//
//  Created by Vic on 14-12-11.
//  Copyright (c) 2014年 feixiang. All rights reserved.
//

#import "WCPhoneContactViewController.h"
#import <APAddressBook/APAddressBook.h>
#import <APAddressBook/APContact.h>
#import "VCPinyin.h"
#import "WCPhoneContactTableViewCell.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "WCPhoneContactDetailViewController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#define SEGUE_PHONECONTACT_DETAIL @"Phone Contact 2 Detail"

@interface WCPhoneContactViewController ()<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate, UISearchDisplayDelegate,ABNewPersonViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *contactTableView;
- (IBAction)addNewContact:(id)sender;

@property (strong,nonatomic) APAddressBook *addressBook;
@property (strong,nonatomic) NSArray *contactsArray;
@property (strong,nonatomic) NSArray *sectionTitlesArray;
@property (strong,nonatomic) NSDictionary *contactsDict;
@property (strong,nonatomic) NSMutableArray *filteredContactArray;
@property (strong,nonatomic) APContact *selectedContact;


@end

@implementation WCPhoneContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(addContact:) name:NOTIFY_CONTACT_MODIFY object:nil];
    [self setup];
    [self loadContact];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Setup

- (void)setup
{
    _addressBook = [[APAddressBook alloc]init];
    _addressBook.fieldsMask = APContactFieldFirstName | APContactFieldLastName | APContactFieldCompositeName |
    APContactFieldPhones | APContactFieldPhonesWithLabels | APContactFieldThumbnail;
    //    _addressBook.sortDescriptors = @[
    //                                     [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
    //                                     [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]];
    _addressBook.filterBlock = ^BOOL(APContact *contact)
    {
        return contact.phones.count > 0 && ((contact.firstName != nil) || (contact.lastName !=nil));
    };
}

#pragma mark - 新增联系人通知

-(void)addContact:(NSNotification *)noti
{
    [self loadContact];
}

#pragma mark - Load Contact

- (void)loadContact
{
    [_addressBook loadContacts:^(NSArray *contacts, NSError *error) {
        if(!error){
            NSArray *soretdArray = [contacts sortedArrayUsingFunction:contactNameSort context:NULL];
            _contactsArray = [NSArray arrayWithArray:soretdArray];
            [self convertContactsArrayToDict];
            [_contactTableView reloadData];
        }
        else{
            switch([APAddressBook access])
            {
                    //TODO: 下面方法没有调用
                case APAddressBookAccessUnknown:
                    [VCViewUtil showAlertMessage:@"请到 系统设置-隐私-通讯录 中开启" andTitle:@"无法访问通讯录"];
                    break;
                    
                case APAddressBookAccessGranted:
                    break;
                    
                case APAddressBookAccessDenied:
                    [VCViewUtil showAlertMessage:@"请到 系统设置-隐私-通讯录 中开启" andTitle:@"无法访问通讯录"];
                    break;
            }
        }
    }];
}

#pragma mark - Sort Contacts By Name

NSInteger contactNameSort(id contact1, id contact2, void *context)
{
    NSString *name1 = [NSString stringWithFormat:@"%@%@",
                       [(APContact *)contact1 lastName] ? [(APContact *)contact1 lastName] : @"",
                       [(APContact *)contact1 firstName] ? [(APContact *)contact1 firstName] :@""];
    NSString *name2 = [NSString stringWithFormat:@"%@%@",
                       [(APContact *)contact2 lastName] ? [(APContact *)contact2 lastName] : @"",
                       [(APContact *)contact2 firstName] ? [(APContact *)contact2 firstName] :@""];
    return  [name1 localizedCaseInsensitiveCompare:name2];
}

#pragma mark - Convert Contacts Array To Dictionary

- (void)convertContactsArrayToDict
{
    // 获取联系人的首字母分组
    
    NSMutableArray *firstLetterArray = [NSMutableArray array];
    
    for(APContact *contact in _contactsArray){
        NSString *name = [NSString stringWithFormat:@"%@%@",
                          [contact lastName] ? [contact lastName] : @"",
                          [contact firstName] ? [contact firstName] :@""];
        char firstLetterChar = pinyinFirstLetter([name characterAtIndex:0]);
        NSString *firstLetterString = [NSString stringWithFormat:@"%c",firstLetterChar];
        if(![firstLetterArray containsObject:[firstLetterString uppercaseString]]){
            [firstLetterArray addObject:[firstLetterString uppercaseString]];
        }
    }
    
    [firstLetterArray sortUsingSelector:@selector(compare:)];
    _sectionTitlesArray = [NSArray arrayWithArray:firstLetterArray];
    
    // 获取Contact Dictionary
    
    NSMutableDictionary *personsDict = [[NSMutableDictionary alloc]init];
    
    //每个首字母对应的行列表
    for(NSString *sectionTitle in _sectionTitlesArray){
        NSMutableArray *rowArray = [NSMutableArray array];
        
        for(APContact *contact in _contactsArray){
            NSString *name = [NSString stringWithFormat:@"%@%@",
                              [contact lastName] ? [contact lastName] : @"",
                              [contact firstName] ? [contact firstName] :@""];
            char firstLetterChar = pinyinFirstLetter([name characterAtIndex:0]);
            NSString *firstLetterString = [NSString stringWithFormat:@"%c",firstLetterChar];
            if([sectionTitle isEqualToString:[firstLetterString uppercaseString]]){
                [rowArray addObject:contact];
            }
        }
        
        [personsDict setValue:rowArray forKey:sectionTitle];
    }
    
    _contactsDict = [NSDictionary dictionaryWithDictionary:personsDict];
}

#pragma mark - Delegates
#pragma mark -- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
    if(tableView == self.searchDisplayController.searchResultsTableView){
        _selectedContact = _filteredContactArray[indexPath.row];
        
    }
    else{
        NSString * sectionTitle = [_sectionTitlesArray objectAtIndex:indexPath.section];
        
        NSArray *rowArray = [_contactsDict objectForKey:sectionTitle];
        if ([rowArray count] > 0) {
            _selectedContact = rowArray[indexPath.row];
            
        }
    }
    
    [self performSegueWithIdentifier:SEGUE_PHONECONTACT_DETAIL sender:self];
    
    
}



#pragma mark -- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == self.searchDisplayController.searchResultsTableView){
        return [_filteredContactArray count];
    }
    else{
        NSArray *dicCount = [_contactsDict objectForKey:[_sectionTitlesArray objectAtIndex:section]];
        return [dicCount count];
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView == self.searchDisplayController.searchResultsTableView){
        return 1;
    }
    else{
        return [_sectionTitlesArray count];
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(tableView == self.searchDisplayController.searchResultsTableView){
        return nil;
    }
    else{
        return [_sectionTitlesArray objectAtIndex:section];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if(tableView == self.searchDisplayController.searchResultsTableView){
        return nil;
    }
    else{
        NSMutableArray *sectionIndexTitles = [NSMutableArray arrayWithArray:_sectionTitlesArray];
        
        return sectionIndexTitles;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Phone Contact Cell";
    
    // 如果是搜索页面
    if(tableView == self.searchDisplayController.searchResultsTableView){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Phone Contact Cell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Phone Contact Cell"];
        }
        APContact *contact = _filteredContactArray[indexPath.row];
        cell.textLabel.text = contact.compositeName;
//        UIImage *thumbnail = contact.thumbnail;
//        cell.avatarImageView.image = thumbnail ? thumbnail : [UIImage imageNamed:@"avatar-40"];
        return cell;
    }
    
    else{
        
        WCPhoneContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(cell == nil){
            cell = [[WCPhoneContactTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        NSString * sectionTitle = [_sectionTitlesArray objectAtIndex:indexPath.section];
        
        NSArray *rowArray = [_contactsDict objectForKey:sectionTitle];
        if ([rowArray count] > 0) {
            APContact *contact = rowArray[indexPath.row];
            NSArray *phones = contact.phones;
            UIImage *thumbnail = contact.thumbnail;
            cell.nameLabel.text = [contact compositeName];
            cell.avatarImageView.image = thumbnail ? thumbnail : [UIImage imageNamed:@"avatar-40"];
            NSMutableString *phoneNums = [NSMutableString stringWithCapacity:30];
            for (NSString *phoneNum in phones) {
                [phoneNums appendString:[NSString stringWithFormat:@"%@ ",phoneNum]];
            }
        }
        return cell;

    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    // 如果是搜索页面
    if(tableView == self.searchDisplayController.searchResultsTableView){
        return 0;
    }
    
    else{
        NSInteger count = 0;
        for(NSString *sectionTitle in _sectionTitlesArray)
        {
            if([sectionTitle isEqualToString:title])
            {
                return count;
            }
            count ++;
        }
        
        return 0;
    }
    
}

#pragma mark - UISearchDisplayDelegate

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

// 联系人搜索

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"compositeName contains[c] %@", searchText];
    _filteredContactArray = [NSMutableArray arrayWithArray:[_contactsArray filteredArrayUsingPredicate:resultPredicate]];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SEGUE_PHONECONTACT_DETAIL]) {
        WCPhoneContactDetailViewController *detail = segue.destinationViewController;
        detail.contact = _selectedContact;
    }
}

/**
 *    去掉电话号码的（，），-,这些符号，如138-1111-1111，变为13811111111
 */

#pragma mark - PhoneNumber Handle

- (NSString *)handlePhoneNum:(NSString *)oldPhoneNum
{
    return [[[[[oldPhoneNum stringByReplacingOccurrencesOfString:@"-" withString:@""]
               stringByReplacingOccurrencesOfString:@"(" withString:@""]
              stringByReplacingOccurrencesOfString:@")" withString:@""]
             stringByReplacingOccurrencesOfString:@" " withString:@""]
            stringByReplacingOccurrencesOfString:@" " withString:@""];
}

#pragma mark - 新增联系人

- (IBAction)addNewContact:(id)sender {
    ABNewPersonViewController *picker = [[ABNewPersonViewController alloc] init];
    picker.newPersonViewDelegate = self;
    
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:picker];
    [self presentViewController:navigation animated:YES completion:nil];
}

#pragma mark - 添加联系人回调函数

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter]postNotificationName:NOTIFY_CONTACT_MODIFY object:nil];
    }];
}
@end
