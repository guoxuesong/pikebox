private mapping cache=([]); 
//private int level;
void cache_begin()
{
	//level++;
}
void cache_end()
{
	/*level--;
	//ASSERT_TRUE(level>=0,level);
	if(level==0){
		cache=([]);
	}
	*/
}
void cache_reset()
{
	cache=([]);
}
void cache_set(array keys,mixed val)
{
	if(/*level&&*/sizeof(keys)){
		mapping p=cache;
		foreach(keys[..<1],mixed key){
			p[key]=p[key]||({UNDEFINED,([])});
			p=p[key][1];
		}
		p[keys[-1]]=p[keys[-1]]||({UNDEFINED,([])});
		p[keys[-1]][0]=val;
	}
}
mixed cache_query(array keys)
{
	if(/*level&&*/sizeof(keys)){
		mapping p=cache;
		foreach(keys[..<1],mixed key){
			p=(p[key]||({UNDEFINED,([])}))[1];
		}
		return (p[keys[-1]]||({UNDEFINED,([])}))[0];
	}
}
int cache_level()
{
	return 0;
	//return level;
}

/*
void main()
{
	cache_begin();
	cache_set(({1,2,3}),"haha");
	cache_set(({1,2,3,4}),"xixi");
	werror("%O",cache);
	werror("%s\n",cache_query(({1,2,3})));
	werror("%s\n",cache_query(({1,2,3,4})));
	cache_end();
}
*/
