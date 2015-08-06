MIXIN Session{
	extern Widget curr_widget;
	extern int cmd_step;
	private multiset syncers=(<>);
	private mapping syncer2cmd_step=set_weak_flag(([]),Pike.WEAK_INDICES);
	//private multiset post_syncers=(<>);
	object add_syncer(object syncer){
		syncers[syncer]=1;syncer2cmd_step[syncer]=cmd_step;return syncer->w;
	}
	//object add_post_syncer(object syncer){post_syncers[syncer]=1;return syncer->w;}
	void delete_syncer(object syncer){
		//werror("remove syncer.\n");
		syncers[syncer]=0;
	}
	//void delete_post_syncer(object syncer){post_syncers[syncer]=0;}
	multiset query_syncers(){return syncers;}
	//multiset query_post_syncers(){return post_syncers;}
	void reset_syncers(){syncers=(<>);/*post_syncers=(<>);*/}
void update_syncers()/*{{{*/
{
	//werror("DEBUG: update_syncers %O\n",map(query_syncers(),`->,"f"));
	//master()->handle_error(({"DEBUG",backtrace()}));
	mixed e;
//	cache_begin();
	e=catch{
	multiset done=(<>);
	//multiset m1=copy_value(query_post_syncers());
	multiset widgets_alive=(<>);
	void walk(Widget w)
	{
		widgets_alive[w]=1;
		foreach(w->items,Widget ww){
			walk(ww);
		}
	};
	if(curr_widget){
		walk(curr_widget);
		foreach(query_syncers();object syncer;int one){
			if(widgets_alive[syncer->w]==0){
				delete_syncer(syncer);
				//werror("DEBUG: delete %O\n",syncer->f);
				//delete_post_syncer(syncer);
			}
		}
	}
	multiset m=copy_value(query_syncers());
	//foreach(({m,m1}),multiset m){
		while(sizeof(m)){
			array vals=indices(syncers);
			array keys=map(vals,lambda(object ob){return ob->priority;});
			sort(keys,vals);
			foreach(vals,object syncer){
				syncer->sync(cmd_step==syncer2cmd_step[syncer]);
				//werror("DEBUG: sync %O\n",syncer->f);
				done[syncer]=1;
				if(syncer->eof()){
					delete_syncer(syncer);
				}
			}
			m=query_syncers()-done;
		}
	//}
	};
//	cache_end();
	if(e){
		throw(e);
	}
}/*}}}*/
}

/* 关于syncer的备注：

   syncer的机制设计，应该确保所有命令在执行时，得到的数据是最新的数据。

   这包括两个部分，一是widget里的数据，一是GLOBALD或者WorkflowRuntime里的数据。

   关于widget里的数据，现有的机制已经保障从前端将数据同步回来。

   关于GLOBALD或者WorkflowRuntime里的数据，这意味着synver不能用于将widget里的数据同步到runtime，只能用set_widget_onchange来实现。

   */

DAEMON:
#define DEBUG/*{{{*/

#define ABORT() throw(({"ERROR\n",backtrace()}))
#define assert(EXP) ((EXP)||ABORT())

#ifdef DEBUG
#define ASSERT(EXP) assert(EXP)
#endif/*}}}*/

class TinySyncer(Widget w,function f,mixed ... args){
	array bt=backtrace();
	int priority;
	int eof(){return 0;}
	object sync()
	{
		mixed e=catch{
			mixed v=f(w,@args);
		};
		if(e){
			master()->handle_error(({"Syncer sync error, dumping backtrace of create:",bt}));
			throw(e);
		}
		return this;
	}
}

class SimpleSyncer(Widget w,function f,mixed ... args){
	array bt=backtrace();
	int priority;
	int eof(){return 0;}
	object sync()
	{
		mixed e=catch{
			mixed v=f(w->data,@args);
			if(!zero_type(v)&&(intp(v)||stringp(v))){
				if(w->data!=(string)v)
					w->set_data((string)v);
			}
		};
		if(e){
			master()->handle_error(({"Syncer sync error, dumping backtrace of create:",bt}));
			throw(e);
		}
		return this;
	}
}

/*class WorkflowSyncer{
	inherit SimpleSyncer;
	mapping runtime;
	string key;
	string var;
	mapping prop;
	int active_flag;
	int depend_flag;
	constant DP_ARGS=1;
	constant DP_SELF=2;
}*/

class WidgetSyncer{
	Widget w;
	int priority;
	array bt;
	object dbase;
	array path;
	function|mapping create_widget;
	int noeof;
	function(array,array|mapping:array)|mapping sorter;
	private array keep_order(array items,array|mapping m)
	{
		mapping name2pos=([]);
		if(arrayp(m)){
			foreach(m;int pos;mapping info){
				name2pos[info->_id_]=pos;
			}
			array vals=({});
			foreach(items,Widget w){
				vals+=({name2pos[w->name]});
			}
			sort(vals,items);
		}
		return items;
	}
	void create(Widget _w,object _dbase,array fullpath,function|mapping _create_widget,function(array,array|mapping:array)|void _sorter,int|void _noeof)
	{
		bt=backtrace();
		sorter=_sorter;
		noeof=_noeof;
		if(sorter==0)
			sorter=keep_order;
		ASSERT(_create_widget);
		w=_w;dbase=_dbase;create_widget=_create_widget;
		ASSERT(fullpath[0]=="/");
		path=fullpath;
		/*
		if(_path[0]=="/"){
			path=_path;
		}else{
			ASSERT(dbase->curr_namespace);
			path=({"/",dbase->curr_namespace})+_path;
		}
		*/
		/*if(Array.all(path,stringp)&&!noeof){
			if(dbase->query(path)==0){
				array p=path[..<1];
				while(dbase->query(p)==0){
					p=p[..<1];
				}
				werror("p=%O\n",p);
				mapping m=DBASEITEMD->find_type(dbase,p);
				if(sizeof(m)){
					werror("ERROR: 找不到 %s(%s)\n",(map((array)m,lambda(mixed t){return sprintf("%O",t);})*"|"),path[sizeof(p)]);
				}else{
					mapping mm=DBASEITEMD->find_type(dbase,p[..<1]);
					if(mm){
						werror("ERROR: 找不到 %s(%s) 的 %s\n",(map((array)mm,lambda(mixed t){return sprintf("%O",t);})*"|"),path[sizeof(p)-1],path[sizeof(p)]);
					}
				}
				werror("ERROR: path not found %O\n",path);
				ABORT();
			}
		}
		*/
	}
	int eof()
	{
		if(noeof)
			return 0;
		/*if(zero_type(dbase->query(path)))
			return 1;*/
	}
	/*
	object set_noeof()
	{
		noeof=1;
		return this;
	}
	*/
	object sync()
	{
		mixed e=catch{
			array curr_path=map(path,lambda(mixed s){
					if(functionp(s)){
						return s();
					}else{
						return s;
					}
					});
			werror("path=%O\n",curr_path);
			mapping m=THIS_SESSIOND->this_session()->find_type(dbase,curr_path);
			werror("find_type return %O\n",m);
			function curr_create_widget;
			function curr_sorter;
			program curr_constructor;
			object father;
			curr_create_widget=create_widget;
			curr_sorter=sorter;
			//werror("%O",m);
			foreach(m;mixed t;[program pp,object ob]){
				curr_constructor=pp;
				father=ob;
				if(mappingp(create_widget)&&create_widget[t]){
					if(t&&mappingp(create_widget)){
						curr_create_widget=create_widget[t];
					}else{
						curr_create_widget=create_widget;
					}
					if(t&&mappingp(sorter)){
						curr_sorter=sorter[t];
					}else{
						curr_sorter=sorter;
					}
					break;
				}
			}
			if(w->type=="button"||w->type=="text"||w->type=="html"||w->type=="htmlbtton"){
				mixed v=father&&father->`->(curr_path[-1])||THIS_SESSIOND->this_session()->dbase_query(dbase,curr_path);
				if(zero_type(v)){
					if(w->data!="")
						w->set_data("");
				}else if(!zero_type(v)&&(intp(v)||stringp(v))){
					if(w->data!=(string)v)
						w->set_data((string)v);
				}
				return this;
			}
			/*
			foreach(type2dbasepath;mixed t;array a){
				int found=0;
				foreach(a,[object dbase1,array path1,program p1]){
					//werror("path1=%O\n",path1);
					if(dbase1==dbase&&path_equal(path1,curr_path,loopflags[t])){
						if(mappingp(create_widget)){
							create_widget=create_widget[t];
						}
						if(mappingp(sorter)){
							sorter=sorter[t];
						}
						found=1;
						break;
					}
				}
				if(found)
					break;
			}
			ASSERT(create_widget);
			if(!functionp(create_widget)){
				//werror("create_widget=%O\n",create_widget);
				//werror("path=%O\n",curr_path);
				foreach(type2dbasepath;mixed t;array a){
					foreach(a,[object dbase1,array path1,program p1]){
						if(path_equal(path1,curr_path,loopflags[t])&&dbase1!=dbase){
							werror("ERROR: 找到了注册路径，但 add_syncer 中指定的dbase对象与定义 %O 时使用的dbase对象不同。\n",t);
						}
					}
				}
			}
			*/
			/*if(!functionp(curr_create_widget)){
				werror("%O %O",dbase,path);
			}
			ASSERT(functionp(curr_create_widget));*/
			ASSERT(functionp(curr_sorter));
			//werror("%O",dbase->query(path));
			mapping known=([]);
			if((father&&father->`->(curr_path[-1])==0)||!father&&THIS_SESSIOND->this_session()->dbase_query(dbase,curr_path)==0){
				while(sizeof(w->items)){
					w->delete(0);
				}
				return this;
			}
			array todelete=({});
			mixed mm=father&&father->`->(curr_path[-1])||THIS_SESSIOND->this_session()->dbase_query(dbase,curr_path);
			foreach(w->items;int pos;Widget item){
				if(item->name){
					if(array_query(mm,item->name)!=0){
						known[item->name]=item;
					}else{
						//werror("can't found %s in path %O data %O",item->name,path,dbase->query(path));
						todelete+=({pos});
						//w->delete(pos);
					}
				}
			}
			foreach(reverse(todelete),int pos){
				w->delete(pos);
			}

			int found;
			if(mappingp(mm)){
				foreach(mm;string key;mixed m){
					//werror("check1 %O\n",key);
					if(known[key]==0){
						//werror("new\n");
						//werror("sync: %O\n",dbase->query(path));
						//ASSERT(m);
						//ASSERT(mappingp(m)||arrayp(m));
						object ob;
						if(curr_constructor){
							ob=curr_constructor(key,1);
							if(!functionp(curr_create_widget)){
								curr_create_widget=ob->create_widget;
							}
						}else{
							/*werror("WARNING: no constructor found to create %s\n",key);
							werror("WARNING: using curr_create_widget: %O\n",curr_create_widget);
							werror("WARNING: create_widget: %O\n",create_widget);
							werror("WARNING: curr_path: %O\n",curr_path);
							*/
						}

						Widget item;
						mixed tt=__get_first_arg_type(_typeof(curr_create_widget));
						if(tt==0||tt==ARGTYPE(string)/*||tt==ARGTYPE(mixed)*/){
							item=curr_create_widget(key,m,curr_path,dbase,mappingp(create_widget)?create_widget:0);
						}else{
							werror("_typeof(curr_create_widget)=%O\n",_typeof(curr_create_widget));
							werror("tt=%O\n",tt);
							ASSERT(tt==ARGTYPE(object));
							ASSERT(ob);
							item=curr_create_widget(ob,mappingp(create_widget)?create_widget:0);
						}
						ASSERT(item->name==0);
						item->mark(key);
						w->add(item);
						known[key]=item;
						found=1;
					}
				}
			}else if(arrayp(mm)){
				foreach(mm,mapping b){
					string key=b["_id_"];mapping val=b;
					//werror("check2 %s\n",key);
					if(known[key]==0){
						//werror("new\n");
						ASSERT(val);
						ASSERT(mappingp(val)||arrayp(val));
						//curr_constructor(key);
						object ob;
						if(curr_constructor){
							ob=curr_constructor(key,1);
							if(!functionp(curr_create_widget)){
								curr_create_widget=ob->create_widget;
							}
						}else{
							/*werror("WARNING: no constructor found to create %s\n",key);
							werror("WARNING: using curr_create_widget: %O\n",curr_create_widget);
							werror("WARNING: create_widget: %O\n",create_widget);
							werror("WARNING: curr_path: %O\n",curr_path);
							*/
						}
						//Widget item=curr_create_widget(key,val,path,dbase,mappingp(create_widget)?create_widget:0);
						Widget item;
						mixed tt=__get_first_arg_type(_typeof(curr_create_widget));
						if(tt==0||tt==ARGTYPE(string)/*||tt==ARGTYPE(mixed)*/){
							item=curr_create_widget(key,val,path,dbase,mappingp(create_widget)?create_widget:0);
						}else{
							werror("_typeof(curr_create_widget)=%O\n",_typeof(curr_create_widget));
							werror("tt=%O\n",tt);
							//ASSERT(tt==ARGTYPE(object));
							ASSERT(ob);
							item=curr_create_widget(ob,mappingp(create_widget)?create_widget:0);
						}
						ASSERT(item->name==0);
						item->mark(key);
						w->add(item);
						known[key]=item;
						found=1;
					}
				}
			}
			if(found&&curr_sorter){
				array a=curr_sorter(copy_value(w->items),m);
				int found2=0;
				int count;
				do{
					if(count==sizeof(w->items)){
						werror("ERROR: reorder error.\n");
						break;
					}
					for(int i=0;i<sizeof(a);i++){
						if(a[i]!=w->items[i]){
							w->reorder(a[i],i);
							found2=1;
							count++;
						}
					}
				}while(found2);
			}
		};
		if(e){
			master()->handle_error(({"Syncer sync error, dumping backtrace of create:",bt}));
			throw(e);
		}
		return this;
	}
}

class TypeRegister(mixed t) {
	object register(string name,function f){MODULED->add_object_function(t,name,f);return this;}
}
