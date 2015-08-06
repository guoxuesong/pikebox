string VARINFO(mixed v){
	string s=sprintf("%O",v);
	s="\""+replace(s,(["\"":"\\\"","\n":"\\\n"]))+"\"";
	string src="string s="+s+";";
	//werror("src:\n%s\n",src);
	program p=compile(src);
	return p()->s;
}

