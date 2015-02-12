//
//  HHSIPUtil.m
//  huihaiIOS
//
//  Created by Vic on 14-9-20.
//  Copyright (c) 2014年 huihai. All rights reserved.
//

#import "HHSIPUtil.h"

#import "zmt_sdk.h"
#import "AppDelegate.h"
#import "Global.h"
#import <SSKeychain/SSKeychain.h>
#import <pjsua-lib/pjsua.h>
#import <pj/string.h>

static  int accountId = 0;
static unsigned int callId = 0;
static int recordId = 0;

const size_t MAX_SIP_ID_LENGTH = 50;
const size_t MAX_SIP_REG_URI_LENGTH = 50;


@interface HHSIPUtil ()<UIAlertViewDelegate>


@end

@implementation HHSIPUtil


+(HHSIPUtil *)sharedInstance
{
    static HHSIPUtil *sipUtil = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sipUtil = [[HHSIPUtil alloc] init];
    });
    

    return sipUtil;
}

static void on_reg_state(int _accountId, int regState)
{
    NSLog(@"get register event:accountId:%d, reg state:%d\n", _accountId, regState);
    accountId = _accountId;
}

static void on_incoming_call(int acc_id, int call_id, char *clgNumber, zmt_call_type call_type, char *conf_name, zmt_conference_member *conf_member, int conf_member_count)
{
    NSLog(@"get on incoming call event,call_id:%d\n", call_id);
    callId = call_id;
    
    // 如果是一对一呼叫
    if(call_type == ZMT_CALLTYPE_SINGLE){
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        [delegate handleIncomingCall:[NSString stringWithCString:clgNumber encoding:NSUTF8StringEncoding]];
    }
    
    /*
    // 如果是在后台
    if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground){
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = @"来电话啦...";
        notification.alertAction = @"打开";
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
     */
    
}

static void on_call_state(int call_id, zmt_call_event_e call_event)
{
    NSLog(@"get call state event, call_id:%d, call_event:%d\n", call_id, call_event);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"zmt_call_event" object:@(call_event)];
}

/*
- (int)initZMTSDK
{
    int ret;
    zmt_config config;
    config.max_calls = 2;
    config.log_level = 4;
    
    config.cb.on_reg_state = &on_reg_state;
    config.cb.on_incoming_call = &on_incoming_call;
    config.cb.on_call_state = &on_call_state;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs_dir = [paths objectAtIndex:0];
    NSString* aFile = [docs_dir stringByAppendingPathComponent: @"zmt_sdk.log"];
    const char* zmt_sdk_log = [aFile fileSystemRepresentation];
    
    sprintf(config.log_name, "%s", zmt_sdk_log);
    
    
    NSString* aPJSIPFile = [docs_dir stringByAppendingPathComponent: @"pjsip.log"];
    const char* zmt_pjsip_log = [aPJSIPFile fileSystemRepresentation];
    //config.pj_log_level = 6;
    //sprintf(config.pj_log_name, "%s", zmt_pjsip_log);
    
    NSString* ringFile = [docs_dir stringByAppendingPathComponent: @"Ring.wav"];
    const char* ring_file_name = [ringFile fileSystemRepresentation];
    sprintf(config.ring_file_name, "%s", ring_file_name);
    
    config.nameserver_count = 0;
    config.stun_server_count = 0;
    config.transport_type = UDP;
    
    NSLog(@"zmt create begin, len:%zu, zmt_sdk_log:%s" ,strlen(zmt_sdk_log), zmt_sdk_log);
    NSLog(@"pjsip log:%s",zmt_pjsip_log);
    NSLog(@"ring file:%s",ring_file_name);
    ret =zmt_create(&config);
    if (ret <0 ) {
        NSLog(@"zmt create failed, ret:%d", ret);
        //printf("zmt create failed ll");
    }
    else{
        NSLog(@"zmt create success");
    }
    return 0;
    
}

// 注册
-(BOOL)registerSIP
{
    [self initZMTSDK];
    NSDictionary *voipLoginDict = [[NSUserDefaults standardUserDefaults]objectForKey:USER_MODEL_USERDEFAULT];
    sipServerIp = WC_SIP_HOST_IP;
//    NSString *strServerPort = voipLoginDict[@"serverport"];
    sipServerPort = WC_SIP_HOST_PORT;
    sipNumber = voipLoginDict[USER_NAME_KEY];
    sipPassword = [SSKeychain passwordForService:KEY_KEYCHAIN_SERVICE_ACCOUNT account:voipLoginDict[USER_NAME_KEY]];
    
    zmt_acc_config acc_cfg;
    
    sprintf(acc_cfg.sip_number, "%s", [sipNumber UTF8String]);
    sprintf(acc_cfg.sip_server, "%s", [sipServerIp UTF8String]);
    sprintf(acc_cfg.sip_password, "%s", [sipPassword UTF8String]);
    acc_cfg.sip_register_timeout = 120;
    acc_cfg.sip_server_port = sipServerPort;
    
    int ret;
    ret  = zmt_acc_add(&acc_cfg,&accountId);
    if (ret<0) {
        
        NSLog(@"register failed\n");
        return NO;
    }
    else{
        NSLog(@"register success\n");
        return YES;
    }
    

    
}
*/

#pragma mark -registerSIP2

-(BOOL)registerSIP2
{
    pj_status_t status;
    
    // Create pjsua first
    status = pjsua_create();
    if (status != PJ_SUCCESS) {
        error_exit("Error in pjsua_create()", status);
        return NO;
    }
    // Init pjsua
    {
        // Init the config structure
        pjsua_config cfg;
        pjsua_config_default (&cfg);
        
        cfg.cb.on_incoming_call = &on_incoming_call2;
        cfg.cb.on_call_media_state = &on_call_media_state2;
        cfg.cb.on_call_state = &on_call_state2;
        cfg.cb.on_reg_state2 = &on_reg_state2;
        

        // Init the logging config structure

        /*
        pjsua_logging_config log_cfg;
        pjsua_logging_config_default(&log_cfg);
        log_cfg.console_level = 4;
         */
        // Init the pjsua
//        status = pjsua_init(&cfg, &log_cfg, NULL);
        status = pjsua_init(&cfg, NULL, NULL);


        if (status != PJ_SUCCESS) {
            error_exit("Error in pjsua_create()", status);
            return NO;
        }



    }
    
    // Add UDP transport.
    {
        // Init transport config structure
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5060;
        
        // Add UDP transport.
        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, NULL);
        if (status != PJ_SUCCESS)  {
            error_exit("Error in pjsua_create()", status);
            return NO;
        }

        

    }
    
    // Add TCP transport.
    /*
    {
        // Init transport config structure
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5060;
        
        // Add TCP transport.
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &cfg, NULL);
        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
    }
    */
    
    
    // Initialization is done, now start pjsua
    status = pjsua_start();
    if (status != PJ_SUCCESS)  {
        error_exit("Error in pjsua_create()", status);
        return NO;
    }
    
    // Register the account on local sip server
    {
        pjsua_acc_config cfg;
        
        pjsua_acc_config_default(&cfg);
        
        cfg.reg_timeout = 120;
        

        
        // Account ID
        
        NSDictionary *voipLoginDict = [[NSUserDefaults standardUserDefaults]objectForKey:USER_MODEL_USERDEFAULT];
        sipServerIp =  WC_SIP_HOST_IP;
        //    NSString *strServerPort = voipLoginDict[@"serverport"];
        sipServerPort = WC_SIP_HOST_PORT;
        sipNumber = voipLoginDict[USER_NAME_KEY];
        sipPassword = [SSKeychain passwordForService:KEY_KEYCHAIN_SERVICE_ACCOUNT account:voipLoginDict[USER_NAME_KEY]];
        
        
        
        char sipId[MAX_SIP_ID_LENGTH];
        sprintf(sipId, "sip:%s@%s", [sipNumber UTF8String], [sipServerIp UTF8String]);
        cfg.id = pj_str(sipId);
        
        // Reg URI
        char regUri[MAX_SIP_REG_URI_LENGTH];
        sprintf(regUri, "sip:%s", [sipServerIp UTF8String]);
        cfg.reg_uri = pj_str(regUri);
        
        // Account cred info
        cfg.cred_count = 1;
        cfg.cred_info[0].scheme = pj_str("digest");
        cfg.cred_info[0].realm = pj_str((char *)[sipServerIp UTF8String]);
        cfg.cred_info[0].username = pj_str((char *)[sipNumber UTF8String]);
        cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
        cfg.cred_info[0].data = pj_str((char *)[sipPassword UTF8String]);
        
        status = pjsua_acc_add(&cfg, PJ_TRUE, &accountId);
        if (status != PJ_SUCCESS) {
            error_exit("Error in pjsua_create()", status);
            return NO;
        }

    }
    
    
    return YES;
}

/* Callback called by the library when registration state has changed */
static void on_reg_state2(pjsua_acc_id acc_id, pjsua_reg_info *info)
{
    NSLog(@"get register event:accountId:%d, reg state\n", acc_id);
    accountId = acc_id;
}

/* Callback called by the library upon receiving incoming call */
static void on_incoming_call2(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata)
{
    
    pjsua_call_info call_info;
    pjsua_call_get_info(call_id, &call_info);
    char *contactPtr = call_info.remote_contact.ptr;
    NSString *contactString = [[NSString alloc]initWithUTF8String:contactPtr];
    NSArray *contactArray = [contactString componentsSeparatedByString:@"@"];
    NSString *callPhoneNum = (NSString *)[contactArray firstObject];
    NSArray *contactArray2 = [callPhoneNum componentsSeparatedByString:@":"];
    NSString *callPhoneNum2 = [contactArray2 lastObject];

    
    callId = call_id;
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
//    [delegate handleIncomingCall:[NSString stringWithCString:clgNumber encoding:NSUTF8StringEncoding]];
    NSLog(@"on_incoming_call2");
    [delegate handleIncomingCall:callPhoneNum2];


}

/* Callback called by the library when call's state has changed */
static void on_call_state2(pjsua_call_id call_id, pjsip_event *e)
{
    pjsua_call_info ci;
        
    pjsua_call_get_info(call_id, &ci);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"zmt_call_event" object:@(ci.state)];


}

/* Callback called by the library when call's media state has changed */
static void on_call_media_state2(pjsua_call_id call_id)
{
    pjsua_call_info ci;
    
    pjsua_call_get_info(call_id, &ci);
    
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        // When media is active, connect call to sound device.
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
    }
}

/* Display error and exit application */
static void error_exit(const char *title, pj_status_t status)
{
    NSLog(@"-----------error_exit------:%s",title);
//    pjsua_destroy();
}

/*
-(void)unregisterSIP
{
    zmt_acc_update_registration(accountId, 0);
}


// 拨打
-(BOOL)callSIP:(NSString *)calledPhoneNumber
{
    NSString *strCalledNumber = calledPhoneNumber;
    zmt_called_member calledMember ;
    sprintf(calledMember.called_number, "%s", [strCalledNumber UTF8String]);
    unsigned calledMemberCount = 1;
    int ret;
    char name[10];
    int call_id;
    ret = zmt_call_make_call(accountId, ZMT_CALLTYPE_SINGLE, name, &calledMember, calledMemberCount, &call_id);
    if (ret < 0) {
        NSLog(@"call failed");
        return NO;
    }
    else{
        NSLog(@"call success");
        callId = call_id;
        return YES;
    }
    
}
 */

-(BOOL)callSIP2:(NSString *)calledPhoneNumber
{
    pj_status_t status;
    
    char uri[256];
    pj_str_t pj_uri;
    const char *sip_domain;
    
    sip_domain = [WC_SIP_HOST_IP UTF8String];
    
    pj_ansi_snprintf(uri, 256, "sip:%s@%s", [calledPhoneNumber UTF8String], sip_domain);
    
    status = pjsua_verify_sip_url(uri);
    if (status != PJ_SUCCESS)
    {
        return NO;
    }
    
    pj_uri = pj_str(uri);
    
    int call_id;

    status = pjsua_call_make_call(accountId, &pj_uri, 0, NULL, NULL, &call_id);
    if (status != PJ_SUCCESS) {
        error_exit("Error making call", status);
        return NO;
    }
    else{
        callId = call_id;
        return YES;
    }
}

/*
// 挂断
-(void)hungupSIP
{
    zmt_call_hungup(callId, 0);
}
 */

-(void)hungupSIP2
{
    pjsua_call_hangup_all();

}

/*
// 接听
-(void)answerCall
{
    zmt_call_answer(callId, ZMT_ANSWER_OK, ZMT_CALLMEDIA_A);
}
 */

-(void)answerCall2
{
    pjsua_call_answer(callId, 200, NULL, NULL);
}

/*
// 拒接
-(void)rejectCall
{
    zmt_call_answer(callId, ZMT_ANSWER_REJECT, ZMT_CALLMEDIA_A);
}
 */

-(void)rejectCall2
{
    pjsua_call_hangup_all();

}

/*
-(void)reregister:(id)sender
{
    zmt_acc_update_registration(accountId, 1);
}
 */

/*
// 删除账号
-(void)deleteAccount
{
    zmt_acc_delete(accountId);
}
 */

-(void)deleteAccount2
{
    pjsua_call_hangup_all();
    pjsua_stop_worker_threads();
    pjsua_acc_del(accountId);
    pjsua_destroy();

}


// 开始录音
-(void)startRecord:(NSString *)filePath
{
//    NSString *recordFileName = [recordFileText text];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *docs_dir = [paths objectAtIndex:0];
//    NSString* aFile = [docs_dir stringByAppendingPathComponent: recordFileName];
    const char* recordFile = [filePath fileSystemRepresentation];
    
    
//    zmt_call_start_record(callId, recordFile, ZMT_CALLMEDIA_A);
}

-(void)startRecord2:(NSString *)filePath
{
    const char* recordFile = [filePath fileSystemRepresentation];
    pj_str_t pjFile = pj_str((char *)recordFile);

    pj_status_t status = pjsua_recorder_create(&pjFile, 0, NULL, -1, 0, &recordId);
    
    if(status != PJ_SUCCESS){
        NSLog(@"pjsua_recorder_create error");
    }
    
    else{
        int rec_port = pjsua_recorder_get_conf_port(recordId);
        int call_port = pjsua_call_get_conf_port(callId);
        status = pjsua_conf_connect(call_port, rec_port);
        if (status != PJ_SUCCESS) {
            NSLog(@"pjsua_recorder_create error");

        }
    }
}


// 停止录音
-(void)stopRecord
{
//    zmt_call_stop_record(callId);
}

-(void)stopRecord2
{
    pj_status_t status = pjsua_recorder_destroy(recordId);
    if(status != PJ_SUCCESS){
        NSLog(@"pjsua_recorder_destroy error");
    }
}

/*
// 播放录音
-(void)startPlayFile:(NSString *)filePath
{
    
//    NSString *playFileName = [playFileText text];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *docs_dir = [paths objectAtIndex:0];
//    NSString* aFile = [docs_dir stringByAppendingPathComponent: playFileName];
    const char* playFile = [filePath fileSystemRepresentation];
    
    zmt_call_start_player(callId, playFile, 0);
    
}

 
// 停止播放录音
-(void)stopPlayFile
{
    zmt_call_stop_player(callId);
}

-(void)destroy:(id)sender
{
    zmt_destroy(1);
}
 */

-(void)holdCall2
{
    pjsua_call_set_hold(callId, NULL);
}

-(void)holdCall
{
    // disconnect the call bridge
    pjsua_conf_disconnect(0,  pjsua_call_get_conf_port(callId));
    // silent the mic
    pjsua_conf_adjust_rx_level(pjsua_call_get_conf_port(callId), 0.0f);}

// 释放保持通话
-(void)unholdCall2
{
    pjsua_call_reinvite(callId, PJ_TRUE, NULL);
}

-(void)unholdCall
{
    // reconnect the call bridge
    pjsua_conf_connect(0, pjsua_call_get_conf_port(callId));
    // enable mic again
    pjsua_conf_adjust_rx_level(pjsua_call_get_conf_port(callId), 1.0f);
}

-(void)daildtmf:(NSString *)dailNum
{
    
    pj_str_t pjDigits = pj_str((char *)[dailNum cStringUsingEncoding:NSASCIIStringEncoding]);
    pj_status_t status = pjsua_call_dial_dtmf(callId,&pjDigits);
    
    if (status != PJ_SUCCESS) {  // Okay, that didn't work. Send INFO DTMF.
        const pj_str_t kSIPINFO = pj_str("INFO");
        
        for (NSUInteger i = 0; i < [dailNum length]; ++i) {
            pjsua_msg_data messageData;
            pjsua_msg_data_init(&messageData);
            messageData.content_type = pj_str("application/dtmf-relay");
            
            NSString *messageBody
            = [NSString stringWithFormat:@"Signal=%C\r\nDuration=300",
               [dailNum characterAtIndex:i]];
            messageData.msg_body = pj_str((char *)[messageBody cStringUsingEncoding:NSASCIIStringEncoding]);
            
            status = pjsua_call_send_request(callId, &kSIPINFO, &messageData);
            if (status != PJ_SUCCESS)
                NSLog(@"Error sending DTMF");
        }
    }
}


#pragma mark -UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
}

@end
