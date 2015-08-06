mapping servers=([]);
string server;
int time_out;
int debug_mode;
void cb(Protocols.HTTP.Server.Request r)
{
	mapping access_info=([]);
	mapping m=([]);
	foreach(indices(r),string k){
		if(object_variablep(r,k)){
			m[k]=r[k];
		}
	}
	string data="";
	void mywrite(mixed ... args)
	{
		data+=sprintf(@args);
	};

	//access_info["request_raw"]=string_to_utf8((Protocols.HTTP.uri_decode(m->request_raw)));
	access_info["request_raw"]=m->request_raw;
	[access_info["ip"],access_info["port"]]=(m->my_fd->query_address()||"- -")/" ";

	object now=Calendar.ISO->now();
	access_info["date"]=sprintf("%d/%s/%d:%s",now->month_day(),now->month_name(),now->year_no(),now->format_todz_iso());

	//Stdio.write_file("/tmp/httpd.pike.info",sprintf("m=%O\n",m));
	string curr_server=server;
	if(m->request_headers->host){
		string host=(m->request_headers->host/":")[0];
		access_info["host"]=host;
		if(servers[host])
			curr_server=servers[host];
	}
	mapping res;
	int flag_async_done;
	mixed call_out_id;
	//float begin_time=time(2);
	int begin_time=gethrtime();
	mapping async_finish(mapping res,void|mapping extra_loginfo)/*{{{*/
	{
		//float end_time=time(2);
		int end_time=gethrtime();
		//werror("httpd debug: %O %O %d",res,data,flag_async_done);
		if(flag_async_done==0){
			flag_async_done=1;
			if(call_out_id) remove_call_out(call_out_id);

			string path;

			mixed e=catch{

			res=res||([]);
			path=ob2path[curr_server];
			//master()->handle_error(({"DEBUG",backtrace()}));
			if(res->error==0&&sizeof(data)==0&&res->data==0&&res->file==0){
				//werror("path=%O\n",path);
				string p=m->not_query;
				if(has_prefix(p,"/")){
					p=p[1..];
				}
				string filename=combine_path(path,"htdocs",p);
				if(!Stdio.is_file(filename)){
					if(has_suffix(filename,"/")||Stdio.is_dir(filename)){
						if(Stdio.is_file(combine_path(filename,"index.html")))
							filename=combine_path(filename,"index.html");
						else if(Stdio.is_file(combine_path(filename,"index.htm")))
							filename=combine_path(filename,"index.htm");
					}
				}
				if(!Stdio.is_file(filename)){
					string htdocs_d=combine_path(path,"htdocs.d");
					if(Stdio.is_dir(htdocs_d)){
						array a=get_dir(htdocs_d);
						if(a==0){
							werror("Error: can't read dir %s\n",htdocs_d);
						}else{
							foreach(a,string s){
								filename=combine_path(htdocs_d,s,p);
								if(Stdio.is_file(filename)){
									break;
								}
							}
						}
					}
				}

				if(Stdio.is_file(filename)){
					if(search(filename,".nocache.")>=0){
						res->extra_heads=res->extra_heads||([]);
						res->extra_heads["Cache-Control"]="no-cache, must-revalidate";
						res->extra_heads["Expires"]="Thu, 01 Dec 1994 16:00:00 GMT";
					}
					res->type=Protocols.HTTP.Server.filename_to_type(filename);
					res->file=Stdio.FILE(filename);
					res->length=Stdio.file_size(filename);
				}else{
					werror("INFO: file %O not found.\n",filename);
					res->error=404;
				}
			}
			if(res->data==0&&res->file==0){
				res->data=data;
				res->length=sizeof(data);
				if(sizeof(data)&&res->type==0){
					res->type="text/html";

				}
			}
			if(res->extra_heads&&res->extra_heads["Location"]){
				if(res->error==0||res->error==404)
					res->error=302;
			}
			res->error=res->error||200;

			access_info["stat"]=res->error;
			access_info["length"]=res->length;
			access_info["type"]=res->type;
			access_info["referer"]=m->request_headers->referer;
			access_info["user-agent"]=m->request_headers["user-agent"];

			res->curr_server=res->server||"pikehttpd";
			//res->type=res->type||"text/html";

			};
			if(e){
				res=res||([]);
				res->error=500;
				res->data=describe_backtrace(e);
				res->length=sizeof(res->data);
				werror("ERROR:\n%s",res->data);
			}
			//werror("res=%O",res);
			//werror("httpd debug: %O",res);
			if(debug_mode){
				werror("httpd: response=%O\n%s\n",res-(["data":0]),res->data||"");
			}
			r->response_and_finish(res);

			string s=(m->not_query/"/")[-1];
			if(access_info["type"]==0&&s!=""){
				//werror("s=%s\n",s);
				access_info["type"]=Protocols.HTTP.Server.filename_to_type(s);
				//werror("s=%s done\n",s);
			}


			string t=sprintf("%s - - [%s] %s %d %d %O %O %O %.8fs",
					access_info->ip,
					access_info->date,
					"\""+replace(access_info->request_raw,(["\\":"\\\\","\n":"\\n","\"":"\\\""]))+"\"",
					access_info->stat,
					access_info->length,
					access_info->referer||"-",
					access_info["user-agent"],
					access_info["host"]||"-",
					(end_time-begin_time)/1000000.0,
			      );

			if(extra_loginfo){
				foreach(sort(indices(extra_loginfo)),string k){
					t+=sprintf(" %s=%s",k,
							"\""+replace(extra_loginfo[k],(["\\":"\\\\","\n":"\\n","\"":"\\\""]))+"\"",
						  );
				}
			}

			t+="\n";
			if(path)
				Stdio.append_file(combine_path(path,"access_log"),t);
			else
				Stdio.append_file("access_log",t);
			mapping stat2escq=([2:"[32m", /* green */
					3:"[34m", /* blue */
					4:"[36m", /* cyan*/
					5:"[31m", /* red */
					]);
			mapping type2escq=(["text/html":"[4m"]);
			werror("%s",(stat2escq[access_info->stat/100]||"")
					+(type2escq[access_info->type]||"")
					+t
					+"[0m");
		}
	};/*}}}*/
	void async_finish_time_out()/*{{{*/
	{
		werror("INFO: time out.\n");
		async_finish((["error":500]));
	};/*}}}*/
	if(debug_mode){
		werror("httpd: request=%O\n",m);
	}
	if(curr_server==0){
		res=res||([]);
		werror("INFO: virtual host not found.\n");
		res->error=404;
	}else{
		mixed e=catch{
			string old=getcwd();
			cd(ob2path[curr_server]);
			object server_ob=(object)curr_server;
			if(server_ob->is_loader)
				server_ob=server_ob->real_object;
			werror("call handle_request\n");
			res=server_ob->handle_request(m,mywrite,async_finish);
			werror("call handle_request done\n");
			cd(old);
		};
		if(e){
			res=res||([]);
			res->error=500;
			res->data=describe_backtrace(e);
			res->length=sizeof(res->data);
			werror("ERROR:\n%s",res->data);
		}
	}
	//if(res->data&&sizeof(res->data)>1024)
		//werror("%O",res-(["data":0]));
	//else
		//werror("%O",res);
	if(res){
		async_finish(res);
	}else if(flag_async_done==0){
		call_out_id=call_out(async_finish_time_out,time_out);
	}
	//async_finish(res);
}
mapping ob2path=([]);
int quit_flag;
int main(int argc,array argv)
{
	add_constant("quit",lambda(){quit_flag=1;});
	add_constant("query_quit_flag",lambda(){return quit_flag;});
	add_constant("HTTPD",this);
	mapping args=Arg.parse(argv);
	if(args["h"]||args["help"]||sizeof(args[Arg.REST])==0){
		werror("usage: httpd.pike [options] [hostname1]:app1.pike[:listen_ip:listen_port[:connect_ip:connect_port[:args_for_setup]]] ... [defaultapp.pike]\n"
#"-h,	--help			show this help.\n"
#"-d,	--debug			dump request and response.\n"
#"	--time-out=n		set timeout, default is 30s.\n"
#"	--port=n		set port, default is 80 if posible, otherwise 8080.\n"
		     );
		return 0;
	}
	time_out=(int)(args["time-out"])||30;
	//int user_port=(int)(args["port"]);
	string user_ports=(args["port"]);
	array ports=({});
	if(user_ports){
		foreach(user_ports/":",string s){
			ports+=({(int)s});
		}
	}
	debug_mode=(args["d"]||args["debug"])?1:0;
	foreach(args[Arg.REST],string s0){
		string host_name,s;
		string ip;int port;
		string host;string|int remote_port;
		string args_for_setup;
		sscanf(s0,"%s:%s:%s:%d:%s:%s:%s",host_name,s,ip,port,host,remote_port,args_for_setup)==7||
		sscanf(s0,"%s:%s:%s:%d:%s:%s",host_name,s,ip,port,host,remote_port)==6||
		sscanf(s0,"%s:%s:%s:%d",host_name,s,ip,port)==4||
		sscanf(s0,"%s:%s",host_name,s)==2||
		sscanf(s0,"%s",s);
		if(host_name=="")
			host_name=0;
		if(host=="")
			host=0;

		remote_port=(int)remote_port;

		werror("host_name=%O\n",host_name);
		werror("server=%O\n",s);
		werror("ip=%O\n",ip);
		werror("port=%O\n",port);
		werror("host=%O\n",host);
		werror("remote_port=%O\n",remote_port);
		werror("args_for_setup=%O\n",args_for_setup);

		string path=combine_path(@explode_path(combine_path(getcwd(),s))[..<1]);
		string old=getcwd();
		cd(path);
		object ob=(object)s;
		if(args_for_setup)
			werror("args_for_setup=%O\n",args_for_setup/",");
			ob->setup(@(args_for_setup/","));

		if(ob->is_loader){
			werror("loader=%O\n",ob);
			ob=ob->real_object;
			werror("real_object=%O\n",ob);
		}
		if(ob->connect&&host){
			ob->connect(host,remote_port);
		}
		if(ob->listen&&port){
			if(ip=="")
				ip=0;
			ob->listen(ip,port);
		}
		cd(old);
		ob2path[s]=path;
		if(ob){
			if(host_name)
				servers[host_name]=s;
			else
				server=s;
		}
	}
	int port=8080;
#ifndef __NT__
	if(System.geteuid()==0)
		port=80;
#endif
	//if(user_port) port=user_port;
	if(sizeof(ports)==0){
		ports+=({port});
	}
	array listeners=({});
	foreach(ports,int port){
		listeners+=({Protocols.HTTP.Server.Port(cb,port)});
	}
	signal(signum("SIGINT"),lambda(){quit_flag=1;});
	signal(signum("SIGTERM"),lambda(){ quit_flag=1; });

	while(!quit_flag){
		Pike.DefaultBackend(0.1);
		multiset done=(<>);
		foreach(values(servers)+({server}),string s){
			if(!done[s]&&s){
				object ob=(object)s;
				if(ob->is_loader)
					ob=ob->real_object;
				if(ob->on_idle)
					ob->on_idle();
			}
		}
	}
	multiset done=(<>);
	foreach(values(servers)+({server}),string s){
		if(!done[s]&&s){
			werror("DESTRUCT %s\n",s);
			done[s]=1;
			object ob=(object)s;
			if(ob->is_loader){
				destruct(ob->real_object);
			}
			destruct(ob);
		}
	}
	//werror("final gc...");
	//gc();
}

/* {{{
[0m
--
reset; clears all colors and styles (to white on black)

[1m
--
bold on (see below)

[3m
--
italics on

[4m
--
underline on

[7m
2.50
inverse on; reverses foreground & background colors

[9m
2.50
strikethrough on

[22m
2.50
bold off (see below)

[23m
2.50
italics off

[24m
2.50
underline off

[27m
2.50
inverse off

[29m
2.50
strikethrough off

[30m
--
set foreground color to black

[31m
--
set foreground color to red

[32m
--
set foreground color to green

[33m
--
set foreground color to yellow

[34m
--
set foreground color to blue

[35m
--
set foreground color to magenta (purple)

[36m
--
set foreground color to cyan

[37m
--
set foreground color to white

[39m
2.53
set foreground color to default (white)

[40m
--
set background color to black

[41m
--
set background color to red

[42m
--
set background color to green

[43m
--
set background color to yellow

[44m
--
set background color to blue

[45m
--
set background color to magenta (purple)

[46m
--
set background color to cyan

[47m
--
set background color to white

[49m
2.53
set background color to default (black)

	}}}	*/

