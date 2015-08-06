#! /bin/env pike
int main(int argc,array argv)
{
	//werror("%O",argv);
	foreach(argv[1..],string s){
		if(!has_prefix(s,"-")){
			if(Stdio.is_file(s)){
				string ccfile=((s/".")[..<1]+({"cc"}))*".";
				argv=replace(argv,s,ccfile);
				mv(s,ccfile);
				Process.system((({"mkoctfile"})+argv[1..])*" ");
				//Process.system("ls /tmp");
				string octfile=((s/".")[..<1]+({"so.oct"}))*".";
				string sofile=((s/".")[..<1]+({"so"}))*".";
				if(Stdio.is_file(octfile)){
					mv(octfile,sofile);
				}
				break;
			}
		}
	}
	Process.system("rm __c__*.o");
}
