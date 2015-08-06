#! /bin/env pike
int write_file(string path,string data)
{
	int res;
	if(!Stdio.is_dir(path)){
		res=Stdio.write_file(path+".safetmp",data);
		mv(path+".safetmp",path);
	}else{
		res=Stdio.write_file(path,data);
	}
	return res;
}

#include <args.h>
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"",0)){
		return 0;
	}
	HANDLE_ARGUMENTS();
}

