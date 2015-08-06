private array split_desc(string key,string desc)
{
	int indent;
	while(has_prefix(desc," ")){
		indent++;
		desc=desc[1..];
	}
	if(has_prefix(desc,"=")){
		array a=desc/"\t";
		key=key+a[0];
		desc=a[1..]*"\t";
	}
	return ({indent,key,desc});
}
int usage(array|mapping argv,string extra,int n)
{
	extra=extra||"";
	mapping args;
	if(arrayp(argv))
		args=Arg.parse(argv);
	else
		args=argv;
	if(args["_cmd_info"]){
		n++;
	}
	if(args["help"]||args["h"]||sizeof(args[Arg.REST])<n){
		if(!args["_cmd_info"]){
			foreach(extra/"\n";int i;string line){
				if(i==0)
					werror("usage: %s [OPTIONS] %s\n",basename(argv[0]),line);
				else
					werror("       %s [OPTIONS] %s\n",basename(argv[0]),line);
			}
		}else{
			foreach(extra/"\n";int i;string line){
				if(i==0)
					werror("usage: %s [OPTIONS] CMD %s\n",basename(argv[0]),line);
				else
					werror("       %s [OPTIONS] CMD %s\n",basename(argv[0]),line);
			}
		}
		if(mappingp(argv)){
			werror("OPTIONS:\n");
			int maxkeysize=(sizeof("[-h,--help]")-2);
			if(args["_arg_info"]){
				foreach(args["_arg_info"],[string key,string desc,int required]){
					if(!has_prefix(desc,"!")){
						[int indent,key,desc]=split_desc(key,desc);
						maxkeysize=max(maxkeysize,sizeof(key)+indent);
					}
				}
				maxkeysize+=2;
				foreach(args["_arg_info"],[string key,string desc,int required]){
					if(!has_prefix(desc,"!")){
						[int indent,key,desc]=split_desc(key,desc);
						if(required)
							werror(" %s--%s %s\n"," "*indent,key+" "*(maxkeysize-sizeof(key)),desc);
						else
							werror(" %s[--%s]%s %s\n"," "*indent,key," "*(maxkeysize-(sizeof(key)+2)),desc);
					}
				}
			}
			werror(" [-h,--help]%s Show this help.\n"," "*(maxkeysize-(sizeof("[-h,--help]")-2)));
			if(args["_cmd_info"]){
				werror("CMD:\n");
				int maxkeysize;
				foreach(args["_cmd_info"],[string key,string desc]){
					if(!has_prefix(desc,"!")){
						maxkeysize=max(maxkeysize,sizeof(key));
					}
				}
				foreach(args["_cmd_info"],[string key,string desc]){
					if(!has_prefix(desc,"!")){
						werror(" %s %s\n",key+" "*(maxkeysize-sizeof(key)),desc);
					}
				}
			}
		}
		return 1;
	}
}
