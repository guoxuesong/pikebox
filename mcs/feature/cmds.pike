extern object type_resolver;
extern string PATH;
array minute_cmdscount=({({time()/60,0})});
multiset global_external_setup_flags=(<>);

MIXIN Session{
#include <symble_stream.h>
	extern string super_user,curr_user;
	extern object this_player();
	//extern function write;
	private multiset external_setup_flags=(<>);
	private mapping cmd2object=([]);
	private string cmd_prefix;
	private int case_insensitive;
	int active_time;
	extern string id;
	int cmd_step;

	//Thread.Queue q_out;


	private PUBLIC public_sample(){};
	private USERONLY useronly_sample(){};
	private PRIVATE private_sample(){};
	private SUPERUSER superuser_sample(){};

	private mixed type_public=__get_return_type(typeof(public_sample));
	private mixed type_useronly=__get_return_type(typeof(useronly_sample));
	private mixed type_private=__get_return_type(typeof(private_sample));
	private mixed type_super=__get_return_type(typeof(superuser_sample));

	int cmdp(mixed f){
		if(functionp(f)){
			mixed t=_typeof(f);
			string s=sprintf("%O",t);
			if(search(s,CMDTYPE_PREFIX)>=0){
				return 1;
			}
		}
	}

	void set_cmd_prefix(string s)/*{{{*/
	{
		cmd_prefix=s;
	}/*}}}*/

	void set_case_insensitive(){case_insensitive=1;};
	void set_case_sensitive(){case_insensitive=0;};

	private mapping func_type=([]);
	array list_cmds()
	{
		array res=({});
		foreach(indices(this),string key){
			if(functionp(this[key])){
				function f=this[key];
				if(cmdp(f)){
					res+=({key});
				}
			}
		}
		return res;
	}
	void update_commands()
	{
		werror("WARNING: update_commands deprecated.\n");
		foreach(cmd2object;string cmd;object ob){
			load_command(cmd);
		}
	}
	object load_command(string cmd)/*{{{*/
	{
		werror("WARNING: load_command deprecated.\n");
		if(1||cmd2object[cmd]==0){
			//werror("LOAD_COMMAND: %s\n",cmd);
			/*if(cmd=="units"){
				master()->handle_error(({"LOAD_COMMAND",backtrace()}));
			}*/
			werror("PATH=%O\n",PATH);
			mixed err=catch{
				string path=Stdio.append_path(PATH,cmd+".pike");
				object old_curr_session=THIS_SESSIOND->this_session();
				THIS_SESSIOND->set_this_session(this);
				program p=object_program(load_system(path,1,
	sprintf(
#"IMPORT(F_HAS_MAIN);
string curr_session;
protected string curr_namespace=\"%s\";\n
				PUBLIC _main(mixed ... args)
				{
					array argv=({\"%s\"})+args;
					int argc=sizeof(argv);
					return main(argc,argv);
				}
			",cmd,cmd),1));
				object ob=p();
				ob->curr_session=id;
				cmd2object[cmd]=ob;
				if(external_setup_flags[cmd]==0){
					external_setup_flags[cmd]=1;
					if(ob->init){
						ob->init();
					}
				}
				//GLOBALD->curr_session=old_curr_session;
				THIS_SESSIOND->set_this_session(old_curr_session);
				//return ob;
			};
			if(err){
				master()->handle_error(err);
			}
		}
		object ob=cmd2object[cmd];
		if(ob->vars){
			foreach(ob->vars;mixed key;mapping m)
				ASSERT(stringp(key));
			if(GLOBALD->query(({"/",cmd}))==0){
				GLOBALD->set(({"/",cmd}),copy_value(ob->vars));
			}else{
				foreach(ob->vars;mixed key;mixed val){
					if(GLOBALD->query(({"/",cmd,key}))==0){
						GLOBALD->set(({"/",cmd,key}),copy_value(val));
					}
				}
			}
		}
		if(global_external_setup_flags[cmd]==0){
			global_external_setup_flags[cmd]=1;
			if(ob->init_global){
				ob->init_global();
			}
		}
		return ob;
		//return cmd2object[cmd];
	}/*}}}*/
	private mixed exec_internal(string cmd,function f,array args00)/*{{{*/
	{
		mixed res;
		array argv=({cmd})+args00;
		mixed t=_typeof(f);
		//werror("%s = %O [%O]\n",cmd,this[cmd],t);
		array args0=map(argv[1..],lambda(string s){if(s=="$USER"){return curr_user;}else{return s;}});
		array args=({});
		int fail;
		array resolver_list=({global::this,DBASEITEMD->root});
		//ASSERT(THIS["curr"]==this);
		//ASSERT(THIS["curr"]->this_player==this->this_player);
		//ASSERT(this->this_player);
		//werror("THIS[\"curr\"]->this_player:%O\n",THIS["curr"]->this_player);
		//werror("THIS->this_player:%O\n",THIS->this_player);
		//werror("this->this_player:%O\n",this->this_player);
		if(this_player()){
			resolver_list+=({this_player()});
		}
		resolver_list+=({function_object(f)});
		ENTER(this);
		foreach(args0,mixed s){
			if(!__low_check_call(t,_typeof(s),1)){
				mixed t1=__get_first_arg_type(t);
				t=__low_check_call(t,typeof(0));
				fail=1;
				foreach(reverse(resolver_list),object ob){
					if(ob->type_resolver&&ob->type_resolver[t1]){
						//werror("resolver found %O\n",ob->type_resolver[t1]);
						if(ob->type_resolver[t1]){
							if(stringp(ob->type_resolver[t1])){
								string k=ob->type_resolver[t1];
								if(ob[k][s]){
									args+=({ob[k][s]});
									resolver_list+=({ob[k][s]});
									fail=0;
									break;
								}
							}else if(functionp(ob->type_resolver[t1])){
								if(ob->type_resolver[t1](s)){
									args+=({ob->type_resolver[t1](s)});
									resolver_list+=({ob->type_resolver[t1](s)});
									fail=0;
									break;
								}
							}else if(mappingp(ob->type_resolver[t1])){
								args+=({ob->type_resolver[t1][s]});
								resolver_list+=({ob->type_resolver[t1][s]});
								fail=0;
								break;
							}
						}
					}
				}
				if(fail){
					if(t1==ARGTYPE(int)){
						//werror("a\n");
						int d;
						if(sscanf(s,"%d",d)){
						//werror("b\n");
							args+=({d});
							fail=0;
						}
					}
				}
				if(fail){
					throw(ResolveException(sprintf("ERROR: 无法将 %O 解析为 %O， 所用 type_resolver 如下：\n%O.\n",s,t1,resolver_list),backtrace()));
				}

			}else{
				t=__low_check_call(t,_typeof(s),1);
				if(t){
					args+=({s});
				}else{
					throw(ResolveException(sprintf("ERROR: 发现多余的参数 %s.\n",s),backtrace()));
					//werror("ERROR: unknown extra arg: %s.\n",s);
					//fail=1;
				}
			}
		}
		LEAVE();
		mixed run(function f,array args){
			mixed res;
			ENTER(this);
			res=f(@args);
			werror("run return %O\n",res);
			LEAVE();
			return res;
		};
		if(__get_return_type(t)==type_super){
				//access_control[cmd]==SUPERUSER
			if(curr_user&&curr_user==function_object(f)->super_user||curr_user==super_user){
				res=run(f,args);
			}else{
				throw(PermisionException(sprintf("错误: 命令%s需要超级用户权限。\n",cmd),backtrace()));
				//res=this["homepage"](THIS->curr_user);
			}
		}else if(__get_return_type(t)==type_private){
				//access_control[cmd]==PRIVATE
			if(sizeof(argv)>1&&(stringp(args[0])||curr_user==argv[1])||curr_user==super_user){
				res=run(f,args);
			}else{
				throw(PermisionException(sprintf("错误: 你没有执行命令%s的权限。\n",cmd),backtrace()));
				//res=this["homepage"](THIS->curr_user);
			}
		}else if(__get_return_type(t)==type_useronly){
			if(curr_user!=0){
				res=run(f,args);
			}else{
				throw(PermisionException(sprintf("错误: 命令%s需要登陆。\n",cmd),backtrace()));
			}
		}else if(__get_return_type(t)==type_public){
				//access_control[cmd]==PUBLIC
			res=run(f,args);
		}else if(__get_return_type(t)!=0){
			if(function_object(f)->_type2rule){
				foreach(function_object(f)->_type2rule;mixed tt;array rule)
				{
					if(tt==__get_return_type(t)){
						mixed target;
						multiset target_tags=(<>);
						multiset player_tags=(<>);
						ENTER(this);
						if(rule[2]==0){
							if(sizeof(args))
								target=args[0];
						}else{
							target=rule[2](@args);
						}
						if(objectp(target)||mappingp(target)){
							target_tags=target->_tags||(<>);
						}
						if(this_player()){
							player_tags=this_player()->_tags||(<>);
						}
						target_tags|=filter(rule[0],lambda(mixed t){if(functionp(t)){return t(target);}});
						player_tags|=filter(rule[1],lambda(mixed t){if(functionp(t)){return t(this_player());}});
						werror("rule[0]=%O\n",rule[0]);
						werror("rule[1]=%O\n",rule[1]);
						werror("target_tags=%O\n",target_tags);
						werror("player_tags=%O\n",player_tags);
						LEAVE();
						if(sizeof(target_tags&rule[0])==sizeof(rule[0])
							&&sizeof(player_tags&rule[1])==sizeof(rule[1])){
							res=run(f,args);
						}else{
							throw(PermisionException(sprintf("错误:你没有执行命令%s的权限。\n",cmd),backtrace()));
						}
					}
				}
			}else{
				throw(PermisionException(sprintf("错误:你没有执行命令%s的权限。\n",cmd),backtrace()));
			}
		}else{
			throw(NotFoundException(sprintf("错误:命令%s不存在，或者参数数量错误。\n",cmd),backtrace()));
		}
		return res;
	}/*}}}*/
#if 0
	mixed exec_external(string cmd,function f,array args)/*{{{*/
	{
		ASSERT(cmd);
		mixed e;
		ENTER(this);
		mixed res;
		object ob=function_object(f);
		e=catch{
			res=exec_internal(cmd,f,args);
			werror("exec_internal return %O\n",res);
		};
		LEAVE();
		if(e)
			throw(e);
		return res;
	}/*}}}*/
#endif
	int command(string cmd,array args)
	{
		cmd_step++;
		if(case_insensitive){
			cmd=lower_case(cmd);
		}
		if(cmd=="create"||cmd=="destroy"){
			cmd="_"+cmd;
		}
		if(cmd_prefix&&!has_prefix(cmd,cmd_prefix+".")){
			cmd=cmd_prefix+"."+cmd;
		}
		//werror("%s %s\n",cmd,join(args," "));
		if(minute_cmdscount[-1][0]!=time()/60){
			for(int i=minute_cmdscount[-1][0]+1;i<=time()/60;i++){
				minute_cmdscount+=({({i,0})});
			}
			if(sizeof(minute_cmdscount)>60*24+1){
				minute_cmdscount=minute_cmdscount[<60*24..];
			}
		}
		minute_cmdscount[-1][1]++;
		active_time=time();
		int err=1;
		array argv=({cmd})+args;
		function f;

		//mixed e;
		if(cmd==""&&sizeof(args)==0){
			err=0;
		}else{
			if(cmdp(this[cmd])){
				werror("this[\"%s\"] is a command.\n",cmd);
				f=this[cmd];
			}else{
				werror("this[\"%s\"] is not a command.\n",cmd);
				/*
				foreach(curr_widget_handlers(),object ob){
					if(cmdp(ob[cmd])){
						f=ob[cmd];
						break;
					}
				}
				*/
			}
			//e=catch{
				if(f){
					err=exec_internal(cmd,f,args);
				}else{
					object ob;
					array a=(cmd/".");
					if(all_constants()[a[0]]&&objectp(all_constants()[a[0]])){
						ob=all_constants()[a[0]];
					}else{
						array cmds=get_dir(PATH);
						foreach(cmds,string s){
							if(s==a[0]+".pike"){
								ob=load_command(a[0]);
								if(ob)
									break;
							}
						}
					}
					if(ob){
						if(sizeof(a)==1)
							f=ob->_main;
						else
							f=ob[a[1..]*"."];
					}
					if(f){
						err=exec_internal(cmd,f,args);
					}else{
						throw(NotFoundException(sprintf("错误:命令%s不存在，或者参数数量错误。\n",cmd),backtrace()));
					}
				}
			//};
		}
		return err;
	}
	/*
	int command(string cmd,array args)
	{
		int err;
		mixed e=catch{
			err=_command(cmd,args);
		};

		string data="";
		symble_clear(lambda(mixed ... args){data+=sprintf(@args);});
		if(q_out){
			//werror("write q_out: %d %O\n",err,data);
			q_out->write(({err,data}));
		}else{
			werror("q_out missed: %s",data);
		}
		if(e)
			throw(e);
		return err;
	}
	*/
}

DAEMON:
class PermisionException{
	inherit Error.Generic;
}
class ResolveException{
	inherit Error.Generic;
}
class NotFoundException{
	inherit Error.Generic;
}
