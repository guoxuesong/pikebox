	string base;string features;
	void create(string b,string f)
	{
		base=b;
		features=f;
	}
	object add_feature(string f)
	{
		features=((features/",")-({""})+({f}))*",";
		return this;
	}
  object `+=(string f)
	{
		return add_feature(f);
	}
	private string try_create_file()
	{
		array a=replace(features,".","")/","-({""});
		a=map(a,lambda(string s){
				if(has_prefix(s,base)){
					return s[sizeof(base)..];
				}else{
					return s;
				}
				});
		string progkey=(({base})+a)*"_";
		string filepath;

		filepath=getenv("PIKEBOX")+"/systems/"+CLASS_HOST+".pmod/Class.pmod/"+progkey+".pike";
		if(!Stdio.is_file(filepath)){
			mkdir(getenv("PIKEBOX")+"/systems/"+CLASS_HOST+".pmod/Class.pmod/");
			mkdir(getenv("PIKEBOX")+"/systems/"+CLASS_HOST+".pmod/Static.pmod/");
			Stdio.write_file(filepath,"class _class{\n");
			Stdio.append_file(filepath,sprintf("\tinherit %s.%s;\n",CLASS_HOST,base));
			foreach(features/","-({""}),string prog){
				Stdio.append_file(filepath,sprintf("\tinherit %s.%s;\n",CLASS_HOST,prog));
			}
			Stdio.append_file(filepath,sprintf("\}\n",));
		}
		filepath=getenv("PIKEBOX")+"/systems/"+CLASS_HOST+".pmod/Static.pmod/"+progkey+".pike";
		if(!Stdio.is_file(filepath)){
			Stdio.write_file(filepath,sprintf("inherit %s.Class.%s._class.Static;\n",CLASS_HOST,progkey));
		}
		return progkey;
	}
	mixed cast(string type)
	{
		if(type=="program"){
			string progkey=try_create_file();
			//string rpath="Class.pmod/"+progkey+".pike";
			//return ((object)(rpath))._class(@args);
			string filepath=getenv("PIKEBOX")+"/systems/"+CLASS_HOST+".pmod/Class.pmod/"+progkey+".pike";
			return ((object)(filepath))._class;
		}
	}
	object `()(mixed ... args)
	{
		return cast("program")(@args);
	}
	object find_static()
	{
		string progkey=try_create_file();
		//string rpath="Static.pmod/"+progkey+".pike";
		//return ((object)(rpath));
		string filepath=getenv("PIKEBOX")+"/systems/"+CLASS_HOST+".pmod/Static.pmod/"+progkey+".pike";
		return ((object)(filepath));
	}

