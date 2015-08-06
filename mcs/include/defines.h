#define DEBUG/*{{{*/

#define ABORT() throw(({"ERROR\n",backtrace()}))
#define assert(EXP) ((EXP)||ABORT())

#ifdef DEBUG
#define ASSERT(EXP) assert(EXP)
#define ASSERT_TRUE(EXP,DUMP) if(!(EXP)) {werror("%s ==0\n%s = %O\n",#EXP,#DUMP,(DUMP));ABORT();}
#endif/*}}}*/

#include "version.h"

#define WIDGET_OPT
#define RUNTIME_CHECK_OPT
//#define WERROR_OPT

#define INIT_EXEC(UID,CODE ...) private int _init_##UID=(CODE,1)
#define REGISTER(X) INIT_EXEC(X,MODULED->add_object_function(this,#X,X))

#define ENTER(session) mixed _old_cwd=getcwd();cd(WORKING_DIR);mixed _old_session=THIS_SESSIOND->this_session();THIS_SESSIOND->set_this_session(session);mixed _e=catch{
#define LEAVE() };cd(_old_cwd);THIS_SESSIOND->set_this_session(_old_session);if(_e){throw(_e);};

#define check_extern Function.curry(MODULED->check_extern)(this)
#define auto_check_extern Function.curry(MODULED->auto_check_extern)(this)
#define check_inherit Function.curry(MODULED->check_inherit)(this)

#define ARGTYPE(X) __get_first_arg_type(_typeof(lambda(X arg){}))

//#define BIGARRAY Func("DBASEITEMD","bigarray")

#define format(s) replace(s,(["\n\n":"<br/>\n"]))

#define LOCALE(X,Y) Locale.translate("pikecross", this_app()->lang||"chn", X, Y)

#define CONF(VAR,VAL) private mixed `##VAR(){return CONFD->conf(#VAR,VAL);}
#define SET(VAR,VAL) private mixed _init##VAR=CONFD->set(#VAR,VAL); CONF(VAR,VAL);
