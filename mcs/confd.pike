mapping m=([]);
mixed conf(string key,mixed val)
{
	if(!zero_type(m[key])){
		return m[key];
	}else{
		m[key]=val;
		//werror("WARNING: this_app()->conf[%q] not found, use default %O,\n",key,val);
		return val;
	}
}
mixed set(string key,mixed val)
{
	m[key]=val;
	return val;
}

void destroy()
{
	Stdio.write_file("confd.rc.example","//copy this file to confd.rc and modify to config.\n");
	foreach(SortMapping.sort(m);string k;mixed v){
		Stdio.append_file("confd.rc.example",sprintf("SET(%s,%O);\n",k,v));
	}
}
