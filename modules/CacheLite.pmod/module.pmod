class Cache(int limit,int|void raw_key){
	int time0=time();
	mapping m=([]);
	mapping c=([]);
	mixed _m_delete(mixed key)
	{
		mixed s=raw_key?key:encode_value_canonic(key);
		m_delete(c,s);
		return m_delete(m,s);
	}
	private void cut_tail()
	{
		if(sizeof(c)>limit){
			//PROFILING_BEGIN("cache")
			array keys=indices(c);
			array vals=values(c);
			sort(vals,keys);
			for(int i=0;i<limit/3;i++){
				m_delete(m,keys[i]);
				m_delete(c,keys[i]);
			}
			//PROFILING_END
		}
	}
	mixed `[]=(mixed key,mixed val)
	{
		//string s=encode_value_canonic(key);
		mixed s=raw_key?key:encode_value_canonic(key);
		if(m[s]==0){
			m[s]=val;
		}
		c[s]=time(time0);
		cut_tail();
		return m[s];
	}
	//function last;
	mixed `()(mixed key,function f,mixed ... args)
	{
		//last=f;
		//string s=encode_value_canonic(key);
		mixed s=raw_key?key:encode_value_canonic(key);
		if(m[s]==0){
			m[s]=f(@args);
		}
		c[s]=time(time0);
		cut_tail();
		return m[s];
	}
}
