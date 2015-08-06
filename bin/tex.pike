#! /bin/env pike
#include <args.h>
int main(int argc,array argv)
{
	if(Usage.usage(argv,"FILE",1)){
		werror(
#" -h,	--help		Show this help.
");
		return 0;

	}
	mapping args=Arg.parse(argv);
	array rest=args[Arg.REST];

	string file=rest[0];

	Process.system(sprintf("%s/bin/texfy.pike %s %s/tmp/%s.tex0",getenv("PIKEBOX"),file,getenv("PIKEBOX"),basename(file)));
	Process.system(sprintf("iconv -f utf-8 -t gbk <%s/tmp/%s.tex0 >%s/tmp/%s.tex",getenv("PIKEBOX"),basename(file),getenv("PIKEBOX"),basename(file)));
	Process.system(sprintf("%s/bin/gvim.pike %s/tmp/%s.tex -c 'set fileencoding=gbk'",getenv("PIKEBOX"),getenv("PIKEBOX"),basename(file)));
	Process.system(sprintf("iconv -f gbk -t utf-8 <%s/tmp/%s.tex >%s/tmp/%s.tex0",getenv("PIKEBOX"),basename(file),getenv("PIKEBOX"),basename(file)));
	Process.system(sprintf("%s/bin/texfy.pike -r %s/tmp/%s.tex0 %s/tmp/%s",getenv("PIKEBOX"),getenv("PIKEBOX"),basename(file),getenv("PIKEBOX"),basename(file)));
	string source_data=Stdio.read_file(file);
	string target_data=Stdio.read_file(sprintf("%s/tmp/%s",getenv("PIKEBOX"),basename(file)));
	if(target_data!=source_data){
		Stdio.write_file(file+"~",source_data);
		Stdio.write_file(file,target_data);
	}
}

