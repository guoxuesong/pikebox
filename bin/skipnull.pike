#! /bin/env pike
#include <args.h>
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
	int c=Stdio.stdin->getchar();
	while(c>=0){
		if(c){
			write("%c",c);
		}
		c=Stdio.stdin->getchar();
	}
}

