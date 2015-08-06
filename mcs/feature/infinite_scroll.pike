Widget call_create_widget(function curr_create_widget,object ob,string key,mapping m,array path,object dbase){
	Widget item;
	mixed tt=__get_first_arg_type(_typeof(curr_create_widget));
	//werror("call_create_widget: tt=%O\n",_typeof(curr_create_widget));
	if(tt==0||tt==ARGTYPE(string)/*||tt==ARGTYPE(mixed)*/){
		item=curr_create_widget(key,m,path,dbase);
	}else{
		ASSERT_TRUE(ob,"not a object");
		ASSERT_TRUE(ob->data,"object has no data");
		mixed e=catch{
			item=curr_create_widget(ob);
		};
		if(e){
			master()->handle_error(e);
			item=WIDGETD->text(e[0]+" "+key);
		}
	}
	return item;
}

//int disable_update_scroll;

class InfiniteScrollSyncer(Widget w,mapping info,object session)
{
	int eof(){return 0;}
	void sync(int flag)/*{{{*/
	{
		info->something_happened=0;
		if(flag){
			werror("InfiniteScrollSyncer: skip\n");
			return;
		}
		mixed e;
		cache_begin();
		e=catch{
		Widget vp=w->items[0]->items[0];
		mixed a=/*info->father&&info->father->`->(info->path[-1])||*/session->dbase_query(info->dbase,info->path);
		if(a==0)
			a=({});
		Iterator i=get_iterator(a);
		a=BigArray.ArrayFromIterator(i,sizeof(a));
		werror("infinite_scroll sync: info=%O\n",info);
		array aa;
		int length=max(info->length,info->length_wanted);
		if(info->startpos+length-1<sizeof(a)){
			info->length=length;
			aa=a[info->startpos..info->startpos+length-1];
		}else{
			aa=a[<info->length_wanted-1..];
			info->startpos=sizeof(a)-info->length_wanted;
			info->length=info->length_wanted;
			if(info->startpos<0){
				info->startpos=0;
				info->length=sizeof(a);
			}
			//if(info->startpos!=0)
				//info->disable_update_scroll=0;
		}
		//werror("infinite_scroll: aa=%O\n",aa);
		mapping known=([]);
		array todelete=({});
		foreach(vp->items;int pos;Widget item){
			if(item->name){
				//werror("infinite_scroll: check: %s\n",item->name);
				if(array_query(aa,item->name)!=0){
					known[item->name]=item;
					//werror("infinite_scroll: known: %s\n",item->name);
				}else{
					werror("todelete %d\n",pos);
					todelete+=({pos});
				}
			}
		}
		foreach(reverse(todelete),int pos){
			vp->delete(pos);
			info->something_happened=1;
		}
		mapping known_in_lru=([]);
		foreach(vp->lru->items;int pos;Widget item){
			if(item->name){
				known_in_lru[item->name]=item;
			}
		}
		foreach(aa;int pos;mapping b){
			if(b->_id_==0){
				werror("id=0: aa=%O\n",aa);
			}
			string key=b->_id_;mapping val=b;
			if(known[key]==0){
				Widget item;
				if(!known_in_lru[key]){
					//werror("infinite_scroll: miss: %s\n",key);
					object ob=info->constructor&&info->constructor(key,1);
					item=call_create_widget(info->create_widget,ob,key,val,info->path,info->dbase);
					item->mark(key);
				}else{
					item=known_in_lru[key];
				}
				vp->insert(pos,item);
				known[key]=item;
				info->something_happened=1;
			}
		}
		foreach(aa;int pos;mapping b){
			if(vp->items[pos]->name!=b->_id_){
				foreach(vp->items;int pos2;Widget w){
					if(w->name==b->_id_){
						vp->insert(pos,w);
						info->something_happened=1;
						break;
					}
				}
			}
		}
		//if(!info->disable_update_scroll){
			//w->update_scroll();
		//}
		};
		//info->disable_update_scroll=0;

		cache_end();
		if(e){
			throw(e);
		}
	}/*}}}*/
};
private class LableWidget(string key){
	mapping data=(["_id_":key]);
}
MIXIN Session{
	extern mapping id2widget;
	//extern Widget scroll_panel(Widget|string item,string|function|void click_cmd);
	//extern Widget vertical_panel(array|void items);
	extern void refresh();
	extern object add_syncer(object syncer);
	private mapping widget2info=WIDGETD->setup_widget2info(([]));
	extern mixed dbase_query(object dbase,array key);
	extern mapping request;
	//extern object globald;
	//extern object this_session();
	Widget infinite_scroll_panel(object dbase,array full_path,int n,function create_widget,function(Widget:void)|void delete_notify,int|void height,int|void to_end)
	{
		float t1,t2;
		mixed e;
		Widget res;
		cache_begin();
		e=catch{
			int t0=time();
		t1=time(t0);
		mapping m=THIS_SESSIOND->this_session()->find_type(GLOBALD,full_path);
		werror("find_type return %O\n",m);
		program curr_constructor;
		object father;
		foreach(m;mixed t;[program pp,object ob]){
			curr_constructor=pp;
			father=ob;
			break;
		}
		t2=time(t0);
		werror("get_constructor time %f\n",t2-t1);
		werror("infinite_scroll_panel: full_path=%O\n",full_path);
		werror("infinite_scroll_panel: father=%O\n",father);
		/*if(father){
			werror("infinite_scroll_panel: father[%s]=%O\n",full_path[-1],father[full_path[-1]]);
			if(full_path[-1]=="files"){
			werror("infinite_scroll_panel: father->%s=%O\n",full_path[-1],father->files);
			}
		}*/
		t1=time(t0);
		mixed a0=/*father&&father->`->(full_path[-1])||*/dbase_query(dbase,full_path); //list_unread_mails
		t2=time(t0);
		if(a0==0)
			a0=({});
		werror("dbase_query_full_path time %f\n",t2-t1);
		werror("infinite_scroll_panel: size=%d\n",sizeof(a0));
		//werror("infinite_scroll_panel: a0=%O\n",a0);
		t1=time(t0);
		Iterator i=get_iterator(a0);
		mixed a=BigArray.ArrayFromIterator(i,sizeof(a0));
		t2=time(t0);
		werror("array_from_iterator time %f\n",t2-t1);
		//werror("m=%O",m);
		//werror("infinite_scroll_panel: a=%O",a);
		werror("infinite_scroll_panel: n=%O\n",n);
		//if(a==0){
			//werror("a1=%O",dbase->query(full_path[..<1]));
		//}
		t1=time(t0);
		array b;
		if(!to_end){
			werror("b=a[..n-1]\n");

			b=a[..n-1];
		}else{
			werror("b=a[<n-1..]\n");

			b=a[<n-1..];
		}
		werror("infinite_scroll_panel: load items: sizeof(b)=%d\n",sizeof(b));
		//werror("b=%O\n",b);
		werror("size=%d\n",sizeof(b));
		t2=time(t0);
		werror("a_to_b time %f\n",t2-t1);
		t1=time(t0);
		float create_mail_time=0.0;
		float call_create_widget_time=0.0;
		foreach(b;int i;mixed v)
		{
			float t1,t2;
			ASSERT_TRUE(v->_id_,a0);
			t1=time(t0);
			object ob;
			if(!has_prefix(v->_id_,"group-"))
				ob=curr_constructor&&curr_constructor(v->_id_,1);
			else
				ob=LableWidget(v->_id_);
			t2=time(t0);
			create_mail_time+=t2-t1;
			//werror("v->_id_=%O\n",v->_id_);
			if(ob) ASSERT(ob->data);
			t1=time(t0);
			b[i]=call_create_widget(create_widget,ob,v->_id_,v,full_path,dbase);
			t2=time(t0);
			call_create_widget_time+=t2-t1;
			//werror("call_create_widget: ob->data=%O,v=%O\n",ob->data,v);
			b[i]->mark(v->_id_);
		}
		t2=time(t0);
		werror("construct time %f\n",t2-t1);
		werror("create_mail time time %f\n",create_mail_time);
		werror("call_create_widget time time %f\n",call_create_widget_time);
		Widget vp=WIDGETD->vertical_panel(b);
		Widget vp1=WIDGETD->vertical_panel()->hide();
		vp->set_lru_panel(vp1,2048);
		res=WIDGETD->scroll_panel(WIDGETD->vertical_panel(({vp,vp1})),"_infinite_scroll_panel_sync_");
		widget2info[res]=([
				"dbase":dbase,
				"path":full_path,
				"startpos":to_end?max(sizeof(a)-n,0):0,
				"length":sizeof(b),
				"length_wanted":n,
				"length_limit":2048,
				"constructor":curr_constructor,
				//"father":father,
				"create_widget":create_widget,
				"delete_notify":delete_notify,
				"syncer":0,
				]);
		InfiniteScrollSyncer syncer=InfiniteScrollSyncer(res,widget2info[res],THIS_SESSIOND->this_session());
		add_syncer(syncer);
		widget2info[res]->syncer=syncer;

//werror("info0=%O\n",widget2info[res]);
		if(height){
			res->_set_init_height_internal_(height);
			res->_set_height_internal_(height);
		}
		if(to_end){
			res->_set_init_scroll_to_bottom_internal_(1);
			res->_set_scroll_to_bottom_internal_(1);
		}
		};
		cache_end();
		if(e)
			throw(e);
			
		return res;
	}
	PUBLIC _infinite_scroll_locate_(string widget,string item)
	{
		Widget w=id2widget[widget];
		mapping info=widget2info[w];
		mixed a=/*info->father&&info->father->`->(info->path[-1])||*/dbase_query(info->dbase,info->path);
		if(a==0)
			a=({});
		Iterator i=get_iterator(a);
		a=BigArray.ArrayFromIterator(i,sizeof(a));
		for(int i=0;i<sizeof(a);i++){
			if(a[i]->_id_==item){
				info->startpos=i;
				info->length=info->length_wanted;
				if(i!=0){
					info->startpos--;
					info->syncer->sync();
					Widget vp=w->items[0]->items[0];
					vp->items[-1]->reset_scroll_position(w);
					vp->items[-1]->adjust_scroll_position(w,"+",vp->items[0]);
					//ww->adjust_scroll_position(w,"+",ww);
				}else{
					info->syncer->sync();
				}
				break;
			}
		}
		//w->update_scroll();
	}

	PUBLIC _infinite_scroll_panel_sync_(string widget,int upper,int height,int lower,string|void debug_info)
	{
		if(height==0){
			Widget w=id2widget[widget];
			mapping info=widget2info[w];
			//info->disable_update_scroll=1;
			return 0;
		}
		int something_happened;
		mixed e;
		cache_begin();
		e=catch{
		Widget w=id2widget[widget];
		ASSERT(w);
		ASSERT(w->type=="scroll_panel");
		ASSERT(sizeof(w->items)==1);
		ASSERT(sizeof(w->items[0]->items)==2);
		Widget vp=w->items[0]->items[0];
		mapping info=widget2info[w];
		//info->disable_update_scroll=1;
		info->syncer->sync();
//werror("_infinite_scroll_panel_sync_: info=%O\n",info);
		mixed a=/*info->father&&info->father->`->(info->path[-1])||*/dbase_query(info->dbase,info->path);
		if(a==0)
			a=({});
		/*if(info->startpos+info->length_wanted>=sizeof(a)){
			info->startpos=sizeof(a)-info->length_wanted;
			info->length=info->length_wanted;
		}*/
		Iterator i=get_iterator(a);
		a=BigArray.ArrayFromIterator(i,sizeof(a));
		array aa;
		aa=a[info->startpos..info->startpos+info->length-1];
		//werror("infinite_scroll: aa=%O\n",aa);

		if(height==0)
			height=1;

		if(upper<0) upper=0;
		if(lower<0) lower=0;

		int upper_n=info->length*upper/(upper+height+lower);
		int lower_n=info->length*lower/(upper+height+lower);
		int middle_n=info->length*height/(upper+height+lower);


		int upper_want;
		int lower_want;
		if(upper_n<lower_n){
			upper_want=max(middle_n+1,upper_n);
		}else if(upper_n>lower_n){
			lower_want=max(middle_n+1,lower_n);
		}else{
			upper_want=max(middle_n/2+1,upper_n);
			lower_want=max(middle_n/2+1,lower_n);
		}



//werror("length=%d\n",info->length);
//werror("upper_n=%d,lower_n=%d,middle_n=%d\n",upper_n,lower_n,middle_n);

		//int upper_total=info->startpos;
		//int lower_total=sizeof(a)-(info->startpos+info->length);

//werror("upper_total=%d\n",upper_total);
//werror("lower_total=%d\n",lower_total);

		//int upper_want=middle_n+middle_n*2*upper_total/sizeof(a);
		//int lower_want=middle_n+middle_n*2*lower_total/sizeof(a);
//werror("upper_want=%d\n",upper_want);
//werror("lower_want=%d\n",lower_want);
		//info->syncer->sync();

		mapping known_in_lru=([]);
		foreach(vp->lru->items;int pos;Widget item){
			if(item->name){
				known_in_lru[item->name]=item;
			}
		}

		if(upper_n<upper_want/2||upper_want<10||lower_n<lower_want/2||lower_want<10){
			//int added_count;

			//if(info->length<=info->length_wanted*2){
				while(upper_n<upper_want){
					if(info->startpos<=0){
						break;
					}
					info->startpos--;
					info->length++;
					upper_n++;
					Widget ww;
					if(known_in_lru[a[info->startpos]->_id_]==0){
						object ob=info->constructor&&info->constructor(a[info->startpos]->_id_,1);
						ww=call_create_widget(info->create_widget,ob,a[info->startpos]->_id_,a[info->startpos],info->path,info->dbase);
						ww->mark(a[info->startpos]->_id_);
						//ww->adjust_scroll_position(w,"+",ww);
						//vp->insert(0,ww);
					}else{
						ww=known_in_lru[a[info->startpos]->_id_];
					}
					vp->adjust_scroll_position_and_insert(w,0,ww);
					something_happened=1;
				}
				while(lower_n<lower_want){
					if(info->startpos+info->length>=sizeof(a)){
						break;
					}
					//werror("info=%O\n",info);
					object ob=info->constructor&&info->constructor(a[info->startpos+info->length]->_id_,1);
					Widget ww=call_create_widget(info->create_widget,ob,a[info->startpos+info->length]->_id_,a[info->startpos+info->length],info->path,info->dbase);
					ww->mark(a[info->startpos+info->length]->_id_);
					vp->add(ww);
					something_happened=1;
					info->length++;
					lower_n++;
				}
				while(info->length>info->length_limit){
					if(upper_n>lower_n){
						info->startpos++;
						info->length--;
						upper_n--;
						if(info->delete_notify){
							int err=info->delete_notify(vp->items[0]);
							if(err)
								break;
						}
						vp->adjust_scroll_position_and_delete(w,0);
						something_happened=1;
					}
					else{
						info->length--;
						lower_n--;
						if(info->delete_notify){
							int err=info->delete_notify(vp->items[-1]);
							if(err)
								break;
						}
						vp->delete(sizeof(vp->items)-1);
						something_happened=1;
					}
				}
			//}
				/*
			while(upper_n>upper_want){
				if(info->length<=info->length_wanted)
					break;
				if(info->startpos>=sizeof(a)){
					break;
				}
				info->startpos++;
				info->length--;
				upper_n--;
				if(info->delete_notify){
					int err=info->delete_notify(vp->items[0]);
					if(err)
						break;
				}
				vp->adjust_scroll_position_and_delete(w,0);
				//vp->adjust_scroll_position(w,"-",vp->items[0]);
				//vp->delete(0);
			}
			while(lower_n>lower_want){
				if(info->length<=info->length_wanted)
					break;
				if(info->length<=0){
					break;
				}
				info->length--;
				lower_n--;
				if(info->delete_notify){
					int err=info->delete_notify(vp->items[-1]);
					if(err)
						break;
				}
				vp->delete(sizeof(vp->items)-1);
			}
			*/
		}
		//info->disable_update_scroll=1;
		refresh();
		if(something_happened||info->something_happened)
			w->update_scroll();
		//info->disable_update_scroll=0;
		};
		cache_end();
		if(e)
			throw(e);
		this->write("\n");
		//request->async_finish(); //XXX: this not works, why??
		//return -1;
	}
}
