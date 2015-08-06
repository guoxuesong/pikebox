#! /bin/env pike
#include <args.h>
#include <pidfile.h>
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

	args["pid-file"]=getenv("HOME")+"/var/run/gvim.pid";
	HANDLE_PIDFILE();

	string file=rest[0];
	//string fullpath=combine_path(getcwd(),file);
	string winpath=combine_path_nt(getenv("WIN_GVIM_WINDOWS_PATH"),"/PikeBox/gvim_tmp/",basename(file));

	//replace(argv,file,winpath);
	//rest[0]=winpath;

	string ip=getenv("WIN_GVIM_IP");
	int port=(int)getenv("WIN_GVIM_PORT");

	object conn=Stdio.FILE();
	conn->connect(ip,port);

	string tmppath=sprintf("%s/gvim_tmp",getenv("PIKEBOX"));
	string vimsee_tmppath=combine_path_nt(getenv("WIN_GVIM_WINDOWS_PATH"),"/PikeBox/gvim_tmp");

	string target=sprintf("%s/gvim_tmp/%s",getenv("PIKEBOX"),basename(file));

	if(sizeof(get_dir(sprintf("%s/gvim_tmp/",getenv("PIKEBOX"))))){
		werror("ERROR: %s is not empty, last action maybe not complated, check it and retry.\n",sprintf("%s/gvim_tmp/",getenv("PIKEBOX")));
		return 1;
	}

	string source_data;
	if(Stdio.is_file(file)){
		source_data=Stdio.read_file(file);
		Stdio.write_file(target,source_data);
	}else if(Stdio.is_dir(file)){
		throw(({"not file.\n",backtrace()}));
	}
	array vim_args=((object)"vi.pike")->gen_vim_args(tmppath,vimsee_tmppath,argc,argv,0);
	replace(vim_args,file,winpath);
	Process.system(sprintf("%s/bin/gvim_sync.sh",getenv("PIKEBOX")));
	sleep(5);
	conn->write("%s\n","gvim -f "+map(vim_args,lambda(string s){
				if(search(s," ")>=0){
					return sprintf("%q",s);
				}else{
					return s;
				}
				})*" ");
	void save()
	{
		Process.system(sprintf("%s/bin/gvim_reverse_sync.sh",getenv("PIKEBOX")));
		if(Stdio.exist(target)){
			string target_data=Stdio.read_file(target);
			if(target_data!=source_data){
				if(source_data)
					Stdio.write_file(file+"~",source_data);
				Stdio.write_file(file,target_data);
			}
		}
	};
	object run=Time.Waker(10);
	while(conn->peek()==0){
		run(save);
		sleep(1);
	}
	werror("finish ...\n");
	conn->gets();
	werror("gets done\n");
	save();
	werror("save done\n");
	foreach(get_dir(sprintf("%s/gvim_tmp/",getenv("PIKEBOX"))),string file){
		rm(sprintf("%s/gvim_tmp/%s",getenv("PIKEBOX"),file));
	}
	werror("rm done\n");
}
