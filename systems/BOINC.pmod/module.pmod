#define DYNPROG
#include <class.h>
#define CLASS_HOST "BOINC"
class DynClass{
#include <class_imp.h>
}
void handle_request(Protocols.HTTP.Server.Request r)/*{{{*/
{
	mapping m=r->variables;
	string userid=m->userid;
	string hostid=m->hostid;
	object host=load_host((int)hostid);
	if(host) host->set_active_time(time());
	string data="";
	if(host&&host->taskkey){
		data=host->taskkey;
	}
	//werror("userid=%s user=%O data=%s\n",userid,user,data);
	r->response_and_finish(([
				"data":data,
				"error":200,
				"length":sizeof(data),
				]));
}/*}}}*/


class UniqIDStatic{
	class Static{
		int sn;
	};
}

class UniqID{
	int id=++(STATIC(UniqIDStatic)->sn);
}

class BOINCMode{
	class Interface{
	}
	class Default{
	}
}

class BOINC{
	inherit BOINCMode.Interface;
}

program default_program=CLASS(BOINC,BOINCMode.Default);

Sql.Sql db=Sql.Sql("mysql://10.0.2.4","test","work","14230628");

class User{
	int id;
	void foreach_host(function(object:int) f)/*{{{*/
	{
		object res=db->big_query("select id from host where userid=:id;",(["id":id]));
		foreach(res;int i;array a){
			object ob=load_host(a[0]);
			if(ob&&f(ob))
				break;
		}
	}/*}}}*/
}
class Host{
	int id;
	string taskkey;
	int active_time;
	void set_taskkey(string key)/*{{{*/
	{
		taskkey=key;
		db->query("update pike_host set taskkey=:key where id=:id;",(["id":id,"key":key]));
	}/*}}}*/
	void set_active_time(int t)/*{{{*/
	{
		active_time=t;
		db->query("update pike_host set active_time=:t where id=:id;",(["id":id,"t":t]));
	}/*}}}*/
}

object users=CacheLite.Cache(1024,1);
object hosts=CacheLite.Cache(1024,1);
object load_user(int id)/*{{{*/
{
	return users(id,lambda(){
			object user=User();
			foreach(db->query("select * from pike_user where id=:id;",(["id":id])),mapping m){
				user->id=(int)m->id;
				return user;
			}
			});
}/*}}}*/
object load_host(int id)/*{{{*/
{
	return hosts(id,lambda(){
			object host=Host();
			foreach(db->query("select * from pike_host where id=:id;",(["id":id])),mapping m){
				host->id=(int)m->id;
				host->taskkey=m->taskkey;
				return host;
			}
			});
}/*}}}*/
#if 0
object hostid2user(int id)/*{{{*/
{
	return hosts(id,lambda(){
			object user=User();
			werror("here\n");
			mixed v=db->query("select pike_user.id,pike_user.taskkey from pike_user inner join host on host.userid=pike_user.id where host.id=:id",(["id":(string)id]));
				werror("%O",v);
			foreach(v,mapping m){
				werror("%O",m);
				user->id=(int)m["pike_user.id"];
				user->taskkey=m["pike_user.taskkey"];
				return user;
			}
			});
}/*}}}*/
#endif
void foreach_user(function(object:int) f)/*{{{*/
{
	object res=db->big_query("select id from user;");
	foreach(res;int i;array a){
		object ob=load_user(a[0]);
		if(ob&&f(ob))
			break;
	}
}/*}}}*/
void foreach_host(function(object:int) f)/*{{{*/
{
	object res=db->big_query("select id from host;");
	foreach(res;int i;array a){
		object ob=load_host(a[0]);
		if(ob&&f(ob))
			break;
	}
}/*}}}*/

#include <args.h>
int create_database_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
	mixed e=catch{
		db->query("drop table pike_user;");
	};
	if(e){
		werror("WARNING: ignore drop table pike_user error.\n");
		master()->handle_error(e);
	}
	e=catch{
		db->query("drop table pike_host;");
	};
	if(e){
		werror("WARNING: ignore drop table pike_host error.\n");
		master()->handle_error(e);
	}
	db->query("create table pike_user (id int(11),primary key (id));");
	db->query("create table pike_host (id int(11),active_time int(11),taskkey varchar(255),primary key (id));");
	db->query("insert into pike_user (id) select id from user;");
	db->query("insert into pike_host (id,taskkey) select id,\"bfgminer\" from host;");

	foreach_host(lambda(object host){
			werror("id=%d taskkey=%O\n",host->id,host->taskkey);
			});
}
int update_database_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
	db->query("insert ignore into pike_user (id) select id from user;");
	db->query("insert ignore into pike_host (id,taskkey) select id,\"bfgminer\" from host;");
	foreach_host(lambda(object host){
			werror("id=%d taskkey=%O\n",host->id,host->taskkey);
			});
}
int pay_miners_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"YYYY-MM-DD",1)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	string day=rest[0];

	mapping user_shares=([]);
	int total;

	string data=Stdio.read_file("/home/work/eloipool/share-logfile."+day);
	if(data){
		foreach(data/"\n",string line){
			array a=line/" ";
			if(sizeof(a)==7){
				string user=a[2];
				user_shares[user]++;
				total++;
			}
		}
		object wallet=BitCoin.BitCoinWallet();
		wallet->cli="/home/work/bitcoin-testnet/bin/64/bitcoin-cli -datadir=/home/work/bitcoin-testnet/var";
		float balance=wallet->getbalance("");
		if(balance>0.0){
			foreach(SortMapping.sort(user_shares);string user;int shares){
				write("pay %s %f\n",user,balance*shares/total);
			}
		}else{
			werror("no money.\n");
		}
	}else{
			werror("file not found.\n");
	}
}
int retcode;
int run_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	DECLARE_ARGUMENT_STRING("http-ip",http_ip_flag,http_ip,"=IP");
	DECLARE_ARGUMENT_INTEGER("http-port",http_port_flag,http_port,"=PORT");
	if(Usage.usage(args,"",0)){
		return 0;
	}
	mapping conf=HANDLE_ARGUMENTS();
	object port=Protocols.HTTP.Server.Port(handle_request,conf->http_port||8080,conf->http_ip);
	retcode=-1;
}
int main(int argc,array argv)
{
	//object ob=load_user(2);
	//werror("ob=%O\n",ob);
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	DECLARE_ARGUMENT_EXECUTE("create-database",create_database_main,"");
	DECLARE_ARGUMENT_EXECUTE("update-database",update_database_main,"");
	DECLARE_ARGUMENT_EXECUTE("pay-miners",pay_miners_main,"");
	DECLARE_ARGUMENT_EXECUTE("run",run_main,"");
	if(Usage.usage(args,"",0)){
		return 0;
	}
	mapping conf=HANDLE_ARGUMENTS();
	return retcode;
}
