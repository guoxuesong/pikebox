#define DEBUG/*{{{*/

#define ABORT() throw(({"ERROR\n",backtrace()}))
#define assert(EXP) ((EXP)||ABORT())

#ifdef DEBUG
#define ASSERT(EXP) assert(EXP)
#endif/*}}}*/
IMPORT(F_THIS_SESSION);
IMPORT(F_NOSAVE_PLAYER);
//IMPORT(F_FUSE);
//IMPORT(F_CALL_OUT);
IMPORT(F_LOAD_GDBM);
//IMPORT(F_DBASE);
IMPORT(F_DBASEITEM);
IMPORT(F_CMDS);
IMPORT(F_EASYHTML);
IMPORT(F_HTMLTOOL);
IMPORT(F_HTTPSESSION);
IMPORT(F_INPUT);
IMPORT(F_LOGIN);
//IMPORT(F_PAGES);
IMPORT(F_SYMBLE_STREAM);
//IMPORT(F_TAGS);
IMPORT(F_TASKS);
//IMPORT(F_TIMEOUT);
IMPORT(F_WIDGET);
IMPORT(F_SYNCER);
//IMPORT(F_LIST_WIDGETS);
IMPORT(F_ASYNC_WIDGET);
IMPORT(F_LOAD_GDBM);
IMPORT(F_LIST_ACTIONS);
IMPORT(F_WIDGET_PROMPT);
IMPORT(F_WIDGET_GWT);
//IMPORT(F_WIDGET_CLIENT);
//IMPORT(F_CURRPATH);

IMPORT(F_INFINITE_SCROLL);
IMPORT(F_INFINITE_LIST);

IMPORT(F_VIEWSTACK);
//IMPORT(F_GEOWEIBO);
//IMPORT(F_LOCATION_SERVER);
//IMPORT(F_SESSION_PROPERTIES);

//IMPORT(F_APPEXAMPLE);

#include "include/defines.h"

mapping players=([]);
mapping sessions=([]);

string PATH="bin";

constant PROMPT_FAIL="错误：操作失败。";
constant PROMPT_DENY="错误：没有权限。";

mapping type_resolver=([ARGTYPE(Player):"players",ARGTYPE(Widget):WIDGETD->id2widget]);

string md5key=String.trim_all_whites(Stdio.read_file("var/md5key.txt"));

CLASS Player{
	inherit "dbase.pike";
	inherit "timeout.pike";
	inherit "tags.pike";

	//need by f_login.player
	string name;

	//need by f_timeout:
	protected int timeout=60*60*12+1;
	protected string workingdir=cwd;
	protected mapping container=players;
	protected array globald_path=0;
	protected string key="name";

	//others:
	protected int start_time=time();

	void create(string|void _data){::create();if(_data) data=decode_value(_data);}
	void destroy() { logout_notify(); }
	void rename_notify(string oldname,string newname){}
	string save(){return encode_value_canonic(data);}
}

string default_command;

CLASS Session{
	inherit "timeout.pike";

#ifndef __NT__
	//inherit f_banchmark_mode::Session;
#endif

	//extern need by f_cmds:
	//curr_user is in f_login
	string super_user="admin";
	object this_player()/*{{{*/
	{
		return players[curr_user];
	}/*}}}*/
	protected mapping players=global::this->players;

	//need by f_input:
	//command() is in f_cmds
	//mapping q is in f_httpsession
	function write=symble_write;

	//need by f_login:
	protected program player_class=global::this->Player;

	//need by f_timeout:
	protected int timeout=60*60*12;
	protected string workingdir=cwd;
	protected mapping container=sessions;
	protected array globald_path=({"/","sessions"});
	protected string key="id";

	/*
	//need by f_pages:
	//linked_command() is in f_htmltool
	protected int pagelimit=10*1024;
	*/

	//need by f_htmltool
	//accept_wml is in f_easyhtml

	//need by f_widget_gtk
	//protected int client_mode_flag=0;

	//others
	string id;
	string ip;
	int connect_time=time();
	int is_socket_session;
	int is_client_session;
	int is_console_session;
	//function gen_uniq_id=global::this->gen_uniq_id;
	//string content_type;
	//string filename;
	int cmd_pos=0;

	/*void set_content_type(string t)
	{
		content_type=t;
	}

	void set_filename(string t)
	{
		filename=t;
	}*/

	void create(string sessionid)/*{{{*/
	{
		werror("create session %O\n",sessionid);
		::create();
		id=sessionid;
	}/*}}}*/

	PUBLIC noop(mixed ... args)
	{
		write("# hello world!\n");
	}
	/*PUBLIC location(string url)
	{
		extra_heads["Location"]=url;
		return -1; //阻止empty_notify
	}*/
	int server_mode_flag=0;
	PUBLIC start_server_mode()
	{
		server_mode_flag=1;
	}
	/*SUPERUSER look(string cmd)
	{
		mapping widgets=list_widgets(cmd);
		werror("list_widgets return %O\n",widgets);
		Widget p=vertical_panel(({}));
		foreach(widgets;string key;Widget w){
			p->add(text(key));
			p->add(w);
		}
		show(p,cmd);
	}*/
	/*PUBLIC _error_(string line,mixed e)
	{
		throw(e);
		//write("# %s %s\n",PROMPT_DENY,line);
	}
	PUBLIC _fail_(string line,int err)
	{
		write("# %s %s\n",PROMPT_FAIL,line);
	}
	*/

	void set_default_command(string cmd)
	{
		default_command=cmd;
	}

	//int query_quit_flag(){return quit_flag;}
	//void reset_quit_flag(){quit_flag=0;}
	//void set_quit_flag(){quit_flag=1;}

	PUBLIC debug()
	{
		return command("look_view",({"WORKFLOW_MANAGED.look_workflows","default","00000001"}));
	}
}

string expires_date(int t)/*{{{*/
{
        string s=Protocols.HTTP.Server.http_date(t);
        int pos0=search(s," ");
        int pos1=search(s," ",pos0+1);
        s[pos1]='-';
        int pos2=search(s," ",pos1+1);
        s[pos2]='-';
        return s;
}/*}}}*/


int command(Session session,string line,/*function|void write,mapping|void q,mapping|void request_headers,mapping|void extra_heads,string|void not_query*/)/*{{{*/
{
	werror("command: %s\n",line);

	/*write=write||predef::write;*/
	//session->touch();

	array argv=split(line," ")||({line});
	//werror("command argv: %O\n",argv);
	string cmd;
	if(session->cmd_pos<sizeof(argv))
		cmd=argv[session->cmd_pos];
	//else
		//cmd="_error_";
	argv=({cmd})+argv[..session->cmd_pos-1]+argv[session->cmd_pos+1..];
	//function old_write=session->real_write;
	//session->real_write=write||predef::write;
	//session->q=q;
	//session->not_query=not_query;
	//session->extra_heads=extra_heads||([]);
	//session->request_headers=request_headers||([]);
	int err;
	mixed e=catch{
		err=session->command(cmd,argv[1..]);
		if(err>0){
			werror("ERROR: 命令 %s 失败.\n",line);
		}
	};
	if(!e){
		if(err>0){
			mixed e=catch{
				session->command("_fail_",({line,err}));
			};
			if(e){
				master()->handle_error(e);
			}
		}
	}else{
		master()->handle_error(e);
		mixed ee=catch{
			session->command("_error_",({line,e}));
		};
		if(ee){
			//master()->handle_error(e);
			master()->handle_error(ee);
		}
		//write("%s",PROMPT_DENY);
	}
	//session->export_symble_clear(write||predef::write);
	//session->real_write=old_write;
	object player=session->this_player();
	if(player&&functionp(player->touch)){
		player->touch();
	}
	if(functionp(session->touch)){
		session->touch();
	}
	werror("command return.\n");
	return err;
}/*}}}*/

CLASS RequestHandler{
#ifndef __NT__
	//inherit f_banchmark_mode::RequestHandler;
#endif
	//need by f_login.request_handler.pike
	string SESSION_ID_COOKIE="MySessionID";
	string LOGIN_COOKIE="MyLogin";
	int autologin_timeout=3600*24*365*5;
	int session_timeout=60*60*12;

	//need by f_banchmark_mode.request_handler.pike

	int banchmark_enable=0;
	int banchmark_level=100;

	//others
	string login_cmd=0;
	multiset set_coockies=(<>);
	string data="";
	mapping m=([]);
	string sessionid=0;
	object session=0;
	string type=0;

	//function gen_uniq_id=global::this->gen_uniq_id;
	function expires_date=global::this->expires_date;

	mapping handle_request(mapping mm,function write,function async_finish)/*{{{*/
	{
		login_cmd=0;
		set_coockies=(<>);
		m=mm;
		data="";
		//type=0;


		object g=MODULED;
		g->apply_function(this,"prelogin_before_f_login");
		g->apply_function(this,"prelogin_f_login");
		g->apply_function(this,"prelogin_after_f_login");
		g->apply_function(this,"prelogin");

		//werror("%O",m->request_headers);
		mapping res=(["extra_heads":([])]);
		ASSERT(m->extra_heads==0);
		m->extra_heads=res->extra_heads;
			

		//constant LOGIN_COOKIE="MyLogin";
		sessionid=m->cookies[SESSION_ID_COOKIE];
		if(sessionid==0){
			sessionid=gen_uniq_id("session");
		}
		/*mapping fake_q_out=(["write":lambda(array a){
				//werror("%s",a[1]);
				data+=sprintf("%s",a[1]);
				},
				]);*/
		/*m->write=lambda(mixed ... args)
		{
			data+=sprintf(@args);
		};*/

		werror("sessionid=%s\n",sessionid);
		if(sessions[sessionid]==0){
			werror("new session\n");
			sessions[sessionid]=Session(sessionid);
			//sessions[sessionid]->globald=GLOBALD;
			if(login_cmd){
				//sessions[sessionid]->q_out=fake_q_out;
				mixed e=catch{
					command(sessions[sessionid],login_cmd/*,mywrite,([]),m->request_headers*/);
				};
				if(e){
					master()->handle_error(e);
				}
			}
		}
		//sessions[sessionid]->q_out=fake_q_out;
		session=sessions[sessionid];
		//session->set_content_type(0);
		session->request=m;
		//session->request_type=m->request_type;

		if(m->my_fd->query_address())
			session->ip=(m->my_fd->query_address()/" ")[0];
		else
			session->ip="unknown";

		mapping q=m->variables;
		foreach(q;string k;string v){ //Fix PostData bug of OnBeforeNaviate2
			if(stringp(v)){
				if(has_suffix(v,"\0")){
					q[k]=v[..<1];
				}
			}
		}
		string cmd=q->cmd;
		if(cmd==0){
			if(m->not_query=="/")
				cmd=default_command||"noop";
			else if(has_prefix(m->not_query,"/cmd=")){
				sscanf(m->not_query,"/cmd=%s/",cmd);
				//m->not_query="/";
			}
		}

		g->apply_function(this,"handle_path");

		if(cmd){
			if(has_prefix(cmd,"HEX:")){
				cmd=String.hex2string(cmd[sizeof("HEX:")..]);
			}
			m->async_finish=lambda()
			{
				string data="";
				session->symble_clear(lambda(mixed ... args){data+=sprintf(@args);});
				werror("call postcmd\n");
				g->apply_function(this,"postcmd");
				werror("call postcmd done\n");
				//werror("q_out=%O\n",session->q_out);
				//session->q_out=0;
				werror("res=%O\n",res);
				res->extra_heads["Set-Cookie"]=(array)set_coockies;
				//werror("call debug_write_file\n");
				//debug_write_file("/tmp/appserver.debug.txt",data);
				//werror("call debug_write_file done\n");
				//Stdio.write_file("/tmp/appserver.debug.txt",data);
				//werror("DEBUG: %s",data);
				//werror("call write data %O\n",data);
				write("%s",data);
				//werror("%s",data);
				//werror("call write data done\n");

				res->extra_heads["Cache-Control"]="no-cache, must-revalidate";
				res->extra_heads["Expires"]="Thu, 01 Dec 1994 16:00:00 GMT";
				res->extra_heads["Last-Modified"]=Protocols.HTTP.Server.http_date(time());

				if(res->error==0&&res->extra_heads["Location"]==0)
					res->error=200; //不再搜索index.html

				//session->request_type=0;
				if(m->content_type){
					res["type"]=m->content_type;
					if(m->filename){
						res->extra_heads["Content-Disposition"]=" attachment; filename="+replace(m->filename," ","+");
					}
				}

				async_finish(res);
			};
			g->apply_function(this,"precmd");
			int err=command(session,cmd/*,mywrite,q,m->request_headers,res->extra_heads,m->not_query*/);
			if(err>=0){
				/*session->symble_clear(lambda(mixed ... args){data+=sprintf(@args);});
				if(sizeof(data)==0&&err>=0){
					data="# NO DATA\n";
					//command(session,"look",mywrite,([]),m->request_headers,res->extra_heads);
				}*/
				m->async_finish();
			}else{
				session->request=0;
				return 0;
			}
		}
		session->request=0;
		return res;
	}/*}}}*/
}

object h=RequestHandler();

function handle_request=h->handle_request;

string cwd;
//inherit "../../Sync/pinyin.pike":PINYIN;
void create()
{
	werror("appserver create.\n");
	::create();
	//GLOBALD->request_handler=RequestHandler;
	cwd=getcwd();
	//PINYIN::open("../Sync/utf8py.org");
	if(all_constants()["quit"]==0)
		add_constant("quit",lambda(){quit_flag=1;});
	if(all_constants()["query_quit_flag"]==0)
		add_constant("query_quit_flag",lambda(){return quit_flag;});
	add_constant("GLOBALD",GLOBALD);
	add_constant("PIKECROSS_VERSION",MyAppVersion);
	//add_constant("PLAYERS",players);
	//add_constant("SESSIONS",sessions);

	add_constant("listen",listen);
	add_constant("connect",connect);
	add_constant("query_connections",query_connections);
	
}

void run_rc(string _rc)/*{{{*/
{
	string rc=Stdio.read_file(_rc);
	werror("loading rc\n");
	foreach(rc/"\n",string s){
		if(!has_prefix(s,"#")){
			s=String.trim_all_whites(s);
			array a=split(s," ");
			string cmd=(a[0]/".")[0];
			if(cmd!=""){
	//werror("setup: cmd=%s\n",cmd);
				function f;
				if(sizeof(a[0]/".")>=2){
					string func=(a[0]/".")[1..]*".";
	//werror("setup: func=%s\n",func);
					object ob=sessions["stdin"]->load_command(cmd);
					f=ob[func];
				}
				else{
					f=sessions["stdin"][a[0]];
					ASSERT(f);
				}
				if(f){
	//werror("setup: found\n");
					//sessions["stdin"]->exec_external(cmd,f,a[1..]);
					//GLOBALD->curr_session=sessions["stdin"];
					THIS_SESSIOND->set_this_session(sessions["stdin"]);
					f(@a[1..]);
					//GLOBALD->curr_session=0;
					THIS_SESSIOND->set_this_session(0);
				}
			}
		}
	}
	werror("load %s done\n",_rc);
}/*}}}*/

void setup() 
{

	object session=sessions["stdin"]=sessions["stdin"]||Session("stdin");
	//session->globald=GLOBALD;
	session->is_socket_session=1;
	session->is_client_session=0;
	session->is_console_session=1;

	string user=session->super_user;
	session->curr_user=user;
	if(user){
		players[user]=players[user]||session->load_player(user)||Player();
		players[user]->name=user;
		session->save_player(user,players[user]);
	}

	//session->cmds_init();



	add_constant("APPSERVER",this);
	add_constant("APPSERVER_PROGRAM",object_program(this));

	object sample=sessions["stdin"];
	werror("Session=%O\n",Session);
	werror("indices of Session=%O\n",indices(Session));
	/*foreach(indices(Session),string key){
		werror("key=%s\n",key);
		werror("val=%O\n",Session[key]);
		//add_constant(key,Session[key]);
	}*/
	/*
	foreach(indices(sample),string key){
		if(functionp(sample[key])){
			add_constant(key,Function.curry(lambda(string key,mixed ... args){
					ASSERT(THIS_SESSIOND->this_session());
					return THIS_SESSIOND->this_session()[key](@args);
					})(key));
		}
	}
	*/
	run_rc("rc"); 
}

void setup2()
{
	run_rc("rc2"); 
}


Thread.Queue q_in=Thread.Queue();
void handle_stdin(object session)/*{{{*/
{
	object readline=Stdio.Readline();
	void handle_completions(string key)/*{{{*/
	{
		string input = readline->gettext()[..readline->getcursorpos()-1];
		array tokens=split(input," ");
		string token=tokens[-1];
		//werror("token=%O\n",token);
		array a;
		if(sizeof(tokens)==1){
			a=get_dir("bin");
			a=filter(a,has_suffix,".pike");
			a=map(a,lambda(string s){return s[..<5];});
			a=session->list_cmds()+a;
			a=Array.uniq(a);
		}else{
			a=get_dir(".");
		}
		array completions=({});
		foreach(a,string k){
			if(has_prefix(k,token)){
				completions+=({k+" "});
			}
		}
		if(sizeof(completions)>1){
			int end;
			for(int i=0;i<sizeof(completions[0]);i++){
				int bad;
				foreach(completions,string s){
					if(i<sizeof(s)&&s[i]==completions[0][i]){
						;
					}else{
						bad=1;
						break;
					}

				}
				if(bad)
					break;
				else
					end=i;
			}
			if(end&&end>sizeof(token)-1){
				completions=({completions[0][..end]});
			}
		}
		sort(completions);
		if(sizeof(completions)==1)
			readline->insert(completions[0][sizeof(token)..], readline->getcursorpos());
		else if(sizeof(completions)>1)
			readline->list_completions(completions);
	};/*}}}*/
	readline->set_prompt("> ");
	readline->enable_history(1024);
	readline->get_input_controller()->bind("\t", handle_completions);

	handle_socket(readline,session,lambda(Stdio.Readline readline,function on_idle){on_idle();return readline->read();},predef::write);
}/*}}}*/
void handle_socket(Stdio.File|Stdio.Readline file,object session,function getline,function|void write,string|void hello)/*{{{*/
{
	Thread.Queue q_out=Thread.Queue();
	void do_write()
	{
		[int err,string data]=q_out->read();
		//werror("in handle_socket: data=%O\n",data);
		/*
		if(err){
			file->write(sprintf("# ERROR %d\n",sizeof(data)));
		}else{
			file->write(sprintf("# OK %d\n",sizeof(data)));
		}
		*/
		write?write(data):file->write(data);
	};
	void on_idle()
	{
		while(q_out->size()){
			do_write();
		}
	};
	if(hello){
		q_in->write(({hello,session,q_out}));
		do_write();
	}
	string s=getline(file,on_idle);
	while(s){
		//s=String.trim_all_whites(s);
werror ("socket line: %O\n", s);
		if(!has_prefix(s,"#")){
			q_in->write(({s,session,q_out}));
			do_write();
		}
		s=getline(file,on_idle);
	}
};/*}}}*/
string getline(Stdio.File file,function on_idle){/*{{{*/
	on_idle();
	string buff="";
	string wait_byte(){
		if(file->peek){
			while(file->peek()==0){
				on_idle();
				sleep(0.1);
			}
			return file->read(1);
		}else{
			file->set_nonblocking();
			string res=file->read(1,1);
			while(res=="")
				res=file->read(1,1);
			return res;
		}
	};
	
	string s=wait_byte();
	while(s&&sizeof(s)){
		//werror("%s",s);
		buff+=s;
		if(sizeof(buff)>1&&buff[<1..]=="\r\n")
			break;
		s=wait_byte();
	}
	if(sizeof(buff)){
		ASSERT(buff[<1..]=="\r\n");
		return buff[..<2];
	}
};/*}}}*/
mapping socket2connections=([]);
void connect(string host,int port,string|void cmd_prefix,string|void data)/*{{{*/
{
	string socket=sprintf("%s:%d",host,port);
	werror("connect %s\n",socket);
	multiset set=set_weak_flag((<>),Pike.WEAK);
	socket2connections[socket]=socket2connections[socket]||set;
	Stdio.File con=Stdio.File();
	con->async_connect(host,port,lambda(int succ){
		if(!succ){
			werror("connect %s fail\n",socket);
			return;
		}
		con->set_blocking();
		//con->write("start_server_mode\n");
		sessions["socket"+con->query_fd()]=sessions["socket"+con->query_fd()]||Session("socket"+con->query_fd());
		object session=sessions["socket"+con->query_fd()];
		session->set_cmd_prefix(cmd_prefix);
		session->ip=(con->query_address()/" ")[0];
		session->is_socket_session=1;
		session->is_client_session=1;
		session->is_console_session=0;
		//session->client_mode_flag=1;
		socket2connections[socket][con]=1;
		werror("connect %s ok\n",socket);
		mixed t=Thread.Thread(handle_socket,con,session,getline);
		if(data)
			con->write("%s",data);
		});
	//return con;
}/*}}}*/
multiset query_connections(string host,int port)
{
	string socket=sprintf("%s:%d",host,port);
	if(socket2connections[socket]&&sizeof(socket2connections[socket]))
		return socket2connections[socket];
}
string listen_ip;
int listen_port;
void listen(string ip,int p,string|void cmd_prefix,string|void hello,int|void case_insensitive,int|void ssl,int|void cmd_pos)/*{{{*/
{
	if(listen_ip==0){
		listen_ip=ip;
		listen_port=p;
	}
	object port;
	if(!ssl){
		port=Stdio.Port();
	}else {
string my_certificate = MIME.decode_base64(
  "MIIBxDCCAW4CAQAwDQYJKoZIhvcNAQEEBQAwbTELMAkGA1UEBhMCREUxEzARBgNV\n"
  "BAgTClRodWVyaW5nZW4xEDAOBgNVBAcTB0lsbWVuYXUxEzARBgNVBAoTClRVIEls\n"
  "bWVuYXUxDDAKBgNVBAsTA1BNSTEUMBIGA1UEAxMLZGVtbyBzZXJ2ZXIwHhcNOTYw\n"
  "NDMwMDUzNjU4WhcNOTYwNTMwMDUzNjU5WjBtMQswCQYDVQQGEwJERTETMBEGA1UE\n"
  "CBMKVGh1ZXJpbmdlbjEQMA4GA1UEBxMHSWxtZW5hdTETMBEGA1UEChMKVFUgSWxt\n"
  "ZW5hdTEMMAoGA1UECxMDUE1JMRQwEgYDVQQDEwtkZW1vIHNlcnZlcjBcMA0GCSqG\n"
  "SIb3DQEBAQUAA0sAMEgCQQDBB6T7bGJhRhRSpDESxk6FKh3iKKrpn4KcDtFM0W6s\n"
  "16QSPz6J0Z2a00lDxudwhJfQFkarJ2w44Gdl/8b+de37AgMBAAEwDQYJKoZIhvcN\n"
  "AQEEBQADQQB5O9VOLqt28vjLBuSP1De92uAiLURwg41idH8qXxmylD39UE/YtHnf\n"
  "bC6QS0pqetnZpQj1yEsjRTeVfuRfANGw\n");

string my_key = MIME.decode_base64(
  "MIIBOwIBAAJBAMEHpPtsYmFGFFKkMRLGToUqHeIoqumfgpwO0UzRbqzXpBI/PonR\n"
  "nZrTSUPG53CEl9AWRqsnbDjgZ2X/xv517fsCAwEAAQJBALzUbJmkQm1kL9dUVclH\n"
  "A2MTe15VaDTY3N0rRaZ/LmSXb3laiOgBnrFBCz+VRIi88go3wQ3PKLD8eQ5to+SB\n"
  "oWECIQDrmq//unoW1+/+D3JQMGC1KT4HJprhfxBsEoNrmyIhSwIhANG9c0bdpJse\n"
  "VJA0y6nxLeB9pyoGWNZrAB4636jTOigRAiBhLQlAqhJnT6N+H7LfnkSVFDCwVFz3\n"
  "eygz2yL3hCH8pwIhAKE6vEHuodmoYCMWorT5tGWM0hLpHCN/z3Btm38BGQSxAiAz\n"
  "jwsOclu4b+H8zopfzpAaoB8xMcbs0heN+GNNI0h/dQ==\n");
		port=SSL.sslport();
		port->certificates = ({ my_certificate });
		port->rsa = Standards.PKCS.RSA.parse_private_key(my_key);
		class no_random {
			object arcfour = Crypto.Arcfour();

			void create(string|void secret)
			{
				if (!secret)
					secret = sprintf("Foo!%4c", time());
				arcfour->set_encrypt_key(Crypto.SHA1->hash(secret));
			}

			string read(int size)
			{
				return arcfour->crypt(replace(allocate(size), 0, "\021") * "");
			}
		};
		port->random = no_random()->read;
	}

	void accept_callback()
	{
		object con=port->accept();
		if(!con)
			return;

		con->set_blocking();
		string old_cwd=getcwd();
		cd(cwd);
		string key=con->query_fd?"socket"+con->query_fd():gen_uniq_id("socket-u");
		if(sessions[key])
			destruct(sessions[key]);
		sessions[key]=Session(key);
		object session=sessions[key];
		session->set_cmd_prefix(cmd_prefix);
		session->cmd_pos=cmd_pos;
		if(case_insensitive)
			session->set_case_insensitive();
		session->ip=(con->query_address()/" ")[0];
		session->is_socket_session=1;
		session->is_client_session=0;
		session->is_console_session=0;
		/*if(hello){
			mixed e=catch{
				command(session,hello);
			};
			if(e){
				master()->handle_error(e);
			}
		}*/
		cd(old_cwd);
		mixed t=Thread.Thread(handle_socket,con,session,getline,0,hello);
	};

	port->bind(p,accept_callback,ip);
}/*}}}*/
void on_idle()/*{{{*/
{
	//werror("on_idle\n");
	if(GLOBALD->global_lock){
		cache_begin();
		mixed e=catch{
			destruct(GLOBALD->global_lock);
			sleep(0.01);
			GLOBALD->global_lock=GLOBALD->mutex->lock();
		};
		if(e){
			master()->handle_error(e);
		}
		cache_end();
	}
	if(sessions["stdin"])
		sessions["stdin"]->touch();
	if(q_in->size()){
		string old_cwd=getcwd();
		cd(cwd);
		mixed e=catch{
			//werror("got\n");
			[string s,object session,Thread.Queue q_out]=q_in->read();
			//session->q_out=q_out;
			string data="";
			//werror("s=%O\n",s);
			if(session->want_line&&functionp(session->feed_line)){
				session->feed_line(s);
				q_out->write(({0,""}));
			}else{
				int err=command(session,s);
				string data="";
				session->symble_clear(lambda(mixed ... args){data+=sprintf(@args);});
				q_out->write(({0,data}));
			}
			//werror("data=%O\n",data);
			//q_out->write(({err,data}));
		};
		if(e){
			master()->handle_error(e);
		}
		cd(old_cwd);
	}
}/*}}}*/
int quit_flag;
/*Widget test_weak()
{
	//WIDGETD->id2widget["xixi"]=Stdio.File();
	return WIDGETD->button("xixi","ok");
}*/

int main(int argc,array argv)
{
	/*Widget wwww=test_weak();
	Debug.locate_references(wwww);
	wwww=0;
	gc();
	werror("%O",WIDGETD->id2widget);
	return 1;*/
	//werror("%O\n",players["peterpan"]->node_order);

	//werror("argv=%O",argv);

	mapping args=Arg.parse(argv);
	if(args["h"]||args["help"]){
		werror("usage: %s [options] [cmd arg ...]\n"
#"-h,	--help				Show this help.\n"
#"-d					Don't exist.\n"
#"	--connect=host[:port]		Connect to host:port and work as a client .\n"
#"	--listen=[ip:]port		Listen to ip:port and work as a server.\n"
#"	--user=user			Set curr_user to user.\n"
//#"	--apps=path			Set apps path, default is bin.\n"
				,argv[0]);
		return 0;
	}

	int noexit=args["d"];
	string connect_str=args["connect"];
	string listen_str=args["listen"];
	string user=args["user"];
	//PATH=args["apps"]||"bin";
	//werror("main PATH=%O\n",PATH);

	//werror("connect_str=%s\n",connect_str);
	array extra=args[Arg.REST];
	argv=argv[0..0]+extra;

	setup();
	setup2();

	object session=sessions["stdin"];
	if(user){
		session->curr_user=user;
		players[user]=players[user]||session->load_player(user)||Player();
		players[user]->name=user;
		session->save_player(user,players[user]);
	}
	Pike.DefaultBackend(0.0);
	if(sizeof(MODULED->errors)){
		werror("ERROR FOUND !\n");
		return 0;
	}else{
		werror("WELCOME.\n");
	}
	int main_loop_flag=1;


	if(connect_str){
		string host=connect_str;
		int port=80;
		sscanf(connect_str,"%s:%d",host,port);
		string cmdline;
		if(sizeof(argv)>1)
			cmdline=join(argv[1..]," ");
		connect(host,port,0,cmdline+"\n");
		//if(sizeof(argv)>1)
		//con->write("%s\n",join(argv[1..]," "));
		main_loop_flag=1;
	}

	if(listen_str){
		string ip=0;
		int p=(int)listen_str;
		sscanf(listen_str,"%s:%d",ip,p);
		listen(ip,p);
		main_loop_flag=2;
	}

	signal(signum("SIGINT"),lambda(){ 
			//master()->handle_error(({"SIGINT",backtrace()}));
			quit_flag++; 
			});
	signal(signum("SIGTERM"),lambda(){ 
			//master()->handle_error(({"SIGINT",backtrace()}));
			quit_flag++; 
			});

	if(!connect_str&&sizeof(argv)>1){
		if(has_suffix(argv[1],".pike")){
			argv[1]=(argv[1]/".")[..<1]*".";
		}
		int err=command(session,join(argv[1..]," "));
		/*
		if(!err)
			write("## OK\n");
		else
			write("## ERROR\n");
			*/
		if(noexit)
			main_loop_flag=1;
		else if(main_loop_flag!=2)
			main_loop_flag=0;

	}

	
	if(!noexit)
		mixed t=Thread.Thread(handle_stdin,session);

	if(main_loop_flag){
		while(!quit_flag){
			Pike.DefaultBackend(0.1);
			on_idle();
		}
	}
	destruct(this);
	sleep(3);
}

void destroy()
{
	string old_cwd=getcwd();
	cd(cwd);
	werror("save players...\r\n");
	foreach(players;string name;Player player){
		if(player->logout_notify)
			player->logout_notify();
	}
	werror("save dbasetypes...\r\n");
	//GLOBALD->save_dbasetypes();

	
	//GLOBALD->curr_session=sessions["stdin"];
	//THIS_SESSIOND->set_this_session(sessions["stdin"]);
	//destruct(GLOBALD);
	werror("quit.\r\n");
	cd(old_cwd);
	//exit(0);
}

mapping conf=([]);
