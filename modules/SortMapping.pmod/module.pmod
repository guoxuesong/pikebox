#pike __REAL_VERSION__

class SortedIterator
{
	array keys,vals;
	int curr;
	object clone()
	{
		object res=SortedIterator();
		res->keys=keys;
		res->vals=vals;
		res->curr=curr;
		return res;
	}
	void create(mapping|void m,int|void reverse_flag,int|void sort_values)
	{
		if(m){
			keys=indices(m);
			vals=values(m);
			if(!sort_values){
				predef::sort(keys,vals);
			}else{
				predef::sort(vals,keys);
			}
			if(reverse_flag){
				keys=reverse(keys);
				vals=reverse(vals);
			}
			curr=0;
		}

	}
	void _random() { curr=random(sizeof(vals)); }
	int _sizeof() { return sizeof(vals); }
	int `!() { return !(curr>=0&&curr<sizeof(vals)); }
	SortedIterator `+(int n) {
		object res=SortedIterator();
		res->keys=keys;
		res->vals=vals;
		res->curr=curr+n;
	}
	SortedIterator `+=(int n)
	{
		curr+=n;
		return this;
	}
	SortedIterator `-(int n) {
		object res=SortedIterator();
		res->keys=keys;
		res->vals=vals;
		res->curr=curr-n;
	}
	int first() {
		curr=0;
		return sizeof(vals)>0;
	}
	mixed index() { if(curr>=0&&curr<sizeof(vals)) return keys[curr]; }
	int next() { curr++; return curr<sizeof(vals); }
	void set_index(int idx) { curr=idx; }
	mixed value()
	{
		if(curr>=0&&curr<sizeof(vals))
			return vals[curr];
	}
}

object sort(mapping|void m,int|void reverse_flag)
{
	return SortedIterator(m,reverse_flag);
}

object sort_values(mapping|void m,int|void reverse_flag)
{
	return SortedIterator(m,reverse_flag,1);
}
