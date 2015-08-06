#! /bin/env pike
#include <args.h>
int main(int argc,array argv)
{
	mapping args=Arg.parse(argv)+([0:argv[0]]);
	array rest=args[Arg.REST];
	if(Usage.usage(args,"MAILADDR TIMEOUT FILE[+] ...",3)){
		return 0;
	}
	HANDLE_ARGUMENTS();

	object currday=Calendar.ISO.Day();

	string mailaddr=rest[0];
	int timeout=(int)rest[1];
	array files=rest[2..];

	mapping file2size=([]);
	mapping file2time=([]);
	mapping file2stop=([]);

	while(1){
		object day=Calendar.ISO.Day();
		if(day!=currday){
			file2stop=([]);
			currday=day;
		}
		foreach(files,string file0){
			string file=file0;
			if(has_suffix(file,"+")){
				file=sprintf("%s%s",file[..<1],Calendar.ISO.Second()->format_ymd_short());
			}
			object st=file_stat(file);
			int size=st&&st->size;
			if(size!=file2size[file0]){
				file2size[file0]=size;
				file2time[file0]=time();
			}
		}
		foreach(files,string file0){
			werror("check %s\n",file0);
			if(file2stop[file0]==0&&time()-file2time[file0]>timeout){
				file2stop[file0]=1;
				werror("%s STOP.\n",file0);
				Process78.system(sprintf("echo '%s' | mail -s \"Watchlog Alert: STOP\" %s",sprintf("%s %s STOP.",Calendar.ISO.Second()->format_time_short(),file0),mailaddr));
			}
			if(file2stop[file0]==1&&time()-file2time[file0]<timeout){
				file2stop[file0]=0;
				werror("%s RESTART.\n",file0);
				Process78.system(sprintf("echo '%s' | mail -s \"Watchlog Alert: RESTART\" %s",sprintf("%s %s RESTART.",Calendar.ISO.Second()->format_time_short(),file0),mailaddr));
			}
		}
		sleep(10);
	}
}

