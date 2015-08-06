void foreach_a(array a,function f)/*{{{*/
{
	f(({}));
	for(int i=1;i<(1<<sizeof(a));i++){
		array b=({});
		foreach(a;int idx;mixed d){
			if((i>>idx)&1){
				b+=({d});
			}
		}
		f(b);
	}
}/*}}}*/
void foreach_c(array a,int n,function f,array|void args)/*{{{*/
{
	if(args==0)
		args=({});
	if(sizeof(a)<n)
		return;
	if(n==0){
		if(sizeof(args))
			f(@args);
		return;
	}

	foreach_c(a[1..],n-1,f,args+({a[0]}));
	foreach_c(a[1..],n,f,args);
}/*}}}*/
void foreach_p(array a,int n,function f)/*{{{*/
{
	void pp(array a,function f,array args)
	{
		if(sizeof(a)==0){
			if(sizeof(args))
				f(@args);
			return;
		}
		for(int i=0;i<sizeof(a);i++){
			pp(a[0..i-1]+a[i+1..],f,args+({a[i]}));
		}
	};
	foreach_c(a,n,lambda(mixed...args){ pp(args,f,({})); });
}/*}}}*/
void foreach_multidim(array deltarange,function f)
{
	void walk(array a,array b,function f){
		if(sizeof(b)==1){
			for(int i=b[0][0];i<=b[0][1];i++){
				f(a+({i}));
			}
		}else{
			for(int i=b[0][0];i<=b[0][1];i++){
				walk(a+({i}),b[1..],f);
			}
		}
	};
	walk(({}),deltarange,f);
}
