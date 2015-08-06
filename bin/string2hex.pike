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

	if(sizeof(rest))
		write("%s",String.string2hex(rest[0]));
	else
		write("%s",String.string2hex(Stdio.stdin->read()));
}

