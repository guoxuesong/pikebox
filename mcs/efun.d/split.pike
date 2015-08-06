private mapping encode_mapping=(["/":"TA","#":"TB","$":"TC",".":"TD","T":"TZ"]);
private mapping decode_mapping=(["TA":"/","TB":"#","TC":"$","TD":".","TZ":"T"]);
array split(string tags_str,string|void d,string|void brackets)/*{{{*/
{
	if(d==0)
		d=" ";
	if(d=="/")
		return explode_path(tags_str);
	array a;
	if(catch{
		a=Parser.C.split(replace(tags_str,encode_mapping));
	}){
		if(catch{
				a=Parser.C.split(replace(tags_str+"\"",encode_mapping));
				}){
			return 0;
		}

	}
	//werror("a=%O\n",a);
	a=map(a,replace,decode_mapping);
	//werror("a=%O\n",a);
	if(a[-1]=="\n")
		a=a[..<1];
	else if(has_suffix(a[-1],"\n"))
		a[-1]=a[-1][..<1];
	array stack=({});
	array res=({""});
	int brackets_count=0;
	foreach(a,string s){
		if(brackets&&s==brackets[0..0]){
			brackets_count++;
			if(res[-1]=="")
				res=res[..<1];
			stack+=({res});
			res=({""});
		}else if(brackets&&s==brackets[1..1]){
			brackets_count--;
			stack[-1]+=({res});
			res=stack[-1];
			stack=stack[..<1];
		}else{
			while(has_suffix(s,d)){
				res+=({""});
				s=s[1..];
			}
			if(sizeof(s)){
				if(s[0]=='\"')
					sscanf(s,"%O",s);
				if(!stringp(res[-1])){
					res+=({""});
				}
				res[-1]+=s;
			}
		}
	}
	while(sizeof(stack)){
		stack[-1]+=({res,""});
		res=stack[-1];
		stack=stack[..<1];
	}
	return res;
}/*}}}*/
int need_quote(string s,string d)
{
	return (search(s," ")!=-1|| search(s,"\t")!=-1||
							search(s,"\r")!=-1||
							search(s,"\n")!=-1||
							search(s,"\"")!=-1||
							search(s,"\000")!=-1||
							search(s,d)!=-1
							);
}
string join(array tags,string|void d,string|void brackets,int|void force_quote)/*{{{*/
{
	if(d==0)
		d=" ";
	if(brackets==0){
		brackets="()";
	}
	if(d=="/")
		return Stdio.append_path_unix(@tags);
	return map(tags,lambda(string|int|float|array s)
			{
				if(stringp(s)){
					if(force_quote||need_quote(s,d)){
						return "\""+replace(s,(["\000":"\\000","\t":"\\t","\r":"\\r","\n":"\\n","\"":"\\\"","\\":"\\\\"]))+"\"";
						//sprintf("%O",s);
					}else if(s==""){
						return "\"\"";
					}else{
						return s;
					}
				}else if(arrayp(s)){
					return brackets[0..0]+join(s,d,brackets,force_quote)+brackets[1..1];
				}else{
					s=(string)s;
					if(need_quote(s,d)){
						return "\""+replace(s,(["\000":"\\000","\t":"\\t","\r":"\\r","\n":"\\n","\"":"\\\"","\\":"\\\\"]))+"\"";
					}else if(s==""){
						return "\"\"";
					}else{
						return s;
					}
				}
			})*d;
}/*}}}*/

#ifndef __RUNTIME__
void main()
{
	//array a,b;
	/*write("%O\n",a=split("add_node peterpan 海鲜店 http://shop34388439.taobao.com/?catId=24273547&queryType=cat&categoryName=%A1%F3%A1%F3%CF%BA%D0%B7%D6%C6%C6%B7%A1%F3%A1%F3&browseType=#pagebar -"," "));
	write("%s\n",join(a," "));
	write("%O\n",b=split("a,b,c,d,\"a b \",\"a,b,c\"",","));
	write("%s\n",join(b,","));
	*/
	//write("%O\n",a=split(",,\"张奕\",,,,,\"未指定\",\"00-0-0\",,,,,,\"yi.y.zhang@daimler.com\",,,,,,\"13718517990\",,,\"\",,,,,,,,,,,,,,,,,,,\"奔驰公司帝国理工校友\"",","));
	//write("%O",split("look/x//x/x","/"));
	//write("%O",join(({"abc","","def"})," "));
	//array a=split("tt(xixi haha)tt"," ","()");
	//write("%O",a);
	//write("%O",join(a));
	//write("%s\n",join(({"abc",123})," ","()",1));
	write("%O\n",split("(body[header.fields (date)])"," ","()"));

}
#endif
