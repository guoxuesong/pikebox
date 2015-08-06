Thread.Local thread_local=Thread.Local();
void _setlocal(mixed val)
{
	thread_local->set(val);
}
mixed _getlocal()
{
	return thread_local->get();
}
void pause(mixed|void value)
{
	object func=thread_local->get();
	func->pause(value);
}

class AdvanceFunctionIterator(object afunc){/*{{{*/
	int pos;
	mixed val;
	void create()
	{
		val=afunc();
	}
	int `!()
	{
		return !afunc;
	}
	/*AdvanceFunctionIterator `+=(int n)
	{
		for(int i=0;i<n;i++){
			if(afunc)
				val=afunc->advance();
			else
				eof=1;
		}
		pos+=n;
		return this;
	}*/
	int index()
	{
		if(afunc)
			return pos;
		else
			return UNDEFINED;
	}
	int next()
	{
		pos++;
		if(afunc)
			val=afunc->advance();
		return afunc?1:0;
	}
	mixed value()
	{
		return val;
	}
}/*}}}*/

class AdvanceFunction(function func){
	private Thread.Thread thread;
	private Thread.Fifo fifo=Thread.Fifo(1);
	private int eof;
	int `!() {return eof;}
	void pause(mixed|void value,int|void eof)
	{
		fifo->write(value);
		fifo->write(value);
		fifo->write(eof);
	}
	private mixed _wait()
	{
		return fifo->read();
	}
	mixed advance()
	{
		if(!eof){
			fifo->read();
			eof=fifo->read();
		}
		if(!eof)
			return _wait();
	}
	private void thread_main(mixed ... args)
	{
		._setlocal(AdvanceFunction::this);
		//werror("set -> %O\n",AdvanceFunction::this);
		//werror("get -> %O\n",._getlocal());
		mixed res=func(@args);
		pause(res,1);
	}
	mixed `()(mixed ... args)
	{
		thread=Thread.Thread(thread_main,@args);
		return _wait();
	}
	object _get_iterator()
	{
		return .AdvanceFunctionIterator(this);
	}
}

private int test()
{
	werror("test start.\n");
	for(int i=0;i<10;i++){
		.pause(i);
	}
	werror("test stop.\n");
	return -1;
}

int main()
{
	object func=.AdvanceFunction(test);
	/*int value=func();
	while(func){
		werror("got %d\n",value);
		value=func->advance();
	}*/
	foreach(func;int pos;int value){
		werror("%d %d\n",pos,value);
	}
	werror("done");
}
