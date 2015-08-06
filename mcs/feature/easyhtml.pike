MIXIN Session{
	extern function write;
	extern void symble_clear(function);
	//extern string html_encode_string(string);
	extern string content_type;

	int accept_wml=0;
	void htmlfinal(string htmltitle)
	{
		string data="";
		symble_clear(lambda(mixed ... args){data+=sprintf(@args);});

		//ASSERT(data!=0);
		//werror("data=%s\n",data);
		if(!accept_wml){
			data=sprintf(
#"<!doctype html>
	<!-- The DOCTYPE declaration above will set the    -->
	<!-- browser's rendering engine into               -->
	<!-- \"Standards Mode\". Replacing this declaration  -->
	<!-- with a \"Quirks Mode\" doctype may lead to some -->
	<!-- differences in layout.                        -->

	<html><head>
	%s
	<meta http-equiv='content-type' content='text/html;charset=UTF-8' />
	<meta http-equiv='Cache-Control' content='no-cache, must-revalidate' /> 
	<meta http-equiv='Expires' content='Thu, 01 Dec 1994 16:00:00 GMT' />
	<meta http-equiv='Last-Modified' content='%s' />
	<meta name='viewport' content='width=device-width'/>
	</head><body><div id='start'>%s</div></body></html>",
	sprintf("<title>%s</title>",html_encode_string(htmltitle)),
	Protocols.HTTP.Server.http_date(time()),
	data);
			content_type="text/html;charset=UTF-8";
		}else{
			data=sprintf(
#"<?xml version='1.0' encoding='UTF-8'?><!DOCTYPE wml PUBLIC '-//WAPFORUM//DTD WML 1.1//EN' 'http://www.wapforum.org/DTD/wml_1.1.xml'><wml><head>
	<meta http-equiv='content-type' content='text/vnd.wap.wml;charset=UTF-8'/>
	<meta http-equiv='Cache-Control' content='no-cache, must-revalidate' /> 
	<meta http-equiv='Expires' content='Thu, 01 Dec 1994 16:00:00 GMT' />
	<meta http-equiv='Last-Modified' content='%s' />
	</head>
	<card id='main' title='%s'><p>%s</p></card></wml>",Protocols.HTTP.Server.http_date(time()),
	sprintf("%s",html_encode_string(htmltitle)),data);
			content_type="text/vnd.wap.wml;charset=UTF-8";
		}
		write("%s",data);
	}
}

MIXIN RequestHandler{
	REGISTER(precmd);
	extern object session;
	extern string data;
	extern string type;
	private void precmd()
	{
		session->accept_wml=0;
		//werror("%O",session->request_headers);
		if(session->request_headers["accept"]){
			array a=session->request_headers["accept"]/",";
			a=map(a,String.trim_all_whites);
			foreach(a,string s){
				if((s/";")[0]=="text/vnd.wap.wml"){
					//werror("%s -> %s OK\n",s,(s/";")[0]);
					session->accept_wml=1;
				}else{
					//werror("%s -> %s\n",s,(s/";")[0]);
				}
			}
		}
	}
}

