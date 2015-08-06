#! /bin/env pike
#include <args.h>
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"FILE",1)){
		return 0;
	}
	HANDLE_ARGUMENTS();
	write("%O\n",decode_value(Stdio.read_file(argv[1])));
}
