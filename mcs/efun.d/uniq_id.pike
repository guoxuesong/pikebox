int n2c(int n)/*{{{*/
{
	if(n<10){
		return '0'+n;
	}else{
		n=n-10;
		if(n<26){
			return 'a'+n;
/*		}else{
			n-=26;
			return 'A'+n;*/
		}
	}
}/*}}}*/
string short_string(int n)/*{{{*/
{
	string res="";
	while(n){
		res=sprintf("%c%s",n2c(n%(26+10)),res);
		n=n/(26+10);
	}
	return res;
}/*}}}*/
string gen_uniq_id(string prefix,int|void basetime)
{
	//basetime=0;
	if(time()!=uniq_id_last_time){
		uniq_id_last_time=time();
		uniq_id_sn=0;
	}
	return sprintf("%s-%s-%s",prefix,short_string(uniq_id_last_time-basetime),short_string(uniq_id_sn++));
}
int uniq_id_last_time=time();
int uniq_id_sn;


