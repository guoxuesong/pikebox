#define DEBUG/*{{{*/

#define ABORT() throw(({"ERROR\n",backtrace()}))
#define assert(EXP) ((EXP)||ABORT())

#ifdef DEBUG
#define ASSERT(EXP) assert(EXP)
#endif/*}}}*/

	constant is_dbase=1;
	mapping data=([]);

//! query
	mixed query(array key)/*{{{*/
	{
		ASSERT(key[0]=="/");
		if(equal(key,({"/"}))||equal(key,({"/",""}))){
			return data;
		}
		array a=key[1..];
		//werror("aa=%O\n",a);
		mapping|array m=data;
		for(int i=0;i<sizeof(a)-1;i++){
			string s=a[i];
			mixed t=array_query(m,s);
			if(!mappingp(t)&&!arrayp(t)&&!(objectp(t)&&object_program(t)==Func)){
				werror("return 0 for %s (found %O)\n",s,t);
				return UNDEFINED;
			}
			/*if((objectp(t)&&object_program(t)==Func)){
				array pp=({"/"})+a[..i-2];
				t=t(a[i-1],query(pp),pp,this); //函数通常用来构造一个虚拟的属性，函数需要知道自己在为谁构造属性，在为谁构造属性就把谁的key作为参数传给函数。
			}*/
			m=t;
		}
		mixed res=array_query(m,a[-1]);
		/*if(objectp(res)&&object_program(res)==Func){
			array pp=({"/"})+a[..<3];
			res=res(a[-2],query(pp),pp,this);
		}*/
		werror("return %s for %s\n",res==0?"0":"not 0",a[-1]);
		return res;
	}/*}}}*/

//! set
	mixed set(array key, mixed val)/*{{{*/
	{
		//ASSERT(cache_level()==0); // DBASETYPE will load data from gdbm and write into dbase, even if cache_level()!=0
		ASSERT(key[0]=="/");
		if(equal(key,({"/"}))||equal(key,({"/",""}))){
			return data=val;
		}
		for(int i=0;i<sizeof(key)-1;i++){
			if(query(key[..i])==0){
				for(int j=i;j<sizeof(key);j++){
					set(key[..j],([]));
				}
				break;
			}
		}
		mapping|array m=query(key[..<1]);
		if(mappingp(m)){
			werror("found key[..<1] as mapping\n");
			if(mappingp(val)&&val->_id_)
				val->_id_=val->_id_;
			return m[key[-1]]=val;
		}else if(arrayp(m)){
			werror("found key[..<1] as array\n");
			val->_id_=val->_id_||key[-1];
			if(val->_id_!=key[-1]){
				werror("key=%O",key[-1]);
				werror("val=%O\n",val);
			}
			ASSERT(val->_id_==key[-1]);
			if(zero_type(array_set(m,key[-1],val))){
				ASSERT(sizeof(key)>=3);
				mapping m=query(key[..<2]);
				ASSERT(mappingp(m));
				m[key[-2]]=m[key[-2]]+({val});
				//werror("m[key[-2]]=%O",m[key[-2]]);
				return val;
			}else{
				return val;
			}
		}else{
			werror("not found key[..<1] (%t) %O\n",m,indices(m));
		}

		/*
		array a=key[1..];
		mapping|array m=data;
		for(int i=0;i<sizeof(a)-1;i++){
			string s=a[i];
			mixed t=array_query(m,s);
			if(zero_type(t)){
				if(mappingp(m)){
					m[s]=([]);
					t=array_query(m,s);
				}
			}
			if(!mappingp(t)&&!arrayp(t)){
				return UNDEFINED;
			}
			m=t;
		}
		return array_set(m,a[-1],val);
		*/
	}/*}}}*/

//! delete
	mixed delete(array key)/*{{{*/
	{
		//ASSERT(cache_level()==0); // DBASETYPE will save data into gdbm and write into dbase, even if cache_level()!=0
		ASSERT(key[0]=="/");
		if(equal(key,({"/"}))||equal(key,({"/",""}))){
			return data=([]);
		}
		array a=key[1..];
		mapping|array m=data;
		for(int i=0;i<sizeof(a)-1;i++){
			string s=a[i];
			mixed t=array_query(m,s);
			if(!mappingp(t)&&!arrayp(t)){
				return UNDEFINED;
			}
			m=t;
		}
		if(mappingp(m)){
			return m_delete(m,a[-1]);
		}else if(arrayp(m)){
			//val->_id_=val->_id_||key[-1];
			/*if(val->_id_!=key[-1]){
				werror("key=%O",key[-1]);
				werror("val=%O\n",val);
			}*/
			//ASSERT(val->_id_==key[-1]);
			ASSERT(sizeof(key)>=3);
			mapping m=query(key[..<2]);
			ASSERT(mappingp(m));
			mapping res=query(key);;
			if(res){
				m[key[-2]]=m[key[-2]]-({res});
				//werror("m[key[-2]]=%O",m[key[-2]]);
			}
			return res;
		}
	}/*}}}*/

/*
void main()
{
	set(({"/","xixi","haha"}),({}));
	set(({"/","xixi","haha","haha"}),(["xxx":"haha"]));
	set(({"/","xixi","haha","haha2"}),(["xxx":"haha"]));
	//werror("%O",query(({"/","xixi","haha","haha"})));
	werror("%O",query(({"/","xixi","haha","haha2"})));
	delete(({"/","xixi","haha","haha2"}));
	werror("%O",query(({"/","xixi","haha"})));
}
*/
