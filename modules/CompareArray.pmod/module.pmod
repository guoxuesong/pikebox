class CompareArray{
	inherit ByValue.Array;
	void create(array a)
	{
		::create(@a);
	}
}
class Pair{
	inherit ByValue.Pair;
}
#if 0
class CompareArray(array a)
{
	mixed `[](int pos){ return a[pos];}
	mixed `[]=(int pos,mixed val){ return a[pos]=val;}
	int _sizeof()/*{{{*/
	{
		return sizeof(a);
	}/*}}}*/
	int `==(object rhd)/*{{{*/
	{
		if(!objectp(rhd))
			return 0;
		return equal(a,rhd->a);
	}/*}}}*/
	int `<(object rhd)/*{{{*/
	{
		if(sizeof(a)==sizeof(rhd->a)){
			if(sizeof(a)==0)
				return 0;
			if(a[0]<rhd->a[0])
				return 1;
			else if(a[0]==rhd->a[0])
				return CompareArray(a[1..])<CompareArray(rhd->a[1..]);
			else if(a[0]>rhd->a[0])
				return 0;
		}
	}/*}}}*/
	object `-(object rhd)/*{{{*/
	{
		object res=CompareArray(allocate(sizeof(a)));
		for(int i=0;i<sizeof(a)&&i<sizeof(rhd->a);i++){
			res->a[i]=a[i]-rhd->a[i];
		}
		return res;
	}/*}}}*/
	object `+(object ... args)/*{{{*/
	{
		object res=CompareArray(allocate(sizeof(a)));
		for(int i=0;i<sizeof(a);i++)
			res->a[i]=a[i];
		foreach(args,object rhd){
			for(int i=0;i<sizeof(res->a)&&i<sizeof(rhd->a);i++){
				res->a[i]=res->a[i]+rhd->a[i];
			}
		}
		return res;
	}/*}}}*/
	int __hash()/*{{{*/
	{
		return hash_value(predef::`+(0.0,@map(a,hash_value)));
	}/*}}}*/
	string _sprintf(int t)/*{{{*/
	{
		if(t=='O'){
			array aa=({});
			foreach(a,mixed v){
				aa+=({sprintf("%O",v)});
			}
			return "CompareArray("+aa*","+")";
		}
	}/*}}}*/
}

class Pair{
	inherit CompareArray;
	void create(mixed first,mixed second)/*{{{*/
	{
		::create(({first,second}));
	}/*}}}*/
	string _sprintf(int t)/*{{{*/
	{
		if(t=='O'){
			array aa=({});
			foreach(a,mixed v){
				aa+=({sprintf("%O",v)});
			}
			return "Pair("+aa*","+")";
		}
	}/*}}}*/
}
#endif
