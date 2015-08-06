array path2args(array path,string key)
{
	array args=({key});
	for(array p=path;sizeof(p)>3;p=p[..<2]){
		args=({p[-2]})+args;
	}
	return args;
}
