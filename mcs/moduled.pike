mapping object_functions;
mapping program_firstflag=([]);
mapping program_checkflag=([]);
array errors=({});

void create()
{
	werror("moduled create...\n");
	object_functions=set_weak_flag(([]),Pike.WEAK_INDICES);
}

void error_notify(string fmt,mixed ... args)
{
	string e=sprintf(fmt,@args);
	errors+=({e});
	werror("%s",e);
}

void add_object_function(mixed ob,string name,function f)
{
	//werror("add_object_function %O %s [func]\n",ob,name);
	object_functions[ob]=object_functions[ob]||([]);
	object_functions[ob][name]=object_functions[ob][name]||set_weak_flag((<>),Pike.WEAK_INDICES);
	object_functions[ob][name][f]=1;
}

array apply_function(mixed ob,string name,mixed ... args)
{
	//werror("apply_function %s\n",name);
	//werror("%O\n",ob);
	//werror("%O\n",object_functions);
	//write("%O\n",indices(object_functions)[0]==ob);
	array res=({});
	if(object_functions[ob]){
			//werror("ok 1\n");
		if(object_functions[ob][name]){
			//werror("ok 2\n");
			foreach(object_functions[ob][name];function f;int one){
				//werror("call %O\n",f);
				res+=({f(@args)});
			}
		}
	}
	return res;
}


void auto_check_extern(object this,string file)
{
	if(this->skip_check_extern)
		return;
	//werror("INFO: check %s ...\n",file);
	foreach(indices(this),string k){
		/*werror("check %s\n",k);
		if(k=="symble_clear"){
			werror("\tobject_variablep=%d\n",object_variablep(this,k));
		}*/
		if(object_variablep(this,k)){
			mixed e=catch{
				if(this[k]==0)
					this[k]=this[k];
			};
			if(e){
				//werror("indices(this)=%O\n",indices(this));
				master()->handle_error(e);
				error_notify("ERROR: %s: extern %s 没有找到.\n",file,k);
			}
		}else{
			if(this[k]==0){
				error_notify("ERROR: %s: extern %s 没有找到.\n",file,k);
			}
		}
	}
	//werror("INFO: check %s done\n",file);
	
	/*
	string data=cpp(Stdio.read_file(file),file);
	foreach(data/"\n",string line){
		line=String.trim_all_whites(line);
		if(has_prefix(line,"extern ")){
			string s=(line/" ")[2];
			s=(s/";")[0];
			s=(s/"(")[0];
			foreach(s/",",string ss)
				check_extern(this,ss);
		}
	}
	*/
}

#if 0
void check_inherit(object this,string s,program p,object|void container)
{
	container=container||this;
	mixed p1=predef::`->(container,s);
	if(programp(p1)&&Program.inherits(p1,p))
		;
	else
		error_notify("ERROR: %O dos not inherit %O.\n",p1,p);
}
#endif

void destroy()
{
	werror("moduled destroy...\n");
}
