#define DEBUG/*{{{*/

#define ABORT() throw(({"ERROR\n",backtrace()}))
#define assert(EXP) ((EXP)||ABORT())

#ifdef DEBUG
#define ASSERT(EXP) assert(EXP)
#endif/*}}}*/
#include "include/defines.h"
inherit "inherit/dbase.pike";

//! class of GLOBALD
//!
//! 用于构造GLOBALD

//mapping players=([]);
//mapping sessions=([]);
//mapping subglobalds=([]);
//mapping cmds=([]);
mapping tmp=([]);
int start_time=time();
//multiset path2dbasetype=(<>);
//multiset global_external_setup_flags=(<>);

object init_thread=Thread.this_thread();
Thread.Mutex mutex=Thread.Mutex();
mixed global_lock=mutex->lock();


/*
int subglobaldp(string key)
{
	return Stdio.is_file(Stdio.append_path("var/globalds",key+".dat"));
}

object load_subglobald(string key,int|void nocreate)
{
	if(nocreate&&!subglobaldp(key))
		return 0;
	mkdir("var/globalds");
	if(subglobalds[key]==0){
		subglobalds[key]=this_program(key,1);
		subglobalds[key]->path2dbasetype=path2dbasetype;
	}
	return subglobalds[key];
}
*/

/*void register_path_dbasetype(string curr_namespace,array path) DBASETYPE 已被废止
{
	if(path[0]!="/"){
		path=({"/",curr_namespace,})+path;
	}
	path2dbasetype[encode_value_canonic(path)]=1;
}*/
private string save(){
	//clear_functions(({"/"}));
	mixed e=catch{
		mixed v=encode_value(data,codec);
		ASSERT(v);
		//werror("globald: %O\n",decode_value(v,codec));
		return v;
	};
	if(e){
		werror("%O\n",data);
		throw(e);
	}
}
private int auto_save_flag;
void auto_save()/*{{{*/
{
	//werror("cwd=%s\n",getcwd());
	//werror("globald auto_save\n");
	//data["time"]+=" "*1024;
	if(auto_save_flag==0){
		safe_write_file(savefile,save());
#ifndef __NT__
		chown(savefile,WORKING_UID,WORKING_GID);
#endif
		call_out(auto_save,15*60);
	}
	auto_save_flag=1;
}/*}}}*/

//#ifndef __NT__
//#include "fuse.pike"
//#endif

string savefile;
string key;
string varpath="var";

/*void setup_key(string _key)
{
	key=_key;
	string file=Stdio.append_path("var/globalds",_key+".dat");
	string path=Stdio.append_path("var/globalds",_key+".d");
	if(savefile){
		mv(savefile,file);
		mv(varpath,path);
	}
	mkdir(Stdio.append_path("var/globalds",_key+".d"));
	varpath=Stdio.append_path("var/globalds",_key+".d");
	savefile=file;
}
*/

void create(string|void _key,int|void nofuse)/*{{{*/
{
	ASSERT(_key==0);
	if(_key==0){
		string file;
		file="var/globald.dat";
		savefile=file;
	}else{
		//setup_key(_key);
	}
	string val=Stdio.read_file(savefile);
	if(val){
		mapping m=decode_value(val,codec);
		//ASSERT(m);
		if(m){
			data=m;
		}
	}

	auto_save();
	/*
#ifndef __NT__
	if(!nofuse){
		Process.system("umount var/globald");

		Thread.Thread(Fuse.run,Operations(),({"globald.pike","var/globald",
					"-d",
					"-f","-o","default_permissions,allow_other"}));
	}
#endif
*/
}/*}}}*/

#if 0
#undef GLOBALD
#define GLOBALD global::this
void save_dbasetypes()
{
	ENTER(sessions["stdin"])
	foreach(path2dbasetype;string key;int one){
		array path=decode_value(key);
		array|mapping m=query(path);
		/* 打算废弃 DBASETYPE 因此 readonly 和 dirty 也废弃了
		foreach(m;string key;mapping m){
			//ASSERT_TRUE(mappingp(m),({path,key,m})); //_id_,_ctime_,...
			if(mappingp(m)){
				if(m->readonly==0||m->dirty==1){
					m->dirty=0;
					object ob=sessions["stdin"]->load_command("fuse")->query(path+({m->_id_}));
					ob->force_save();
				}
			}
		}
		*/
		if(arrayp(m)){
			set(path,({}));
		}else{
			ASSERT_TRUE(mappingp(m),m);
			set(path,([]));
		}
	}
	LEAVE();
}
#endif
void destroy()/*{{{*/
{
	//Process.system("umount var/globald");
	//save_dbasetypes();
	/*foreach(subglobalds;string key;object ob){
		destruct(ob);
	}
	*/
	werror("save globald.dat...\r\n");
	safe_write_file(savefile,save());
}/*}}}*/
