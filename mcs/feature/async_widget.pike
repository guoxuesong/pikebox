#include <async_widget.h>
MIXIN Session{
	int async_widgetp(mixed f)/*{{{*/
	{
		if(functionp(f)){
			mixed t=_typeof(f);
			string s=sprintf("%O",t);
			if(search(s,ASYNC_WIDGET_TYPE_PREFIX)>=0){
				return 1;
			}
		}
	}/*}}}*/
	extern void show(Widget w,string title);
	extern mapping request;
	PUBLIC look_widget(string cmd,string ig,mixed ... args)
	{
		return async_widget(cmd,@args);
	}

	PUBLIC async_widget(string cmd0,mixed...args) /*{{{*/
	{
		mapping r=request;
		
		void async_finish(Widget w)
		{
			ENTER(this);
			show(w,w->namecn||"-");
			if(r->async_finish)
				r->async_finish();
			LEAVE();
		};
		array a=cmd0/".";
		string cmd=a[0];
		string func=a[1..]*".";
		object ob;
		if(cmd==""){
			ob=this;
		}else{
			ob=all_constants()[cmd];
		}
		mixed f=ob[func];
		if(async_widgetp(f)){
			int err=f(async_finish,@(args||({})));
			if(err)
				return err;
			else
				return -1;
		}
		return 1;
	}/*}}}*/
}
