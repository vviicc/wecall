/*
 *Author:Casey
 *Date:2014-04-23
 *Desc:This file contains the main configuration settings
 */
#ifndef _CONFIG_H_
#define _CONFIG_H_


#ifdef __cplusplus
#       define ZMT_BEGIN_DECL           extern "C" {
#       define ZMT_END_DECL             }
#else
#       define ZMT_BEGIN_DECL   
#       define ZMT_END_DECL     
#endif

ZMT_BEGIN_DECL


#define ZMT_ERROR       -1
#define ZMT_SUCCESS     0

#define ZMT_SDK_VERSION "0.0.1"

/*
 *define the max account count
 */
#define MAX_ACCOUNT_COUNT       10

/*
 *define the max call count
 */
#define MAX_CALL_COUNT          10

/**
 *  max length to name server
 */
#define MAX_NAMESERVER_LENGTH   100


/**
 *      max length of log filename
 */
#define MAX_LOGNAME_LENGTH              256


/*
 *define the max length of sip number
 *
 */
#define MAX_SIPNUMBER_LENGTH            256

/*
 *define the max length of sip account name
 */
#define MAX_SIPNAME_LENGTH              128

//define the max length of sip uri
#define MAX_SIPURI_LENGTH		512

//define the max length of filename
#define MAX_FILENAME_LENGTH 	512

/*
 *define the max length of sip server
 */
#define MAX_SIPSERVER_LENGTH            128

/*
 *define the max length of sip password
 */
#define MAX_SIPPASSWORD_LENGTH          128

/*
 *define the max conference id length
 */
#define MAX_CONFERENCEID_LENGTH         128

/*
 * MAX call numbers     length
 */
#define MAX_NUMBERS_LEN                         128

//define the count of media type
#define MEDIA_TYPES             2

/*
 *define the max conference name len
 */
#define MAX_CONFNAME_LEN  128

//define the default register timeout
#define DEFAULT_SIPREGISTER_TIMEOUT	120

//define the max register timeout
#define MAX_SIPREGISTER_TIMEOUT		3600

//define the default SIP　Server Port
#define DEFAULT_SIPSERVER_PORT	5060

//define the call direction
typedef enum{DIRECTION_IN=0, DIRECTION_OUT}zmt_call_direction;

//define the pjsip log level
#define PJSIP_LOG_LEVEL 6 

//define the pjsip log name
//#define PJSIP_LOG_NAME	"pjsip.log"

ZMT_END_DECL

#endif
