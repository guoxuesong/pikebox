CONF(VIEWSTACK_LINE_HEIGHT,24);
CONF(VIEWSTACK_USERINFO_WIDTH,120);
CONF(VIEWSTACK_STACKPANEL_WIDTH,-1-VIEWSTACK_USERINFO_WIDTH);
MIXIN Session{
	extern object add_syncer(object syncer);
	private array view_stack=({});
	private Widget error_panel=WIDGETD->horizontal_panel()->mark("error_prompt");
	private Widget stack_panel=WIDGETD->horizontal_panel()->set_height(VIEWSTACK_LINE_HEIGHT,100);
	private Widget userinfo_panel=WIDGETD->horizontal_panel()->set_height(VIEWSTACK_LINE_HEIGHT,100)->set_width(VIEWSTACK_USERINFO_WIDTH,100);

	private Widget view_panel=WIDGETD->vertical_panel(({WIDGETD->text("DEBUG")}));
	private Widget curr_view=WIDGETD->vertical_panel(({error_panel,WIDGETD->horizontal_panel(({WIDGETD->horizontal_panel(({stack_panel}))->set_width(VIEWSTACK_STACKPANEL_WIDTH,100),userinfo_panel})),view_panel}));
	private void update_userinfo_panel()/*{{{*/
	{
		userinfo_panel->clear_panels();
		string s=THIS_SESSIOND->this_session()->this_player()->name;
		userinfo_panel->add(WIDGETD->field(s)->set_width(VIEWSTACK_USERINFO_WIDTH,100));
	}/*}}}*/
	private void update_stack_panel()/*{{{*/
	{
		object stack=stack_panel;
		stack->clear_panels();
		stack->add(WIDGETD->text("您位于："));
		/*if(view_stack[0]->namecn!="首页"){
			stack->add(WIDGETD->text("首页",reset_view)->mark(0,(<"path">)));
			stack->add(WIDGETD->text(" >> "));
		}*/
		foreach(view_stack,object a){
			string dispname="-";
			if(a->namecn){
				dispname=a->namecn;
			}
			stack->add(WIDGETD->text(dispname,Function.curry(lambda(Widget curr){
				int n=sizeof(view_stack);
				for(int i=0;i<n&&top_view()!=curr;i++){
					pop_view();
				}
				})(a))->mark(0,(<"path">)));
			if(a!=view_stack[-1]){
				stack->add(WIDGETD->text(" >> "));
			}
		}
	}/*}}}*/
	Widget query_curr_view()/*{{{*/
	{
		return curr_view;
	}/*}}}*/
	void reset_view(int|void skip_update)/*{{{*/
	{
		view_stack=({});
		view_panel->clear_panels();
		error_panel->clear_panels();
		if(!skip_update){
			update_userinfo_panel();
			update_stack_panel();
		}
	}/*}}}*/
	void push_view(Widget w,string daemon,string viewname){/*{{{*/
		if(w){
			error_panel->clear_panels();
			werror("PUSH_VIEW(%s:%s)\n",daemon,viewname);
			werror("PUSH_VIEW: size0=%d\n",sizeof(view_stack));
			view_stack+=({w});
			foreach(view_panel->items,Widget ww){
				ww->hide();
			}
			view_panel->add(w);
			werror("PUSH_VIEW: size=%d\n",sizeof(view_stack));
		}
		update_userinfo_panel();
		update_stack_panel();
		//THIS_SESSIOND->this_session()->show(w,"push_view: "+daemon+" "+viewname);
	}/*}}}*/
	object top_view(){return (({0})+view_stack)[-1];}
	object pop_view(int|void skip_update){/*{{{*/
		ASSERT(sizeof(view_stack));
		werror("POP_VIEW\n");
		object res=view_stack[-1];
		view_stack=view_stack[..<1];
		view_panel->delete(sizeof(view_panel->items)-1,1,1);
		if(sizeof(view_panel->items))
			view_panel->items[-1]->show();
		werror("POP_VIEW: size=%d\n",sizeof(view_stack));
		/*
		if(sizeof(view_stack))
			THIS_SESSIOND->this_session()->show(view_stack[-1],"pop_view");
		else
			THIS_SESSIOND->this_session()->show(WIDGETD->text(""),"pop_view");
		*/
		if(!skip_update){
			update_userinfo_panel();
			update_stack_panel();
		}
		return res;
	}/*}}}*/
	int query_view_level(){ return sizeof(view_stack);}
}
