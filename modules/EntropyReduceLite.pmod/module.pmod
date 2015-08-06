#! /bin/env pike
#include <args.h>
int dots_main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	string line=Stdio.stdin->gets();
	while(line){
		array a=line/" ";
		if(sizeof(a)){
			a=map(a,Cast.intfy);
			int count=a[0];
			array vals=a[1..];
			//werror("%d %O\n",count,vals);
		}
		line=Stdio.stdin->gets();
	}
}

int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	DECLARE_ARGUMENT_EXECUTE("dots",dots_main,"")
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
}

