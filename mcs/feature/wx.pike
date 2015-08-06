MIXIN Session{
	string oauth_cmd;
	string wx_openid="oRWXNvo-t-RJi-NaB4L9rwOHEUNo";
	array payok_argv;
	string payok_prepay_id;
	string payok_out_trade_no;
}
DAEMON:
string app_id="wxba97f4cc76aba2ed";
string app_secret="2efb9c1ea347ae3deba22f4a49bc4c91";
string mch_id="1254299201";
string api_secret="292d3ee88fda723f0886bd98ffaab8e1";
string _access_token;
int _access_token_expires;
string access_token()
{
	if(time()>_access_token_expires){
		string data=wget(sprintf("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=%s&secret=%s",app_id,app_secret));
		mapping m=Standards.JSON.decode(data);
		//werror("access_token data:%s\n",data);
		//werror("access_token:%O\n",m);
		_access_token=m->access_token;
		_access_token_expires=time()+m->expires_in-10;
	}

	return _access_token;
}
string _jsapi_ticket;
int _jsapi_ticket_expires;
string jsapi_ticket()
{
	if(time()>_jsapi_ticket_expires){
		string data=wget(sprintf("https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=%s&type=jsapi",access_token()));
		mapping m=Standards.JSON.decode(data);
		if(m->errcode){
			werror("%O",m);
			return 0;
		}
		_jsapi_ticket=m->ticket;
		_jsapi_ticket_expires=time()+m->expires_in-10;
	}

	return _jsapi_ticket;
}

string jssdk_signature(string noncestr,int timestamp,string url)
{
	string s=sprintf("jsapi_ticket=%s&noncestr=%s&timestamp=%d&url=%s",jsapi_ticket(),noncestr,timestamp,url);
	string res=String.string2hex(Crypto.SHA1.hash(s));
	werror("jssdk_signature: s=%s\n",s);
	werror("jssdk_signature: res=%s\n",res);
	return res;
}
string pay_signature(mapping args)
{
	array keys=sort(indices(args));
	string s=map(keys,lambda(string key){return sprintf("%s=%s",key,(string)(args[key]));})*"&";
	s=s+"&key="+api_secret;
	string res=upper_case(String.string2hex(Crypto.MD5.hash(s)));
	werror("pay_signature: s=%s\n",s);
	werror("pay_signature: res=%s\n",res);
	return res;
}
string args2xml(mapping args)
{
	array keys=sort(indices(args));
	return "<xml>"+map(keys,lambda(string key){return sprintf("<%s>%s</%s>",key,(string)(args[key]),key);})*""+"</xml>";
}
