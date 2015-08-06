#ifndef __LIST_WIDGETS__
#define __LIST_WIDGETS__
mapping _wtype2rule=([]);
#define LIST_WIDGETS_TYPE_PREFIX "pikecross_list_widgets_"
typedef __attribute__(LIST_WIDGETS_TYPE_PREFIX "public",mapping) WIDGET_MAPPING;
typedef __attribute__(LIST_WIDGETS_TYPE_PREFIX "useronly",mapping) WIDGET_MAPPING_USERONLY;
typedef __attribute__(LIST_WIDGETS_TYPE_PREFIX "private",mapping) WIDGET_MAPPING_PRIVATE;
typedef __attribute__(LIST_WIDGETS_TYPE_PREFIX "superuser",mapping) WIDGET_MAPPING_SUPERUSER;
#define MAPPINGTYPE(X,s,target_tags,player_tags,get_target) typedef __attribute__(LIST_WIDGETS_TYPE_PREFIX #X,mapping) X;private int _actiontype_##X##_register=(_wtype2rule[ARGTYPE(X)]=({target_tags,player_tags,get_target,s}),1);
#endif
