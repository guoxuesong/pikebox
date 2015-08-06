#! /bin/env pike
#include <args.h>
#define BUFFSIZE 1024
class Buffer{
	array a=({allocate(BUFFSIZE)});
	int last_size;
	mixed `[](int n)
	{
		return a[n/BUFFSIZE][n%BUFFSIZE];
	}
	mixed `[]=(int n,mixed val)
	{
		return a[n/BUFFSIZE][n%BUFFSIZE]=val;
	}
	int _sizeof()
	{
		return BUFFSIZE*(sizeof(a)-1)+last_size;
	}
	void resize(int n)
	{
		array res=allocate(n/BUFFSIZE+1,0);
		for(int i=0;i<sizeof(res);i++){
			if(i<sizeof(a)){
				res[i]=a[i];
			}
		}
		last_size=n%BUFFSIZE;
	}
}
class Table{
	array keys=({});
	mapping key2default=([]);
	array columns=({});
	int n=0;
	void add_column(string key,mixed value)/*{{{*/
	{
		if(search(keys,key)<0){
			keys+=({key});
			key2default[key]=value;
		}
	}/*}}}*/
	void add_row(mapping m)
	{
	}
}
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
}

