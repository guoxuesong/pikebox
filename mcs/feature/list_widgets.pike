#include <list_widgets.h>
MIXIN Session{
	extern object load_command(string cmd);
	extern void show(Widget w,string title);
	//extern mixed apply(string cmd,function f,array...args);
	int list_widgetsp(mixed f)/*{{{*/
	{
		if(functionp(f)){
			mixed t=_typeof(f);
			string s=sprintf("%O",t);
			if(search(s,LIST_WIDGETS_TYPE_PREFIX)>=0){
				return 1;
			}
		}
	}/*}}}*/
	mapping list_widgets(string cmd0,mixed...args) /*{{{*/
	{
		array a=cmd0/".";
		string cmd=a[0];
		string func=a[1..]*".";
		//if(func=="")
			//func="_list_widgets";
		object ob;
		if(cmd==""){
			ob=this;
		}else if(all_constants()[cmd]==0){
			werror("all_constants=%O\n",all_constants());
			ob=load_command(cmd);
		}else{
			ob=all_constants()[cmd];
		}
		mixed f=ob[func];
		if(list_widgetsp(f)/*||func=="_list_widgets"*/){
			return f(@(args||({})));
		}
	}/*}}}*/
	PUBLIC look_widget(string cmd,string key,mixed ... args)
	{
		mapping m=list_widgets(cmd,@args);
		werror("%O",m);
		show(m[key],key);
	}
}