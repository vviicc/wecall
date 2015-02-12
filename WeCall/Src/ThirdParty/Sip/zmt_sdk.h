/************************************************************************/
/* AUTHOR:hongzhou.yang													*/
/* DATETIME:2014.04.21													*/
/* CONTENT: important sdk interface function declare					*/
/************************************************************************/
#ifndef	_ZMT_SDK_H
#define _ZMT_SDK_H
#include "zmt_type.h"

ZMT_BEGIN_DECL
//get zmt sdk version
char* zmt_get_version();

/**
 @param	zmt_config //init configure infomation
 *func init mycall sdk
 */
int	zmt_create(const zmt_config	*cfg);
/* destroy sdk lib*/

int zmt_destroy(unsigned flags);

//add zmt account
int     zmt_acc_add(const zmt_acc_config *acc_cfg, int *acc_id);

//delete zmt account
int     zmt_acc_delete(unsigned acc_id);

/* register or unregistar account*/
int zmt_acc_update_registration(int acc_id,int flags);

//call
//make out call
int     zmt_call_make_call(unsigned acc_id,  zmt_call_type call_type, char *conf_name, zmt_called_member *called_member, unsigned called_member_count, int *call_id);

//answer the call
int     zmt_call_answer(unsigned call_id, zmt_answer_flag answer_flag, zmt_callmedia_type media_type);

//hungup the call
int     zmt_call_hungup(unsigned call_id, short close_conf_flag);

//record the call
int     zmt_call_start_record(unsigned call_id, const char *record_file_name, zmt_callmedia_type media_type);

//stop the record
int     zmt_call_stop_record(unsigned call_id);

/*play video to peer*/
int zmt_call_start_player(int call_id,const char* filename,int loop_flags);
/*stop play*/
int zmt_call_stop_player(int call_id);
/*set whether show video */
//int zmt_call_vid_set_show(int call_id,int flag);

//int zmt_call_vid_set_pos_size(int call_id, zmt_vid_pos *pos, zmt_vid_size *size);
/*set video size and pos*/
//int zmt_call_vid_set_pos_size(int call_id,zmt_vid_pos *pos,zmt_vid_size *size);


/*show native video window*/
//int zmt_vid_preview_start(int flag);

/*stop preview video*/
//int zmt_vid_preview_stop(int flag);

/*set pos and size of the video window*/
//int zmt_vid_preview_set_pos_size(zmt_vid_pos *pos, zmt_vid_size *size);

/* register or unregistar account*/
int zmt_acc_update_registration(int acc_id,int flags);


//adjust tx level(mic)
int 	zmt_call_adjust_mic_level( float level);

//adjust rx level(speaker)
int	zmt_call_adjust_speaker_level( float level);

//get tx rx level(mic, speaker)
int    zmt_call_get_mic_speaker_level( unsigned *mic_level, unsigned *speaker_level);


//test video api
//void zmt_test_video();

ZMT_END_DECL

#endif
