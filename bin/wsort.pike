#! /bin/env pike
#include <args.h>
int main(int argc,array argv)
{
	if(Usage.usage(argv,"WINDOW-SIZE",1)){
		werror(
#" -h,  --help          Show this help.
");
		return 0;

	}
	mapping args=Arg.parse(argv);
	array rest=args[Arg.REST];

	int window_size=(int)(rest[0]);

	array a=({});

	string lastout;

	int res;

	string s=Stdio.stdin->gets();
	while(s){
		a+=({s});
		if(sizeof(a)>=window_size){
			string m=min(@a);
			if(lastout&&m<lastout){
				res=1;
			}
			int pos=search(a,m);
			a=a[..pos-1]+a[pos+1..];
			write("%s\n",m);
			lastout=m;
		}
		s=Stdio.stdin->gets();
	}
	write("%s\n",sort(a)*"\n");
	if(res)
		werror("WARNING: window is too small.\n");
	return res;
}
