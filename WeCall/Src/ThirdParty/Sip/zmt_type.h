/************************************************************************/
/* AUTHOR:hongzhou.yang                                                 */
/* DATETIME:2014.04.22                                                  */
/* CONTENT: general data type declare					*/
/************************************************************************/
#ifndef _ZMT_TYPE_H
#define _ZMT_TYPE_H
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "config.h"

ZMT_BEGIN_DECL



/*
 *	socket transport type
 */
typedef enum{NONE,TCP,UDP,TLS,SCTP,UDP_IPV6,TCP_IPV6,TLS_IPV6}  zmt_transport_type_e;

/*
 *define the sip account register state
 */
typedef enum{ZMT_ACCOUNT_REGISTER_OFF=0, ZMT_ACCOUNT_REGISTER_ON, ZMT_ACCOUNT_REGISTER_FAILED} zmt_account_register_state;
/*
 * Media Receive and send status
 */
typedef enum{ReceiveOnly=0,SendOnly,SendReceive,UnActive} zmt_media_direction_e;

/*
 *define the call type
 */
typedef enum{ZMT_CALLTYPE_SINGLE, ZMT_CALLTYPE_CONF} zmt_call_type;

/*
 *define the call media type
 */
typedef enum{ZMT_CALLMEDIA_A=1, ZMT_CALLMEDIA_V, ZMT_CALLMEDIA_AV} zmt_callmedia_type;

/*
 *define the call state
 */
typedef enum{ZMT_CALLSTATE_INIT=0, ZMT_CALLSTATE_RING, ZMT_CALLSTATE_CONNECTED, ZMT_CALLSTATE_HUNGUP, ZMT_CALLSTATE_CALLFAILED, ZMT_CALLSTATE_REJECT} zmt_call_state;

/*
 *define the answer flag
 */
typedef enum{ZMT_ANSWER_OK=0, ZMT_ANSWER_BUSY, ZMT_ANSWER_REJECT} zmt_answer_flag;

/*
 *
 */
typedef enum{ZMT_CALLEVENT_RING=0,ZMT_CALLEVENT_CONNECTED, ZMT_CALLEVENT_HUNGUP, ZMT_CALLEVENT_FAILED} zmt_call_event_e;

/*position struct*/
typedef struct zmt_vid_pos
{
    int x;
    int y;
}zmt_vid_pos;
/*video win size*/
typedef struct zmt_vid_size
{
    int width;
    int height;
}zmt_vid_size;
/*
 *define the called member
 */
//TODO:the media type and the zmt_called_member vs zmt_conference_member
typedef struct zmt_called_member
{
	char	called_number[MAX_NUMBERS_LEN];
	zmt_callmedia_type media_type[MEDIA_TYPES];
	zmt_media_direction_e media_direction[MEDIA_TYPES];
}zmt_called_member;

/*
 *define the zmt_acc_config
 */
typedef struct zmt_acc_config
{
	char	sip_number[MAX_NUMBERS_LEN];
	char	sip_name[MAX_SIPNAME_LENGTH];
	char	sip_server[MAX_SIPSERVER_LENGTH];
	unsigned sip_server_port;
	char	sip_password[MAX_SIPPASSWORD_LENGTH];
	int	sip_register_timeout;
	zmt_transport_type_e	transport_type;	
}zmt_acc_config;

/*
 * conference member information
 */

typedef struct zmt_conference_member
{
	char called_number[MAX_NUMBERS_LEN];
	int  media_type[MEDIA_TYPES];
	zmt_media_direction_e media_direction[MEDIA_TYPES];
}zmt_conference_member;

/*
 * media state infomation
 */

typedef struct zmt_stream_state
{
	zmt_callmedia_type	media_type;
	
	float			media_rate;

	zmt_media_direction_e	stream_direction;
}zmt_stream_state;

/*client callback function*/
typedef struct zmt_callback
{
	void (*on_incoming_call)(int acc_id,int call_id, char *clgNumber, zmt_call_type call_type,
		char *conf_name,zmt_conference_member *conf_member,int conf_member_count);

	void (*on_call_state)(int call_id,zmt_call_event_e call_event);

	void (*on_reg_state)(int acc_id,int reg_state);

	void (*on_stream_state)(int call_id,zmt_stream_state *stream_state);

	void (*on_conference_member_state)(int call_id,char *conf_member,zmt_call_event_e *call_event);
}zmt_callback;

/**
 * SDK initialize configure infomation
 */


typedef struct zmt_config
{
	/**
	 *	max numbers of call
	 */
	unsigned int max_calls;

	/**
	 *	nameserver urls
	 */
	char	nameserver[4][MAX_NAMESERVER_LENGTH];

	/**
	 *	nameserver count
	 */
	int		nameserver_count;

	/**
	 *	stun server urls max eight
	 */
	char	stun_server[8][MAX_NAMESERVER_LENGTH];

	/**
	 * stun server count
	 */
	int		stun_server_count;

	/**
	 *	log lever
	 */
	int		log_level;

	/**
	 *	sdk logfile name
	 */
	char	log_name[MAX_LOGNAME_LENGTH];

	/*
	 *	pj_log lever
	 */
//	int	pj_log_level;

	/*
	 *   pj_log_name
	 */

//	char	pj_log_name[MAX_LOGNAME_LENGTH];
	/**
	 *	network transport type
	 */
	zmt_transport_type_e transport_type;
	/**
	 *	rtp stream report about bps
	 */
	float	stream_resolution;


	char	ring_file_name[MAX_FILENAME_LENGTH];

	/*
	 * callbacks
	 */
	zmt_callback	cb;

}zmt_config;

ZMT_END_DECL
#endif
