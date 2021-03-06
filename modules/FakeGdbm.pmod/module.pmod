private void werror(mixed ... args){}
#define DEBUG
#include <assert.h>
#if 0
#define ABORT() throw(({"ERROR\n",backtrace()}))
#define assert(EXP) ((EXP)||ABORT())

#ifdef DEBUG
#define ASSERT(EXP) assert(EXP)
#endif
#endif
private class Tool{
	extern string base;
	extern array get_dir(string path);
	protected string hashpath(string key)/*{{{*/
	{
		int n=hash(key);
		return sprintf("%01d/%01d%01d/%01d%01d/%01d%01d/%s",
				n%10,
				(n%100)/10,(n%1000)/100,
				(n%10000)/1000,(n%100000)/10000,
				(n%1000000)/100000,(n%10000000)/1000000,
				key);
	}/*}}}*/
	protected string _firstkey(array prefix){/*{{{*/
		//ASSERT(sizeof(prefix)==0||sizeof(prefix[0])==1);
		string p=base;
		array a=get_dir(p);
		sort(a);

		for(int i=0;i<4;i++){
			if(sizeof(a)){
				p=combine_path(p,i<sizeof(prefix)?prefix[i]:a[0]);
				a=get_dir(p);
				/*if(a==0){
					werror("%s\n",p);
				}*/
				sort(a);
			}
		}

		if(sizeof(a))
			return a[0];
	}/*}}}*/
	protected string _nextkey(array prefix,string key)/*{{{*/
	{
		werror("_nextkey: %s %s\n",combine_path(base,@prefix),key);
		array a=get_dir(combine_path(base,@prefix));
		sort(a);
		int pos=search(a,key);
		if(pos>=0&&pos+1<=sizeof(a)){
			for(int i=pos+1;i<sizeof(a);i++){
				werror("check %s\n",a[i]);
				string res=_firstkey(prefix+({a[i]}));
				if(res)
					return res;
			}
		}
	}/*}}}*/
}
private class gdbm_imp{
	inherit Tool;
	string base;

	extern array get_dir(string path);
	extern int rm(string path);
	extern int mkdirhier(string path);
	extern int write_file(string path,string data);
	extern string read_file(string path);

	void create(string file) {/*{{{*/
		while(file[-1]=='/')
			file=file[..<1];
		werror("file=%s\n",file);
		mkdirhier(file);
		base=file;
	}/*}}}*/
	string `[](string key){return fetch(key);} 
	string `[]=(string key,string data){if(store(key,data)){return data;}} 
	void close() {}
	string firstkey(){return _firstkey(({}));};
	string nextkey(string key) /*{{{*/
	{
		string s=hashpath(key);
		werror("hashpath=%s\n",s);
		array a=get_dir(dirname(combine_path(base,s)));
		sort(a);
		int pos=search(a,key);
		if(pos>=0&&pos+1<sizeof(a)){
			return a[pos+1];
		}else{
			int a,b,c,d,e,f,g;
			sscanf(s,"%01d/%01d%01d/%01d%01d/%01d%01d/%*s",a,b,c,d,e,f,g);
			werror("%O\n",({a,b,c,d,e,f,g}));
			return _nextkey(({sprintf("%01d",a),sprintf("%01d%01d",b,c),sprintf("%01d%01d",d,e)}),sprintf("%01d%01d",f,g))
				||_nextkey(({sprintf("%01d",a),sprintf("%01d%01d",b,c)}),sprintf("%01d%01d",d,e))
				||_nextkey(({sprintf("%01d",a)}),sprintf("%01d%01d",b,c))
				||_nextkey(({}),sprintf("%01d",a));


		}
	}/*}}}*/
	int reorganize() {}
	void sync() {}

	private object cache=CacheLite.Cache(5000);
	int(0..1) delete(string key) { /*{{{*/
		//m_delete(cache,key);
		m_delete(cache,({key}));
		string path=combine_path(base,hashpath(key));
		int res=rm(combine_path(base,hashpath(key)));
		path=dirname(path);
		while(path!=base&&sizeof(get_dir(path)||({}))==0){
			rm(path);
			path=dirname(path);
		}
		return res;
	}/*}}}*/
	string _fetch(string key){/*{{{*/
		return read_file(combine_path(base,hashpath(key)));
	}/*}}}*/
	string fetch(string key){/*{{{*/
		return cache(({key}),Function.curry(_fetch)(key));
	}/*}}}*/
	int store(string key,string data){/*{{{*/
		mkdirhier(dirname(combine_path(base,hashpath(key))));
		mixed e=catch{
			string olddata=fetch(key);
			write_file(combine_path(base,hashpath(key)),data);
			cache[({key})]=data;
			werror("store %s to %s ok\n",key,combine_path(base,hashpath(key)));
		};
		if(e){
			master()->handle_error(e);
			return 0;
		}else
			return 1;
	}/*}}}*/
}

class fs_gdbm{
	inherit gdbm_imp;

	array get_dir(string path){return predef::get_dir(path);}
	int rm(string path){return predef::rm(path);}
	int mkdirhier(string path){return Stdio.mkdirhier(path);}
	string read_file(string path){return Stdio.read_file(path);}
	int write_file(string path,string data)/*{{{*/
	{
		if(all_constants()["safe_write_file"]){
			werror("call safe_write_file\n");
			return all_constants()["safe_write_file"](path,data);
		}else{
			werror("call write_file\n");
			return Stdio.write_file(path,data);
		}
	}/*}}}*/
}

class ssh_gdbm{
	inherit gdbm_imp;

	string ip;
	int port;
	string user;

	void create(string _ip,int _port,string _user,string file)
	{
		ip=_ip;port=_port;user=_user;
		::create(file);
	}
	array get_dir(string path)
	{
		mapping res=Process.run(sprintf("ssh -p %d %s ls %s",port,ip,path));
		int err=res->exitcode;
		string s=res->stdout;
		if(err){
			throw(({"ssh get_dir fail.\n",backtrace()}));
		}
		return filter(s/"\n",`!=,"");
	}
	int rm(string path)
	{
		mapping res=Process.run(sprintf("ssh -p %d %s rm -r %s",port,ip,path));
		int err=res->exitcode;
		string s=res->stdout;
		if(err){
			throw(({"ssh rm fail.\n",backtrace()}));
		}
		return 1;
	}
	int mkdirhier(string path)
	{
		mapping res=Process.run(sprintf("ssh -p %d %s mkdir -p %s",port,ip,path));
		int err=res->exitcode;
		string s=res->stdout;
		if(err){
			throw(({"ssh mkdir -p fail.\n",backtrace()}));
		}
		return 1;
	}
	int write_file(string path,string data)
	{
		object file=Process.popen(sprintf("ssh -p %d %s cat \\> %s",port,ip,path),"w");
		file->write(data);
		file->close("w");
		string res=file->read();
		if(res!=""){
			werror("res=%O\n",res);
			throw(({"ssh write_file fail.\n",backtrace()}));
		}

		return sizeof(data);
	}
	string read_file(string path)
	{
		mapping res=Process.run(sprintf("ssh -p %d %s cat %s",port,ip,path));
		int err=res->exitcode;
		string s=res->stdout;
		werror("err=%d s=%O\n",err,s);
		if(err){
			//throw(({"ssh read_file fail.\n",backtrace()}));
			return 0;
		}
		return s;
	}
}

object gdbm(string file)
{
	string user,ip;
	int port;
	if(sscanf(file,"ssh://%s@%s:%d/%s",user,ip,port,file)==4){
		return ssh_gdbm(ip,port,user,file);
	}else{
		return fs_gdbm(file);
	}
}

int main(int argc,array argv)
{
	//write("%s\n",hashpath(argv[1]));

	//object ob=fs_gdbm("var/fakegdbm/test");
	/*
	for(int i=0;i<100;i++){
		ob[""+i+random(100000)]="good";
	}
	int count;
	for(string key=ob->firstkey();key;key=ob->nextkey(key)){
		werror("key=%s\n",key);
		count++;
	}
	werror("count=%O\n",count);
	*/
}
