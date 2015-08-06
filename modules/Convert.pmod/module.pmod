string string_to_gbk(string s)/*{{{*/
{
	string out="";
	for(int i=0;i<sizeof(s);i++){
		mixed e=catch{
			if(s[i]<128){
				out+=s[i..i];
			}else{
				out+=Locale.Charset.encoder("gb18030")->feed(s[i..i])->drain();
			}
		};
	}
	return out;
}/*}}}*/
string gbk_to_string(string s)/*{{{*/
{
	string out="";
	for(int i=0;i<sizeof(s);i++){
		mixed e=catch{
			if(s[i]<128){
				out+=s[i..i];
			}else{
				i++;
				if(i<sizeof(s))
					out+=Locale.Charset.decoder("gb18030")->feed(s[i-1..i])->drain();
			}
		};
	}
	return out;
}/*}}}*/
string utf8_to_gbk(string s)/*{{{*/
{
	s=utf8_to_string(s);
	return string_to_gbk(s);
};/*}}}*/
string gbk_to_utf8(string s)/*{{{*/
{
	return string_to_utf8(gbk_to_string(s));

};/*}}}*/

mapping freq=([]);
string dwim_decode(string s)/*{{{*/
{
	string s1;
	catch{
		//s1=iconv("GB18030","UTF8",s);
		s1=Locale.Charset.decoder("gb18030")->feed(s)->drain();
	};
	int maybe_gbk;
	if(s1&&s1!=""){
		werror("maybe_gbk\n");
		maybe_gbk=1;
	}
	string s2;
	mixed e=catch{
		//s2=iconv("UTF8","GB18030",s);
		string t=Locale.Charset.decoder("utf8")->feed(s)->drain();
		Locale.Charset.decoder("gb18030")->feed(string_to_utf8(t))->drain();
		s2=utf8_to_string(s);
	};
	if(e){
		master()->handle_error(e);
	}
	int maybe_utf8;
	if(s2&&s2!=""){
		werror("maybe_utf8\n");
		maybe_utf8=1;
	}

	if(!maybe_gbk&&!maybe_utf8){
		return 0;
	}
	if(maybe_utf8&&!maybe_gbk){
		return s2;
	}
	if(maybe_gbk&&!maybe_utf8){
		return s1;
	}

	if(`+(0,@replace(map(s1/"",freq),0,sizeof(freq)))<`+(0,@replace(map(s/"",freq),0,sizeof(freq)))){
		werror("gbk better\n");
		return s1;
	}else{
		werror("utf8 better\n");
		return s2;
	}

}/*}}}*/

void create()
{
	string freq_str=#string "freq.utf8";
	foreach(freq_str/"\n",string line){
		if(sscanf(line,"%d %s\n",int n,string ch)==2){
			freq[utf8_to_string(ch)[0]]=n;
		}
	}
}
void main()
{
	string t=dwim_decode("大家好");
	werror("%s\n",string_to_utf8(t));
}