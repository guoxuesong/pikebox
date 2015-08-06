class Save{/*{{{*/
	mapping save()
	{
		mapping res=([]);
		foreach(indices(this),string key){
			if(object_variablep(this,key)){
				res[key]=this[key];
			}
		}
		return res;
	}
}/*}}}*/
object load(object|program ob,mapping m)/*{{{*/
{
	if(programp(ob))
		ob=ob();
	foreach(indices(ob),string key){
		if(object_variablep(ob,key)){
			mixed e=catch{
			ob[key]=m[key];
			};
			if(e){
				werror("key=%s\nm=%O\n",key,m);
				throw(e);
			}
		}
	}
	return ob;
}/*}}}*/

/* Save.Project 机制
   =================

	 * inherit Save.Project;
   * Stdio.write_file(FILE,encode_value(OBJECTS));
   * OBJECTS=decode_value(Stdio.read_file(FILE));
   * 缺省情况下，所有的array,mapping,multiset里的对象被当作实例存储，如果需要被当作链接存储，使用REFERENCE
   * 缺省情况下，所有的成员对象被当作链接存储，如果需要被当作实例存储，使用INSTANCE

   */


class Project{
class Codec{/*{{{*/
	mixed nameof(object|function|program x)
	{
		if(objectp(x)){
			werror("object\n");
			if(x->_save){
				return ({"oSave",object_program(x),x->_save()});
			}else{
				mixed v=master()->nameof(x);
				if(v)
					return ({"oOther",v});
				else
					return v;
			}
		}else if(programp(x)){
			werror("program\n");
			return master()->nameof(x);

		}else{
			werror("other\n");
			return master()->nameof(x);

		}
	}

	object objectof(array data)
	{
		//array a=decode_value(data);
		array a=data;
		if(a[0]=="oSave"){
			return load_object(a[1],a[2][0])->_load(@a[2]);
		}else{
			return master()->objectof(a[1]);
		}
	}
	object __register_new_program(program p)
	{
		return master()->__register_new_program(p);
	}
	function functionof(mixed data)
	{
		return master()->functionof(data);
	}
	program programof(mixed data)
	{
		return master()->programof(data);
	}
}/*}}}*/
string encode_value(mixed val)/*{{{*/
{
	return predef::encode_value(val,Codec());
}/*}}}*/
mixed decode_value(string data)/*{{{*/
{
	return predef::decode_value(data,Codec());
}/*}}}*/
	array save_object(object ob)/*{{{*/
	{
		mapping m=([]);
		mapping p=([]);
		foreach(indices(ob),string key){
			if(object_variablep(ob,key)){
				if(objectp(ob[key])){
					m[key]=ob[key]->id;
					p[key]=object_program(ob[key]);
				}else{
					m[key]=ob[key];
				}
			}
		}
		return ({ob->id,p,m});
	}/*}}}*/

	mapping _objects=([]);
	object load_object(program p,string id)/*{{{*/
	{
		_objects[p]=_objects[p]||([]);
		_objects[p][id]=_objects[p][id]||p(id);
		return _objects[p][id];
	}/*}}}*/
	object find_object(program p,string id)/*{{{*/
	{
		return _objects[p]&&_objects[p][id];
	}/*}}}*/
	class Object(string id){/*{{{*/
		array _data=({});
		array _save(){ return save_object(this);}
		object _load(string _id,mapping progs,mapping vals){
			id=_id;
			foreach(progs;string key;program p){
				this[key]=load_object(p,vals[key]);
			}
			foreach(vals;string key;mixed val){
				if(progs[key]==0){
					this[key]=val;
				}
			}
			return this;
		}
		object _push(object ob)
		{
			_data=_data+({ob});
			return ob;
		}
		object INSTANCE(object x)
		{
			return _push(x);
		}

	}/*}}}*/
	class Reference{/*{{{*/
		object value;
		object set(object v){value=v;return this;}
		void create(string|void ig){ }
		array _save(){ return save_object(this);}
		object _load(string ig,mapping progs,mapping vals){
			foreach(progs;string key;program p){
				this[key]=load_object(p,vals[key]);
			}
			return this;
		}

	}/*}}}*/
	class Factory{/*{{{*/
		inherit Object;
		program prog;
		mapping(string:object) m=([]);
		int sn;

		object alloc(){/*{{{*/
			sn++;
			object res=prog((string)sn);
			res->factory=this;
			m[res->id]=res;
			return res;
		}/*}}}*/
		object set_item_program(program p){/*{{{*/
			prog=p;
			return this;

		}/*}}}*/
	}/*}}}*/
	class Item{/*{{{*/
		inherit Object;
		Factory factory;
		void free()
		{
			m_delete(factory->m,id);
		}
	}/*}}}*/
	object REFERENCE(object x)/*{{{*/
	{
		return Reference()->set(x);
	}/*}}}*/
}


