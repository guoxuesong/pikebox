MIXIN Session{
	extern mapping id2widget;
	//extern object this_session();
	extern Widget curr_widget;
	//extern Widget vertical_panel(array|void items);
	//extern Widget horizontal_panel(array|void items);
	//extern Widget button(string text,string|function click_cmd,string|void data_default);
	//extern Widget file_upload(string text,string|function click_cmd);
	//extern Widget checkbox(string name,int|void checked,multiset|void tags);
	extern void list_actions(object ob,string dispname,Widget prompt_widget,string tag,Widget object_widget,mixed ... args);
	//extern Widget text(string data,string|void|function click_cmd,string|void data_default);
	extern object add_syncer(object syncer);
	extern void set_widget_onchange(Widget widget,function(string,string:void) cb);
	extern Widget infinite_scroll_panel(object dbase,array full_path,int n,function create_widget,function(Widget:void)|void delete_notify,int|void height,int|void to_end);
	extern int command(string cmd,array args);
	extern mixed dbase_query(object dbase,array key);
	extern array set_prompt_panel(Widget panel,string tag,Widget|void _delete_on_cancel,Widget|void _list_panel,int|void height,int|void _list_panel_height);
	extern void prompt(Widget w);
	extern PUBLIC cancel_prompt(Widget w,int|void delete_flag);
	//extern object globald;
	private mapping widget2info=WIDGETD->setup_widget2info(([]));
	//multiset selected_items=(<>);
	multiset query_selected_items(Widget w){
		return widget2info[w]->selected_items;
	}
	void set_selected_items(Widget w,multiset m){
		widget2info[w]->selected_items=m;
	}
	int checkbox_all_flag;
	Widget curr_res;
private string count_selected_items(string olddata,string widget)/*{{{*/
{
	Widget w=WIDGETD->id2widget[widget];
	int n=sizeof(query_selected_items(w));
	werror("count_selected_items: w=%s\n",widget);
	if(n){
		return sprintf("总共 %d 个项目被选择",n);
	}else{
		return "";
	}
}/*}}}*/
	Widget create_checkbox_all()/*{{{*/
	{
		checkbox_all_flag=1;
		return WIDGETD->checkbox("infinite_list:checkbox")->mark(0,(<"infinite_list:checkbox">));
	}/*}}}*/
	Widget create_checkbox_item(string key)/*{{{*/
	{
		Widget res=WIDGETD->checkbox(key+":checkbox",query_selected_items(curr_res)[key],(<"infinite_list_checkbox">));
		set_widget_onchange(res,Function.curry(lambda(Widget curr_res,string old,string new){
				if((int)new)
					query_selected_items(curr_res)[key]=1;
				else
					query_selected_items(curr_res)[key]=0;
					})(curr_res));
		return res;
	}/*}}}*/
	Widget infinite_list(array fullpath,int size,function create_header,function create_widget,int width,int height,int header_height,int footer_height,int to_end,mapping(string:function|array)|array actions,mapping(string:function|array)|array|void noparam_actions,string|void listpanel_name,string|void promptpanel_name,int|void promptpanel_height,multiset|void begin_set/*,int|void clear*/)/*{{{*/
	{
		//selected_items=begin_set||(<>);
		Widget selected_counter=WIDGETD->field("");
		Widget action_panel;
		Widget header,footer;
		Widget list;
		Widget prompt;

		int t=time();

		float t1=time(t);
		footer=WIDGETD->horizontal_panel(({
					WIDGETD->horizontal_panel(({action_panel=WIDGETD->horizontal_panel(({}))}))->set_width(width-160),
					WIDGETD->space()->set_width(20),
					selected_counter->set_width(160),
					}));
		checkbox_all_flag=0;
		Widget res=WIDGETD->vertical_panel
			(({
			  header=create_header(),
			  }));
		object old=curr_res;
		curr_res=res;
		widget2info[res]=(["actions":actions,
				"noparam_actions":noparam_actions,
				"fullpath":fullpath,
				"list":0,
				"list_height":0,
				"prompt":0,
				"listpanel_name":listpanel_name,
				"promptpanel_name":promptpanel_name,
				"promptpanel_height":promptpanel_height,
				"action_panel":action_panel,
				"selected_items":begin_set||(<>),
				]);
		res->add(widget2info[res]->list=list=infinite_scroll_panel(GLOBALD,fullpath,size,
				  lambda(mixed ... args){object old=curr_res;curr_res=res;return create_widget(@args);curr_res=old;},
				  0,//collect_selected,
				  height,to_end));
		widget2info[res]->list_height=list->height;
		res->add(footer);
		res->add(widget2info[res]->prompt=prompt=WIDGETD->scroll_panel(""));
		int has_checkbox;
		if(checkbox_all_flag){
			has_checkbox=1;
		}
		/*if(has_checkbox){
			action_panel->add(selected_counter);
		}*/
		/*
		if(!clear){
			if(actions==0){
				actions=([]);
			}
			if(actions["打开"]==0){
				actions["打开"]=({lambda(object ob){
						Widget object_widget=THIS_SESSIOND->this_session()->curr_widget->find_widget(ob->key);//XXX: 效率问题
						Widget prompt_widget=object_widget->find_widget((<"item_prompt">));
						list_actions(ob,ob->key,prompt_widget,"item_prompt",object_widget);
						},(["type":"single"])});
			}
			if(noparam_actions==0){
				widget2info[res]->noparam_actions=noparam_actions=([]);
			}
			if(noparam_actions["返回上一级"]==0){
				noparam_actions["返回上一级"]=lambda(object ob){
						command("frame.pop_view",({}));
						};
			}
		}
		*/
		if(actions&&sizeof(actions)){
			action_panel->add(WIDGETD->text("对选中的项目："));
		}
		float t2=time(t);
		werror("infinite_scroll_panel time %f\n",t2-t1);
		if(listpanel_name)
			list->mark(listpanel_name);
		if(promptpanel_name)
			prompt->mark(promptpanel_name);
		if(header_height)
			header->set_height(header_height);
		if(footer_height)
			footer->set_height(footer_height);
		foreach(Array.arrayify(actions),mapping am){
			foreach(SortMapping.sort(am);string key;function|string|array f)
			{
				mapping info=(["type":"normal"]);
				if(arrayp(f)){
					[f,info]=f;
				}
				if(info->type=="normal")
					action_panel->add(WIDGETD->button(key,join(({"_infinite_list_action_",res->id,key})," ")));
				else if(info->type=="single")
					action_panel->add(WIDGETD->button(key,join(({"_infinite_list_action_single_",res->id,key})," ")));
				else if(info->type=="delete")
					action_panel->add(WIDGETD->button(key,join(({"_infinite_list_action_confirm_",res->id,key})," ")));
				else if(info->type=="confirm")
					action_panel->add(WIDGETD->button(key,join(({"_infinite_list_action_confirm2_",res->id,key})," ")));
				else if(info->type=="single_confirm")
					action_panel->add(WIDGETD->button(key,join(({"_infinite_list_action_single_confirm_",res->id,key})," ")));
				else if(info->type=="download")
					action_panel->add(WIDGETD->file_download(key,join(({"_infinite_list_action_",res->id,key})," ")));
			}
		}
		if(noparam_actions&&sizeof(noparam_actions)){
			//werror("NOPARAM_ACTIONS: %O\n",noparam_actions);
			action_panel->add(WIDGETD->text("其它操作："));
			foreach(Array.arrayify(noparam_actions),mapping am){
				foreach(SortMapping.sort(am);string key;function|string|array f)
				{
					mapping info=(["type":"normal"]);
					if(arrayp(f)){
						[f,info]=f;
					}
					if(info->type=="normal")
						action_panel->add(WIDGETD->button(key,join(({"_infinite_list_noparam_action_",res->id,key})," ")));
					else if(info->type=="single")
						action_panel->add(WIDGETD->button(key,join(({"_infinite_list_noparam_action_single_",res->id,key})," ")));
					else if(info->type=="download")
						action_panel->add(WIDGETD->file_download(key,join(({"_infinite_list_noparam_action_",res->id,key})," ")));
					/*else if(info->type=="upload"){
						action_panel->add(text(key+"："));
						action_panel->add(file_upload(key,join(({"_infinite_list_noparam_action_",res->id,key})," ")));
					}*/
				}
			}
		}
		Widget checkbox_all=res->find_widget((<"infinite_list:checkbox">));
		if(checkbox_all){
			set_widget_onchange(checkbox_all,
						lambda(string old,string new){
							set_selected_items(res,(<>));

							mapping info=widget2info[res];
							multiset m=curr_widget->find_widget((<"infinite_list_checkbox">));
							if(m){
								if(!multisetp(m))
									m=(<m>);
								/*foreach(m;Widget cb;int one){
									string key=(cb->name/":")[0];
									query_selected_items(res)[key]=(int)new;
									cb->set_data(new);
								}*/
								foreach(dbase_query(GLOBALD,info->fullpath),mapping m){
									if(!has_prefix(m->_id_,"group-"))
										query_selected_items(res)[m->_id_]=(int)new;
								}
								foreach(m;Widget w;int one){
									w->set_data(new);
								}
							}
						} 
						);
		}
		if(has_checkbox)
			add_syncer(SimpleSyncer(selected_counter,count_selected_items,res->id));
		curr_res=old;
		return res;
	}/*}}}*/
	Widget query_scroll_panel(Widget w){
		return widget2info[w]->list;
	}
	Widget query_action_panel(Widget w){
		return widget2info[w]->action_panel;
	}
	private void single(string cmd,string widget,string action,int accept_non)
	{
		Widget w=id2widget[widget];
		if(sizeof(query_selected_items(w))==1||accept_non&&sizeof(query_selected_items(w))==0){
			command(cmd,({widget,action}));
		}else if(sizeof(query_selected_items(w))>1){
			mapping info=widget2info[id2widget[widget]];
			info->list->set_height(info->list_height);
			array a=set_prompt_panel(info->prompt,0,0,info->list,/*info->promptpanel_height*/24);
			Widget res=WIDGETD->horizontal_panel(({"此操作只能对单个对象实施？"}));
			res->add(WIDGETD->button("确定",join(({"cancel_prompt",res->id})," ")));
			prompt(res);
			set_prompt_panel(@a);
		}else{
			mapping info=widget2info[id2widget[widget]];
			info->list->set_height(info->list_height);
			array a=set_prompt_panel(info->prompt,0,0,info->list,/*info->promptpanel_height*/24);
			Widget res=WIDGETD->horizontal_panel(({"请选择一个对象。"}));
			res->add(WIDGETD->button("确定",join(({"cancel_prompt",res->id})," ")));
			prompt(res);
			set_prompt_panel(@a);
		}
	}

	PUBLIC _infinite_list_action_single_(string widget,string action)
	{
		single("_infinite_list_action_",widget,action,0);
	}
	PUBLIC _infinite_list_noparam_action_single_(string widget,string action)
	{
		single("_infinite_list_noparam_action_",widget,action,1);
	}
	PUBLIC _infinite_list_action_single_confirm_(string widget,string action){
		single("_infinite_list_action_confirm2_",widget,action,0);
	}
	PUBLIC _infinite_list_action_confirm_(string widget,string action)/*{{{*/
	{
		mapping info=widget2info[id2widget[widget]];
		info->list->set_height(info->list_height);
		array a=set_prompt_panel(info->prompt,0,0,info->list,/*info->promptpanel_height*/24);
		Widget res=WIDGETD->horizontal_panel(({"确定删除？"}));
		res->add(WIDGETD->button("确定",join(({"_infinite_list_action_confirm_ok_",res->id,widget,action})," ")));
		res->add(WIDGETD->button("取消",join(({"cancel_prompt",res->id})," ")));

		prompt(res);
		set_prompt_panel(@a);
	}/*}}}*/
	PUBLIC _infinite_list_action_confirm2_(string widget,string action)/*{{{*/
	{
		mapping info=widget2info[id2widget[widget]];
		info->list->set_height(info->list_height);
		array a=set_prompt_panel(info->prompt,0,0,info->list,/*info->promptpanel_height*/24);
		Widget res=WIDGETD->horizontal_panel(({"确定要执行此操作？"}));
		res->add(WIDGETD->button("确定",join(({"_infinite_list_action_confirm_ok_",res->id,widget,action})," ")));
		res->add(WIDGETD->button("取消",join(({"cancel_prompt",res->id})," ")));

		prompt(res);
		set_prompt_panel(@a);
	}/*}}}*/
	PUBLIC _infinite_list_action_confirm_ok_(Widget w,string widget,string action)/*{{{*/
	{
		cancel_prompt(w);
		int err=command("_infinite_list_action_",({widget,action}));
		if(err<=0){
			set_selected_items(id2widget[widget],(<>));
			multiset m=curr_widget->find_widget((<"infinite_list_checkbox">));
			if(m){
				if(!multisetp(m))
					m=(<m>);
				foreach(m;Widget w;int one){
					if(w->data=="1")
						w->set_data("0");
				}
			}
		}
		return err;
	}/*}}}*/
	PUBLIC _infinite_list_action_(string widget,string action)/*{{{*/
	{
		Widget w=id2widget[widget];
		mapping info=widget2info[w];
		//set_prompt_panel(info->promptpanel_name,0,0,info->listpanel_name,info->promptpanel_height);
		function|string|array f;
		foreach(Array.arrayify(info->actions),mapping am){
			if(am[action]){
				f=am[action];
				break;
			}
		}
		if(f){
			mapping info2=(["type":"normal"]);
			if(arrayp(f)){
				[f,info2]=f;
			}
			if(sizeof(query_selected_items(w))==0){
				werror("_infinite_list_action_: nothing selected.\n");
			}
			werror("_infinite_list_action_ m=%O\n",dbase_query(GLOBALD,info->fullpath));
			werror("query_selected_items(w)=%O\n",query_selected_items(w));
			foreach(dbase_query(GLOBALD,info->fullpath),mapping m)
			{
				if(query_selected_items(w)[m->_id_]){
					info->list->set_height(info->list_height);
					array a=set_prompt_panel(info->prompt,0,0,info->list,info->promptpanel_height);
					if(functionp(f)){
						mixed tt=__get_first_arg_type(_typeof(f));
						if(tt==0||tt==ARGTYPE(string)){
							f(m->_id_,m,info->fullpath,GLOBALD);
						}else{
							object ob=dbase_query(GLOBALD,info->fullpath+({m->_id_}));
							if(ob){
								f(ob);
								if(ob->data==0){
									query_selected_items(w)[ob->key]=0;
								}
							}else{
								throw("infinite_list item is not object.\n");
								f(m->_id_,m,info->fullpath,GLOBALD);
							}
						}
					}else if(stringp(f)){
						array a=split(f," ");
						object ob=dbase_query(GLOBALD,info->fullpath+({m->_id_}));
						if(ob){
							//f(ob);
							command(a[0],a[1..]+({ob}));
							if(ob->data==0){
								query_selected_items(w)[ob->key]=0;
							}
						}else{
							throw("infinite_list item is not object.\n");
							command(a[0],a[1..]+({m->_id_}));
							//f(m->_id_,m,info->fullpath,GLOBALD);
						}
					}
						
					set_prompt_panel(@a);
				}
			}
		}else{
			werror("_infinite_list_action_: action not found\n");
		}
	}/*}}}*/
	PUBLIC _infinite_list_noparam_action_(string widget,string action,mixed ... args)/*{{{*/
	{
		mapping info=widget2info[id2widget[widget]];
		//set_prompt_panel(info->promptpanel_name,0,0,info->listpanel_name,info->promptpanel_height);
		function|string|array f/*=info->noparam_actions[action]*/;
		foreach(Array.arrayify(info->noparam_actions),mapping am){
			if(am[action]){
				f=am[action];
				break;
			}
		}
		if(f){
			mapping info2=(["type":"normal"]);
			werror("f=%O\n",f);
			if(arrayp(f)){
				[f,info2]=f;
			}
			info->list->set_height(info->list_height);
			array a=set_prompt_panel(info->prompt,0,0,info->list,info->promptpanel_height);
			werror("info->promptpanel_height=%d\n",info->promptpanel_height);
			if(functionp(f)){
				f(@args);
			}else{
			werror("f=%O\n",f);
				array a=split(f," ");
				command(a[0],a[1..]+args);
			}
			set_prompt_panel(@a);
		}else{
			werror("_infinite_list_action_: action not found\n");
		}
	}/*}}}*/
}
