string html_encode_string(string s)/*{{{*/
{
	//using _Roxen.html_encode_string break dump
	return replace(master()->resolv("_Roxen")->html_encode_string(s),(["\n":"&#13;",
				"\r":"",
				"'":"&apos;",
				"\0":" ",
				"&#0;":" ",
				"&#39;":"&apos;",
				]));
}/*}}}*/

string http_encode_string(string d)/*{{{*/
{
	//ASSERT(stringp(d));
	string out="";
	for(int i=0;i<sizeof(d);i++){
		if(d[i]>='a'&&d[i]<='z'||d[i]>='A'&&d[i]<='Z'||d[i]>='0'&&d[i]<='9'||d[i]=='_')
			out+=sprintf("%c",d[i]);
		else
			out+=sprintf("%%%02X",d[i]);
	}
	return out;
}/*}}}*/
string http_encode_query(mapping m,int|void wml)/*{{{*/
{
	string AND_TAG=wml?"&amp;":"&";
	//return Protocols.HTTP.http_encode_query(m);
	string out="";
	foreach(m;string k;string d){
		out+=sprintf("%s%s=",AND_TAG,k);
		out+=http_encode_string(d||"");
	}
	return out[sizeof(AND_TAG)..];
}/*}}}*/

mapping http_decode_query(string q)/*{{{*/
{
	return Protocols.HTTP.Server.http_decode_urlencoded_query(q);
}/*}}}*/


