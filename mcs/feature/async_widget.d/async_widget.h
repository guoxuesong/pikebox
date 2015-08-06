#ifndef __ASYNC_WIDGET__
#define __ASYNC_WIDGET__
mapping _awtype2rule=([]);
#define ASYNC_WIDGET_TYPE_PREFIX "pikecross_async_widget_"
typedef __attribute__(ASYNC_WIDGET_TYPE_PREFIX "public",int) ASYNC_WIDGET;
typedef __attribute__(ASYNC_WIDGET_TYPE_PREFIX "useronly",int) ASYNC_WIDGET_USERONLY;
typedef __attribute__(ASYNC_WIDGET_TYPE_PREFIX "private",int) ASYNC_WIDGET_PRIVATE;
typedef __attribute__(ASYNC_WIDGET_TYPE_PREFIX "superuser",int) ASYNC_WIDGET_SUPERUSER;
#define ASYNCTYPE(X,s,target_tags,player_tags,get_target) typedef __attribute__(ASYNC_WIDGET_TYPE_PREFIX #X,int) X;private int _actiontype_##X##_register=(_awtype2rule[ARGTYPE(X)]=({target_tags,player_tags,get_target,s}),1);
#endif
