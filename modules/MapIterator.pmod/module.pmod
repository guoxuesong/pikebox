class MapIterator(Iterator i,function f)/*{{{*/
{
	void _random() { i->_random(); }
	int _sizeof() { return i->_sizeof(); }
	int `!() { return !i; }
	MapIterator `+(int n) { return MapIterator(i+n,f); }
	MapIterator `+=(int n)
	{
		i+=n;
		return this;
	}
	MapIterator `-(int n) { return MapIterator(i-n,f); }
	int first() { return i->first(); }
	int index() { return i->index(); }
	int next() { return i->next(); }
	void set_index(int idx) { i->set_index(idx); }
	mixed value()
	{
		mixed res=i->value();
		if(zero_type(res))
			return UNDEFINED;
		else
			return f(i->index(),res);
	}
}/*}}}*/
