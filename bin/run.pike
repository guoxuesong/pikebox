#! /bin/env pike
int main(int argc,array argv)
{
	if(Usage.usage(argv,"APP",1)){
		werror(
#" -h,	--help		Show this help.
");
		return 0;

	}
	mapping args=Arg.parse(argv);
	array rest=args[Arg.REST];

	//werror("%s\n",rest[0]);

	if(Stdio.is_dir(getenv("PIKEBOX")+"/systems/"+rest[0]+".pmod")){
		mkdir(getenv("PIKEBOX")+"/systems/"+rest[0]+".pmod/Class.pmod");
		mkdir(getenv("PIKEBOX")+"/systems/"+rest[0]+".pmod/Static.pmod");
	}

	object main=compile_string(sprintf("function foo(){return %s.main;}",rest[0]))()->foo();

	return main(argc,argv[1..]);
}

