#ifndef __CMDS__
#define __CMDS__
mapping _type2rule=([]);
#define CMDTYPE_PREFIX "pikecross_cmd_"
typedef __attribute__(CMDTYPE_PREFIX "public",int) PUBLIC;
typedef __attribute__(CMDTYPE_PREFIX "useronly",int) USERONLY;
typedef __attribute__(CMDTYPE_PREFIX "private",int) PRIVATE;
typedef __attribute__(CMDTYPE_PREFIX "superuser",int) SUPERUSER;
#define ACTIONTYPE(X,s,target_tags,player_tags,get_target) typedef __attribute__(CMDTYPE_PREFIX #X,int) X;private int _actiontype_##X##_register=(_type2rule[ARGTYPE(X)]=({target_tags,player_tags,get_target,s}),1);
#endif
