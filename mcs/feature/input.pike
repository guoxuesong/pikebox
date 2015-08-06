MIXIN Session{
extern mapping q;
extern function write;
extern int command(string cmd,array args);
//extern string html_encode_string(string);
extern int accept_wml;

private mapping input_handles=([]);
private mapping key_handle=([]);

private int sn;


class InputOptions{
	string prompt;
	string cmd;
	string submit;
	string cancel;
	int newwendow;
	int br;
	mapping entities;
};

string input_command(string prompt,string cmd,mapping|void options,mapping|void entities,string|void handle)/*{{{*/
{
	string key=sprintf("%O",({prompt,cmd,options,entities}));
	handle=handle||key_handle[key];
	InputOptions o=InputOptions();
	o->prompt=prompt;
	o->cmd=cmd;
	foreach(options||([]);string k;mixed v){
		o[k]=v;
	}
	o->entities=entities||([]);
	handle=handle||sprintf("%d",++sn);
	if(input_handles[handle]==0){
		input_handles[handle]=o;
	}
	key_handle[key]=handle;
	return handle;
}/*}}}*/
	PUBLIC on_input(mixed ... args)/*{{{*/
	{
		//string args_str=join(args," ");
		mapping q1=([]);
		foreach(q;string k;string v)
		{
			if(v=="")
				v="-";
			string h;
			if(sscanf(k,"input%s",h)){
				string name=String.hex2string(h);
				q1[name]=v;
			}
		}
		array fields=list_fields(args);
		mapping m=([]);
		foreach(fields,string s){
			string name,value;
			sscanf(s,"%s:%s",name,value);
			string type;
			sscanf(name,"%s %s",type,name);
			if(q1[name]){
				m[sprintf("[%s]",s)]=q1[name];
			}else{
				m[sprintf("[%s]",s)]=value;
			}
		}
		array a=map(args,replace,m);
		/*args_str=replace(args_str,m);
		werror("args_str=%s\n",args_str);
		array a=split(args_str," ");*/
		werror("a=%O\n",a);
		string cmd=a[0];
		return command(cmd,a[1..]);
	}/*}}}*/
	private array list_fields(array args)/*{{{*/
	{
		array fields=({});
		foreach(args,string arg){
			/*
			array a1=arg/"[";
			foreach(a1[1..],string s){
				fields+=({(s/"]")[0]});
			}
			*/
			if(sizeof(arg)&&arg[0]=='['&&arg[-1]==']'){
				string key,data;
				if(sscanf(arg[1..<1],"%s:%s",key,data)==2){
					fields+=({arg[1..<1]});
				}
			}
		}
		return fields;
	}/*}}}*/
private string action_command(string name,string cmd,int|void post,string|void uri)/*{{{*/
{
	if(uri==0)
		uri="./";
	string res="";
	if(!accept_wml){
		res+=sprintf("<form action='%s' method='%s' style='display:inline;'>",html_encode_string(uri),post?"post":"send");
		res+=sprintf("<input type='hidden' name='cmd' value='%s' />",html_encode_string(cmd));
		res+=sprintf("<input style='display:inline;' type='submit' value='%s'/>",html_encode_string(name));
		res+=sprintf("</form>");
	}else{
		res+="<anchor><go href='"+uri+"'>";
		res+="<postfield name='cmd' value='"+cmd+"' />";
		/*foreach(input,string s){
			out+="<postfield name=\""+s+"\" value=\"$("+s+")\" />";
		}*/
		res+="</go>"+name+"</anchor>\n";
	}
	return res;
}/*}}}*/
	private int input_fields(string args_str,array fields,string submit,string cancel,int br,int newwindow)/*{{{*/
	{
		if(!accept_wml){
			if(!newwindow){
				write("<form target=\"_self\" action='./' method='post' style='display:inline;'>");
			}else{
				write("<form action='./' method='post' style='display:inline;' target=_blank>");
			}
			write("<input type='hidden' name='cmd' value='on_input %s' />",html_encode_string(args_str));
		}
		/*
		input+=({name});
		if(type=="passwd")
			out+=sprintf("<input type=\"password\" name=\"%s\" maxlength=\"127\" emptyok=\"false\" />",name);
		else if(type=="int")
			out+=sprintf("<input format=\"*N\" name=\"%s\" maxlength=\"127\" emptyok=\"false\" />",name);
		else
			out+=sprintf("<input name=\"%s\" maxlength=\"127\" emptyok=\"false\" />",name);
			*/

		array input=({});

		foreach(fields,string s){
			string name,value;
			sscanf(s,"%s:%s",name,value);
			string type;
			sscanf(name,"%s %s",type,name);
			input+=({name});
			if(value=="-")
				value="";
			else if(value=="@"){
				value="";
				if(type==0)
					type="password";
			}
			if(type==0)
				type="text";
			write("%s:<input type='%s' name='%s' value='%s'/>%s\n",html_encode_string(name),html_encode_string(type),"input"+String.string2hex(name),html_encode_string(value),br?"<br/>":"");
		}
		if(!accept_wml){
			write("<input type='submit' value='%s'/>",html_encode_string(submit||"确定"));
			write("</form>");
		}else{
			write("<anchor><go href='%s'>",html_encode_string("./"));
			write("<postfield name='cmd' value='%s' />",html_encode_string(sprintf("on_input %s",args_str)));
			foreach(input,string s){
				write("<postfield name=\"%s\" value=\"$(%s)\" />",html_encode_string(s),html_encode_string(s));
			}
			write("</go>%s</anchor>\n",html_encode_string(submit||"确定"));
		}
		if(cancel&&cancel!="-"){
			write("%s",action_command(cancel,"noop"));
		}
	}/*}}}*/
PUBLIC input(string input_handle,mixed ... args)/*{{{*/
{
	object option=input_handles[input_handle];

	args=map(args,lambda(string s){
			foreach(option->entities;string k;function f){
				string res="";
				int p=0;
				while(p>=0){
					string kk="$("+k+":";
					int pos=search(s,kk,p);
					if(pos>=0){
						res+=s[p..pos-1];
						int epos=search(s,")",pos);
						if(epos>=0){
							string kkk=s[pos..epos];
							//werror("kkk0=%O\n",kkk);
							kkk=kkk[2..<1];
							//werror("kkk=%O\n",kkk);
							array a=split(kkk,":");
							//werror("a=%O\n",a);
							res+=f(@a[1..]);
							p=epos+1;
						}else{
							break;
						}
					}else{
						res+=s[p..];
						break;
					}
				}
				s=res;
			}
			return s;
			}
	);

	string args_str=join(split(option->cmd," ")+args," ");
	array fields=list_fields(args);
	if(option->prompt&&sizeof(option->prompt))
		write("%s<br/>\n",option->prompt);
	return input_fields(args_str,fields,option->submit,option->cancel,option->br,option->newwendow);
}/*}}}*/
	PUBLIC close_window(mixed ... args)/*{{{*/
	{
		int err;
		mixed e=catch{
			err=command(args[0],args[1..]);
			if(err){
				werror("ERROR: 命令 %s 失败。\n",join(args," "));
			}
		};
		if(!e){
			if(err>0){
				write("<script language=\"javascript\"  type=\"text/javascript\">alert(\"错误：操作失败。\");window.close();</script>");
			}else{
				write("<script language=\"javascript\"  type=\"text/javascript\">window.close();</script>");
			}
		}else{
			master()->handle_error(e);
			write("<script language=\"javascript\"  type=\"text/javascript\">alert(\"错误：没有权限。\");window.close();</script>");
		}

	}/*}}}*/
PUBLIC noop()/*{{{*/
{
}/*}}}*/
}