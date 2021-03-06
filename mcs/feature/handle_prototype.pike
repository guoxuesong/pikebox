extern mixed dbase_query(object dbase,array key);
extern mixed dbase_father_set(object father,string subpath,string key,mixed val);
extern mixed dbase_delete(object dbase,array key);
extern object root;
MIXIN Common{
	/*
	extern string key;
	extern array fullpath;
	extern object _dbase;
	extern mapping data;
	extern int nocreate;
	*/
	//walk around the deep-mixin bug of "extern"
	string key;
	array fullpath;
	object _dbase;
	mapping data;
	int nocreate;
	object father;

	//class ProtoType{};
	REGISTER(init_dbaseitem);
	void init_dbaseitem(mapping init_data)/*{{{*/
	{

		if(this.ProtoType==0){
			werror("WARNING: class ProtoType not defined, maybe you forgot it: %O\n",this);
		}
			
		//werror("handle_prototype: key=%s fullpath=%O\n",key,fullpath);
		ASSERT(arrayp(fullpath));
		int create_flag;
		if(data==0){
			//ASSERT(key!="1");
			if(!nocreate){
				ASSERT_TRUE(cache_level()==0,cache_level());
				mapping m=(["_id_":key]);
				//mixed succ=_dbase->set(fullpath+({key}),m);
				//mixed succ=dbase_set(_dbase,fullpath+({key}),m);
				mixed succ;
				if(this->is_typeitem&&father!=root){
					ASSERT(father);
					succ=dbase_father_set(father,fullpath[-1],key,m);
					//werror("init_dbaseitem 1: %O %O\n",father->data,m);
				}else{
					succ=_dbase->set(fullpath+({key}),m);
					//werror("init_dbaseitem 2: %O %O\n",_dbase->query(fullpath+({key})),m);
				}


				//werror("%O",_dbase->data);
				if(!succ){
					//mixed a=_dbase->query(fullpath);
					werror("path=%O\n",fullpath+({key}));
					werror("m=%O\n",m);
					/*if(objectp(a)&&object_program==BigArray){
						a+=({m});
					}else{
					}*/
				}
				ASSERT(succ);
				//ASSERT(_dbase->query(fullpath+({key}))!=0);
				//以下代码是为了老的BigMapping而写，老的BigMapping返回的mapping不等于m，以下代码的副作用是会导致on_create(0)先于on_create(1)被调用
				/*
				ASSERT(dbase_query(_dbase,fullpath+({key}))!=0);
				//data=_dbase->query(fullpath+({key}));
				mapping|object t=dbase_query(_dbase,fullpath+({key}));
				if(t->is_dbase)
					data=t->data;
				else
					data=t;
					*/
				data=m;
				if(mappingp(data)) ASSERT_TRUE(data->_id_,data);
				create_flag=1;
			}
		}else{
			//werror("init_dbaseitem: not created %O\n",data);
		}
		if(data){
			mapping m=data;
			foreach((this.ProtoType?({this.ProtoType}):({}))+(HANDLE_PROTOTYPED->program2prototypes[object_program(this)]||({})),program p){
				object t=p();
				foreach(indices(t),string key){
					//werror("handle_prototype: %s\n",key);
					mixed val=t[key];
					/*if(key=="unread"){
						werror("handle_prototype: t[key]=%O\n",val);
						werror("handle_prototype: m[key]=%O\n",m[key]);
					}*/
					if(functionp(val)){
						//werror("ERROR: don't use function in protytype, use Func(curr_namespace,\"funcname\") instead. val=%O\n",val);
						//ABORT();
						val=val(this->key);
					}
					if(zero_type(m[key])){
						//werror("handle_prototype: init %s %O\n",key,copy_value(val));
						m[key]=copy_value(val);
					}else if(objectp(m[key])&&object_program(m[key])==Func&&m[key]!=val){
						werror("handle_prototype: warning Func changed %s.%s -> %s.%s\n",m[key]->daemon,m[key]->func,val->daemon,val->func);
						m[key]=copy_value(val);
					}
				}
			}
			foreach((this.Constants?({this.Constants}):({}))+(HANDLE_PROTOTYPED->program2constants[object_program(this)]||({})),program p){
				object t=p();
				foreach(indices(t),string key){
					mixed val=t[key];
					werror("handle constant %s=%O old=%O\n",key,val,m[key]);
					if(functionp(val)){
						werror("handle constant %s is function\n",key);
						val=val(this->key);
						//werror("ERROR: don't use function in constants, use Func(curr_namespace,\"funcname\") instead. val=%O\n",val);
						//ABORT();
					}
					if(zero_type(m[key])){
						werror("handle constant %s is new\n",key);
						//werror("handle_prototype: init %s %O\n",key,copy_value(val));
						m[key]=copy_value(val);
					}else if(m[key]!=val){
						werror("handle constant %s need fix\n",key);
						werror("handle_prototype: warning fix constant %s: %O -> %O\n",key,m[key],val);
						m[key]=copy_value(val);
					}
				}
			}
			foreach((this.Deprecated?({this.Deprecated}):({}))+(HANDLE_PROTOTYPED->program2deprecated[object_program(this)]||({})),program p){
				object t=p();
				foreach(indices(t),string key){
					mixed val=t[key];
					if(m[key]){
						m_delete(m,key);
						werror("handle_prototype: warning delete deprecated %s\n",key);
					}
				}
			}
			if(this->on_create){
				this->on_create(create_flag,init_data);
			}
			foreach((HANDLE_PROTOTYPED->program2on_create[object_program(this)]||({})),function on_create){
				on_create(this,create_flag,init_data);
			}
		}
	}/*}}}*/
	mixed `->(string|array k)/*{{{*/
	{
		k=Array.arrayify(k);
		//if(data&&mappingp(data)&&data->_atime_)
			//data->_atime_=time();
		//werror("handle_prototype: `->: %s\n",key);
		if(object_variablep(this,k[0])||this[k[0]]){
		//werror("handle_prototype: `->: %s : return this[key]\n",key);
			return this[k[0]];
		}
		else{
			//ASSERT((this_session()?((this_session()->program2prototypes[object_program(this)]||({}))+(this_session()->program2constants[object_program(this)]||({}))):({})));
			//这段代码很奇怪，按理说所有的Func应该在data里面，为什么要去ProtoType里面取Func呢
#ifndef RUNTIME_CHECK_OPT
			foreach(
			(this.ProtoType?({this.ProtoType}):({}))+
			(this.Constants?({this.Constants}):({}))+
			((HANDLE_PROTOTYPED->program2prototypes[object_program(this)]||({}))+(HANDLE_PROTOTYPED->program2constants[object_program(this)]||({})))
			,program p){
				object t=p();
				//werror("p=%O\n",p);
				//foreach(indices(t),string k){
					//werror("handle_prototype: `->: %s : %s\n",key,k);
				//}
				if(object_variablep(t,k[0])){
#endif
					if(data){
						mixed res=data[k[0]];
						if(objectp(res)&&object_program(res)==Func){
							//werror("handle_prototype call Func\n");
							mixed tt=__get_first_arg_type(res->_typeof());
							if(tt==0||tt==ARGTYPE(string)){
								werror("Deprecated: Func not accept object.\n");
								return res(this->key,data,fullpath,_dbase);
							}else{
								return res(this,k);
							}
						}
						return res;
					}
#ifndef RUNTIME_CHECK_OPT
				}
			}
#endif
		}
	}/*}}}*/
	private int handle_prototype_set(string|array k,mixed val)/*{{{*/
	{
		if(stringp(k))
			k=({k});
		//werror("handle_prototype_set\n");
		if(data&&mappingp(data)&&data->_mtime_)
			data->_mtime_=time();
		mixed old=data&&data[k[0]];
		if(object_variablep(this,k[0])||this[k[0]]){
			this[k[0]]=val;
			if(data&&data[k[0]]!=old)
				return 1;
		}
		else{
			ASSERT(cache_level()==0);
			foreach((this.ProtoType?({this.ProtoType}):({}))+(this.Constants?({this.Constants}):({}))+
					((HANDLE_PROTOTYPED->program2prototypes[object_program(this)]||({}))+(HANDLE_PROTOTYPED->program2constants[object_program(this)]||({}))),program p){
				object t=p();
				if(object_variablep(t,k[0])){
					mixed res=data[k[0]];
					if(objectp(res)&&object_program(res)==Func){
						//werror("handle_prototype call Func\n");
						mixed tt=__get_first_arg_type(res->_typeof());
						if(tt==0||tt==ARGTYPE(string)){
							werror("Deprecated: Func not accept object.\n");
							res(this->key,data,fullpath,_dbase,1,val);
						}else{
							res(this,k,"=",val);
						}
						return 1;
					}else{
						data[k[0]]=val;
						return 1;
					}
				}
			}
		}
	}/*}}}*/
	mixed `->=(string|array k,mixed val)/*{{{*/
	{
		int changed=handle_prototype_set(k,val);
		if(changed)
			MODULED->apply_function(this,"handle_change",k);
		return val;
	}/*}}}*/
}

DAEMON:
mapping program2prototypes=([]);
mapping program2constants=([]);
mapping program2deprecated=([]);
mapping program2on_create=([]);
mapping program2on_remove=([]);
mapping program2actions=([]);
mapping program2noparam_actions=([]);
void add_prototype(program|multiset m,program p,function|void on_create,function|void on_remove)
{
	if(!multisetp(m)){
		m=(<m>);
	}
	foreach(m;program t;int one){
		ASSERT(t);
		program2prototypes[t]=program2prototypes[t]||({});
		if(search(program2prototypes[t],p)<0)
			program2prototypes[t]+=({p});
		if(on_create){
			program2on_create[t]=program2on_create[t]||({});
			if(search(program2on_create[t],on_create)<0)
				program2on_create[t]+=({on_create});
		}
		if(on_remove){
			program2on_remove[t]=program2on_remove[t]||({});
			if(search(program2on_remove[t],on_remove)<0)
				program2on_remove[t]+=({on_remove});
		}
		//werror("add_prototype: %O %O\n",t,program2prototypes[t]);
	}
}
void add_constants(program|multiset m,program p)
{
	if(!multisetp(m)){
		m=(<m>);
	}
	foreach(m;program t;int one){
		ASSERT(t);
		program2constants[t]=program2constants[t]||({});
		if(search(program2constants[t],p)<0)
			program2constants[t]+=({p});
	}
}
void add_deprecated(program|multiset m,program p)
{
	if(!multisetp(m)){
		m=(<m>);
	}
	foreach(m;program t;int one){
		ASSERT(t);
		program2deprecated[t]=program2deprecated[t]||({});
		if(search(program2deprecated[t],p)<0)
			program2deprecated[t]+=({p});
	}
}

void add_actions(program|multiset m,mapping p)
{
	if(!multisetp(m)){
		m=(<m>);
	}
	foreach(m;program t;int one){
		ASSERT(t);
		program2actions[t]=program2actions[t]||({});
		if(search(program2actions[t],p)<0)
			program2actions[t]+=({p});
	}
}
void add_noparam_actions(program|multiset m,mapping p)
{
	if(!multisetp(m)){
		m=(<m>);
	}
	foreach(m;program t;int one){
		ASSERT(t);
		program2noparam_actions[t]=program2noparam_actions[t]||({});
		if(search(program2noparam_actions[t],p)<0)
			program2noparam_actions[t]+=({p});
	}
}
