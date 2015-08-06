int run(string|array(string) cmd)
{
	if(stringp(cmd)){
		cmd=Process.split_quoted_string(cmd);
	}

	object pikeob=(object)(getcwd()+"/"+cmd[0]);
	int res=pikeob->main(sizeof(cmd),cmd);
	return res;
}

mapping storage=([]);

mixed load(string file,function parser)
{
	if(zero_type(storage[file])){
		mixed e=catch{
			storage[file]=parser(file);
		};
		if(e){
			storage[file]=0;
			throw(e);
		}
	}
	return storage[file];
}
