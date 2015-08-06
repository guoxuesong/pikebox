class ArrayFromIterator(Iterator i,int|void size)/*{{{*/
{
	mixed `[](int pos)
	{
		if(pos<0){
			int size=sizeof(this);
			pos=size+pos;
		}
		i->set_index(pos);
		if(i){
			return i->value();
		}else{
			throw(({"BigArray out of bound.\n",backtrace()}));
		}
	}
	mixed `[..](int low, int low_bound_type, int high, int high_bound_type)
	{
		if(_sizeof()==0)
			return ({});
		werror("ArrayFromIterator: size=%d(%d) low=%d low_bound_type=%d high=%d high_bound_type=%d\n",sizeof(this),size,low,low_bound_type,high,high_bound_type);
		if(low_bound_type==Pike.INDEX_FROM_BEG||low_bound_type==Pike.OPEN_BOUND){
			werror("low INDEX_FROM_BEG\n");
			low=max(low,0);
			i->set_index(low);
		}else{
			werror("low INDEX_FROM_END\n");
			low=max(sizeof(this)-low-1,0);
			i->set_index(low);
		}

		if(high_bound_type==Pike.INDEX_FROM_BEG){
			werror("heigh INDEX_FROM_BEG\n");
			;
		}else{
			werror("heigh INDEX_FROM_END\n");
			high=_sizeof()-high-1;
		}

		high=min(high,_sizeof()-1);
		werror("low=%d,height=%d\n",low,high);

		array res=({});
		while(i){
			res+=({i->value()});
			if(i->index()==high)
				break;
			i++;
		}
		return res;
	}
	int _sizeof()
	{
		if(i->_sizeof)
			return i->_sizeof();
		else
			return size;
	}
}/*}}}*/

class BigArray(object db,string size_key,function|void save,function|void load)/*{{{*/
{
	inherit ArrayFromIterator;
	BigArrayIterator ii;
	mixed nosave(mixed v){return v;};
	void create()
	{
		//werror("create\n");
		if(save==0){
			//werror("using nosave\n");
			save=nosave;
			load=nosave;
		}
		ii=BigArrayIterator(db,size_key,save,load);
		::create(ii);
	}
	mixed `[]=(int pos,mixed value)
	{
		if(pos<0){
			int size=(int)db[size_key];
			pos=size+pos;
		}
		ii->set_index(pos);
		if(ii){
			db[sprintf("%d",pos)]=encode_value(save(value));
			return value;
		}else{
			throw(({"BigArray out of bound.",backtrace()}));
		}
	}
	BigArray `+=(array a)
	{
		int p=(int)db[size_key];
		foreach(a,mixed s)
		{
			db[sprintf("%d",p++)]=encode_value(save(s));
		}
		db[size_key]=sprintf("%d",p);
		return this;
	}
	BigArrayIterator _get_iterator(){return BigArrayIterator(db,size_key,save,load);}
}/*}}}*/
class BigArrayIterator(object db,string size_key,function save,function load){/*{{{*/
	int pos;
	void _random()
	{
		int size=(int)db[size_key];
		pos=random(size);
	}
	int _sizeof()
	{
		return (int)db[size_key];
	}
	int `!()
	{
		int size=(int)db[size_key];
		return !(pos>=0&&pos<size);
	}
	BigArrayIterator `+(int n)
	{
		BigArrayIterator res=BigArrayIterator(db,size_key,save,load);
		res->pos=pos+n;
		return res;
	}
	BigArrayIterator `+=(int n)
	{
		pos+=n;
		return this;
	}
	BigArrayIterator `-(int n)
	{
		BigArrayIterator res=BigArrayIterator(db,size_key,save,load);
		res->pos=pos-n;
		return res;
	}
	int first()
	{
		pos=0;
		if((int)db[size_key]==0){
			return 0;
		}else{
			return 1;
		}
	}
	int index()
	{
		int size=(int)db[size_key];
		if(pos>=0&&pos<size)
			return pos;
		else
			return UNDEFINED;
	}
	int next()
	{
		pos++;
		return index();
	}
	void set_index(int idx)
	{
		pos=idx;
	}
	mixed value()
	{
		mixed res=db[sprintf("%d",pos)];
		if(res==0)
			return UNDEFINED;
		else
			return load(decode_value(res));
	}
}/*}}}*/
