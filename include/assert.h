#define ABORT() throw(({"ERROR\n",backtrace()}))
#define abort() throw(({"ERROR\n",backtrace()}))
#define assert(EXP,FUNC ...) ((EXP)||((({FUNC})+({lambda(){}}))[0](),abort()))

#ifdef DEBUG
//#define ASSERT(EXP) assert(EXP)
#define ASSERT(EXP,FUNC ...) assert(EXP,FUNC)
#else
//#define ASSERT(EXP) 
#define ASSERT(EXP,FUNC ...)
#endif

