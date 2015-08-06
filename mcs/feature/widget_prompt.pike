MIXIN Session{
	extern Widget curr_widget;
	private Widget prompt_panel;
	private string prompt_panel_tag;
	private Widget list_panel;
	private Widget delete_on_cancel;
	private int list_panel_height;
	private int prompt_height;
	private mapping widget2info=WIDGETD->setup_widget2info(([]));
	//extern Widget horizontal_panel(array|void items);
	//extern Widget text(string data,string|function|array|void click_cmd,string|void data_default);
	//extern Widget button(string text,string|function|array click_cmd,string|void data_default);
	extern int command(string cmd,array args);
	void _prompt(Widget w)
	{
		widget2info[w]=curr_prompt_panel();
		if(curr_widget){
			if(list_panel){
				werror("list_panel_height=%d\n",list_panel_height);
				werror("prompt_height=%d\n",prompt_height);
				list_panel->set_height(list_panel_height-prompt_height);
				prompt_panel->set_height(prompt_height);
			}
			if(prompt_panel_tag)
				curr_widget->clear_panels((<prompt_panel_tag>));
			prompt_panel->clear_panels();
			//prompt_panel->mark(0,(<"test">));
			prompt_panel->show();
			werror("sizeof prompt_panel->items=%d\n",sizeof(prompt_panel->items));
			prompt_panel->add(w);
		}
	}
	void prompt(Widget|string w)
	{
		if(stringp(w)){
			Widget res=WIDGETD->horizontal_panel(({WIDGETD->text(w)}));
			res->add(WIDGETD->button("确定","cancel_prompt "+res->id));
			w=res;
		}
		int done;
		if(prompt_panel==0&&curr_widget){
			mixed p=curr_widget->find_widget((<"prompt_panel">));
			if(objectp(p)){
				p=(<p>);
			}
			
			if(p){
				foreach(p;Widget pp;int one){
					array a=set_prompt_panel(pp,0);
					_prompt(w);
					set_prompt_panel(@a);
					done=1;
				}
			}else{
				throw(({"没有找到 prompt_panel",backtrace()}));
			}
		}
		if(!done)
			_prompt(w);
	}
	void reprompt(Widget w,function|Widget|string f)
	{
		if(w==0){
			if(functionp(f))
				f();
			else
				prompt(f);
		}
		if(widget2info[w]){
			array a=set_prompt_panel(@widget2info[w]);
			if(functionp(f))
				f();
			else
				prompt(f);
			set_prompt_panel(@a);
		}
	}
	PUBLIC cancel_prompt(Widget w,int|void delete_flag)
	{
		if(curr_widget){
			if(widget2info[w]){
				array a=set_prompt_panel(@widget2info[w]);

				if(list_panel){
					list_panel->set_height(list_panel_height);;
					prompt_panel->set_height(0);;
				}
				if(prompt_panel_tag)
					curr_widget->clear_panels((<prompt_panel_tag>));
				prompt_panel->clear_panels();
				prompt_panel->hide();
				if(delete_flag&&delete_on_cancel){
					delete_on_cancel->father->delete(search(delete_on_cancel->father->items,delete_on_cancel),1);
				}
				set_prompt_panel(@a);
			}else if(all_constants()["THIS_WORKFLOWRESOLVERD"]){
				all_constants()["THIS_WORKFLOWRESOLVERD"]->this_workflowresolver()->pop_view();
			}else if(cancel_prompt_handler){
				return command(cancel_prompt_handler,({w,delete_flag}));
			}
		}
	}
	PUBLIC prompt_in(Widget w,string tag,string cmd,mixed ... args)
	{
		array a=set_prompt_panel(w,tag);
		command(cmd,args);
		set_prompt_panel(@a);
	}
	private array curr_prompt_panel()
	{
		array res=({prompt_panel,prompt_panel_tag,delete_on_cancel,list_panel,prompt_height,list_panel_height});
		return res;
	}
	array set_prompt_panel(Widget panel,string tag,Widget|void _delete_on_cancel,Widget|void _list_panel,int|void height,int|void _list_panel_height)
	{
		array res=({prompt_panel,prompt_panel_tag,delete_on_cancel,list_panel,prompt_height,list_panel_height});
		prompt_panel=panel;
		prompt_panel_tag=tag;
		list_panel=_list_panel;
		delete_on_cancel=_delete_on_cancel;
		if(list_panel){
			if(_list_panel_height){
				list_panel_height=_list_panel_height;
			}else{
				list_panel_height=list_panel->height;
			}
		}
		werror("set prompt_height to %d\n",height);
		prompt_height=height;
		return res;
	}
	private string cancel_prompt_handler;
	void set_cancel_prompt_handler(string cmd)
	{
		cancel_prompt_handler=cmd;
	}
}