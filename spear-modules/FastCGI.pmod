#pike __REAL_VERSION__

/*ABORT ASSERT FAIL{{{*/
#define DEBUG

#define ABORT() throw(({"ERROR\n",backtrace()}))
#define assert(EXP) ((EXP)||ABORT())

#ifdef DEBUG
#define ASSERT(EXP) assert(EXP)
#endif

#define FAIL() throw(({"FAIL\n",backtrace()}))/*}}}*/

//Thread.Mutex mutex=Thread.Mutex();

class Request{
	constant cross_c_include=/*{{{*/
#"
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcgiapp.h>
#include <pthread.h>
";/*}}}*/
	constant cross_c_cc=/*{{{*/
			"gcc -g -shared -lfcgi -fPIC"
			;/*}}}*/

	int request;
	int rc;
	mapping env=([]);
	void create()
	{
		//werror("Request create ...\n");
		C{
			FCGX_Request* request;
			request=(FCGX_Request*)malloc(sizeof(FCGX_Request));
			//fprintf(stderr,"request allocated: %X\n",request);
			//printf("t1\n");
			P{request=INT{request};}
			//P{predef::write("haha\n");};
			//printf("t2\n");
			if(request){
				//printf("%X\n",(void*)request);

				//P{predef::write("haha\n");};
				FCGX_InitRequest(request, 0, 0);
				//printf("%X\n",(void*)request);
				//P{predef::write("haha\n");};
			}
		}
		if(!request){
			throw(({"out of memory",backtrace()}));
		}
	}
	/*int get_request()
	{
		ASSERT(request!=0);
		//werror("request reload send: %X\n",request);
		return request;
	}*/
	void accept()
	{
		ASSERT(request!=0);
		C{
			char** p;
			FCGX_Request* request=(FCGX_Request*)(INT{request});
			//fprintf(stderr,"request reload accept: %X\n",request);
			static pthread_mutex_t accept_mutex = PTHREAD_MUTEX_INITIALIZER;
			pthread_mutex_lock(&accept_mutex);
			//printf("t3\n");
			int rc = FCGX_Accept_r(request);
			pthread_mutex_unlock(&accept_mutex);
			//printf("t4\n");
			//printf("t5\n");
			P{rc=INT{rc};}
			//printf("t6\n");
			if(rc<0){
				return 0;
			}
			/*FCGX_FPrintF(request->out,
"Content-type: text/html; charset=utf-8\r\n"
"\r\n"
"<head></head><body>");*/
			for(p=request->envp;p&&*p;p++){
				P{
					array a=STRING{*p}/"=";
					env[a[0]]=a[1..]*"=";
				}
			}

		}
		//werror("Request create done\n");
		if(rc<0){
			throw(({"FCGX_Accept_r fail.",backtrace()}));
			//XXX: free request
		}
		//werror("Request create done2\n");
	}
	void finish()
	{
		ASSERT(request!=0);
		C{
			FCGX_Request* request=(FCGX_Request*)(INT{request});
			//fprintf(stderr,"request reload finish: %X\n",request);
			FCGX_Finish_r(request);
		}
	}
	void destroy()
	{
		ASSERT(request!=0);
		C{
			FCGX_Request* request=(FCGX_Request*)(INT{request});
			//fprintf(stderr,"request reload destroy: %X\n",request);
			//printf("%X\n",(void*)request);
			//FCGX_Finish_r(request);
			free((void*)request);
		}
	}
	void write(string s,mixed...extra)
	{
		ASSERT(request!=0);
		//werror("Request write ...\n");
		s=sprintf(s,@extra);
		//werror("Request write %s(%d)\n",s,sizeof(s));
		C{
			//printf("z\n");
			FCGX_Request* request=(FCGX_Request*)(INT{request});
			//fprintf(stderr,"request reload write: %X\n",request);
			//printf("y\n");
			//printf("request=%X\n",(void*)request);
			//printf("request->out=%X\n",(void*)(request->out));
			/*if(request==0){
			  printf("request is null: %X\n",request);
			  exit(1);
			  }*/
			if(request->out)
				FCGX_FPrintF(request->out,"%s",STRING{s});
			else
				printf("%s",STRING{s});
			//printf("x\n");
		}
		//werror("Request write done\n");
	}
	int getchar()
	{
		int res;
		C{
			//printf("z\n");
			FCGX_Request* request=(FCGX_Request*)(INT{request});
			int c=FCGX_GetChar(request->in);
			P{res=INT{c};}
		}
		return res;

	}
}

void FCGX_Init()
{
	Cross.INCLUDE(Request.cross_c_include);
	Cross.CC(Request.cross_c_cc);
	C{
		FCGX_Init();
	}
}
